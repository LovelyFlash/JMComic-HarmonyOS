// pages/ComicDetailPage.ets - 漫画详情页（JM：沉浸式头图 + 章节 + 相关推荐 + 云收藏 + 点赞）- NavDestination
import { pasteboard } from '@kit.BasicServicesKit';
import { fileUri } from '@kit.CoreFileKit';
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { ToastUtil } from '../common/ToastUtil';
import { Comic } from '../data/model/Comic';
import { Chapter } from '../data/model/Chapter';
import { ReaderParam } from '../data/model/ReaderParam';
import { Database, ReadingProgress, ChapterTask, ChapterDlStatus } from '../data/database/Database';
import { DownloadManager } from '../data/download/DownloadManager';
import { DetailCache } from '../data/cache/DetailCache';
import { Settings } from '../data/preferences/Settings';
import { JmApi, JmFolder } from '../data/api/JmApi';
import { NetworkImage } from '../components/NetworkImage';
import { ArrayDataSource } from '../common/ArrayDataSource';
import { ChipTokens, DEFAULT_THEME_COLOR, SettingsKeys } from '../common/Constants';
import { Logger } from '../common/Logger';
import { uiMaterial } from '@kit.ArkUI';

const TAG = 'ComicDetail';
const CHAPTER_COLLAPSE_THRESHOLD = 20;


@Builder
export function ComicDetailPageBuilder(name: string, param: object) {
  ComicDetailPage({ pageParam: param })
}

@Component
export struct ComicDetailPage {
  pageParam: object | undefined = undefined;
  @State comicId: string = ''
  @State title: string = ''
  @State source: string = ''
  @State comic: Comic = new Comic()
  @State loading: boolean = true
  @State error: string = ''
  @State isFavorite: boolean = false
  @State isLiked: boolean = false
  @State chapters: Chapter[] = []
  @State chaptersReversed: boolean = false
  @State showAllChapters: boolean = false
  @State resumePage: number = 0
  @State resumeChapterOrder: number = 0
  // 云收藏 sheet
  @State showFavSheet: boolean = false
  @State folders: JmFolder[] = []
  @State loadingFolders: boolean = false
  @State newFolderName: string = ''
  @State favOperating: boolean = false
  // 下载章节选择 sheet
  @State showDlSheet: boolean = false
  @State dlPicks: string[] = []
  @State dlStatuses: Map<string, number> = new Map()
  @State isDownloaded: boolean = false
  /** 章节列表数据源（LazyForEach 惰性构建，排序/展开走 replaceAll 全量刷新） */
  private chapterSource: ArrayDataSource<Chapter> = new ArrayDataSource<Chapter>()
  
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR
  @StorageProp('topAvoidHeight') topAvoid: number = 0
  @StorageProp('bottomAvoidHeight') bottomAvoid: number = 0

  private favoriteMaterial: uiMaterial.Material =
    new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
      materialColor: 0x263B82F6,
      colorInvert: true,
      applyShadow: true,
      interactive: true,
      lightEffect: { color: undefined }
    })

  aboutToAppear(): void {
    if (this.pageParam !== undefined && this.pageParam !== null) {
      const params = this.pageParam as Record<string, Object>;
      this.comicId = params['comicId'] !== undefined && params['comicId'] !== null ? String(params['comicId']) : '';
      this.title = params['title'] !== undefined && params['title'] !== null ? String(params['title']) : '';
      this.source = params['source'] !== undefined && params['source'] !== null ? String(params['source']) : 'jm';
    }
    this.loadDetail();
    this.checkResume();
  }

  /**
   * 本地秒开 + 后台刷新：
   * - 已下载（有详情缓存）→ 立即本地渲染（封面走本地文件），随后按「离线优先」设置决定是否静默联网刷新
   * - 无缓存 → 走网络（原逻辑）
   */
  async loadDetail(): Promise<void> {
    this.loading = true;
    this.error = '';
    const cached: Comic | null = await DetailCache.loadComic(this.comicId, this.source);
    if (cached !== null) {
      this.applyDetail(cached);
      this.loading = false;
      await this.refreshDownloadState();
      this.maybeHealCover();
      const offline: boolean = await Settings.getBool(SettingsKeys.OFFLINE_FIRST, false);
      if (!offline) {
        this.refreshDetail();
      }
      return;
    }
    await this.fetchDetail();
    await this.refreshDownloadState();
    this.maybeHealCover();
  }

  /** 网络加载详情（无本地缓存时） */
  private async fetchDetail(): Promise<void> {
    try {
      if (this.source === 'jm') {
        this.comic = await JmApi.getComicInfo(this.comicId);
      } else {
        this.error = Translations.t('source_disabled');
        this.loading = false;
        return;
      }
      this.title = this.comic.title;
      this.chapters = this.comic.chapters;
      this.chapterSource.replaceAll(this.displayChapters());
      this.isFavorite = this.comic.isFavorite;
      this.isLiked = this.comic.isLiked;
      await Database.insertHistory(this.comicId, this.title, this.comic.coverUrl, this.source);
    } catch (e) {
      this.error = String(e);
    }
    this.loading = false;
  }

  /** 应用详情到状态（本地缓存与联网刷新共用） */
  private applyDetail(comic: Comic): void {
    this.comic = comic;
    this.title = comic.title;
    this.chapters = comic.chapters;
    this.chapterSource.replaceAll(this.displayChapters());
    this.isFavorite = comic.isFavorite;
    this.isLiked = comic.isLiked;
  }

  /** 缓存秒开后的静默联网刷新：成功更新页面与缓存（相关推荐不入缓存），失败保留缓存内容 */
  private async refreshDetail(): Promise<void> {
    try {
      if (this.source !== 'jm') {
        return;
      }
      const fresh: Comic = await JmApi.getComicInfo(this.comicId);
      this.applyDetail(fresh);
      await Database.insertHistory(this.comicId, this.title, fresh.coverUrl, this.source);
      await DetailCache.updateComic(fresh, this.source);
    } catch (e) {
      Logger.debug(TAG, `background refresh failed (cache kept): ${Logger.describe(e)}`);
    }
  }

  /** 封面数据源：本地已下载封面优先（沙箱路径需转 file:// URI 才能渲染），回退网络 URL */
  private coverSource(): string {
    const local: string = DetailCache.localCoverPath(this.comicId);
    return local.length > 0 ? fileUri.getUriFromPath(local) : this.comic.coverUrl;
  }

  /** 已下载但本地封面缺失（旧版本下载）时后台补抓，不阻塞页面 */
  private maybeHealCover(): void {
    if (!this.isDownloaded || this.comic.coverUrl.length === 0) {
      return;
    }
    DetailCache.ensureCover(this.comicId, this.comic.coverUrl).catch((e: Object) => {
      Logger.debug(TAG, `cover heal rejected: ${Logger.describe(e)}`);
    });
  }

  async checkResume(): Promise<void> {
    const progress: ReadingProgress = await Database.getReadingProgress(this.comicId, this.source);
    this.resumePage = progress.lastPage;
    this.resumeChapterOrder = progress.lastChapter.length > 0 ? Number(progress.lastChapter) : 0;
  }

  /** 收藏星标：已收藏→取消；未收藏→弹收藏夹 sheet */
  async toggleFavorite(): Promise<void> {
    if (!JmApi.isLoggedIn()) {
      ToastUtil.show(Translations.t('please_login'), 1500);
      return;
    }
    if (this.isFavorite) {
      try {
        await JmApi.favoriteComic(this.comicId, null);
        this.isFavorite = false;
        ToastUtil.show(Translations.t('favorite_removed'), 1500);
      } catch (e) {
        ToastUtil.fail(e);
      }
    } else {
      this.openFavSheet();
    }
  }

  private openFavSheet(): void {
    this.showFavSheet = true;
    this.newFolderName = '';
    this.loadFolders();
  }

  private async loadFolders(): Promise<void> {
    this.loadingFolders = true;
    try {
      this.folders = await JmApi.getFolders();
    } catch (e) {
      ToastUtil.fail(e);
      this.folders = [];
    }
    this.loadingFolders = false;
  }

  /** 收藏到指定收藏夹（'0'=未分类） */
  private async pickFolder(folderId: string): Promise<void> {
    if (this.favOperating) {
      return;
    }
    this.favOperating = true;
    try {
      await JmApi.favoriteComic(this.comicId, folderId);
      this.isFavorite = true;
      this.showFavSheet = false;
      ToastUtil.show(Translations.t('favorite_added'), 1500);
    } catch (e) {
      ToastUtil.fail(e);
    }
    this.favOperating = false;
  }

  /** 新建收藏夹（成功后刷新列表） */
  private async createFolder(): Promise<void> {
    const name: string = this.newFolderName.trim();
    if (name.length === 0) {
      ToastUtil.show(Translations.t('folder_name_hint'), 1500);
      return;
    }
    if (this.favOperating) {
      return;
    }
    this.favOperating = true;
    try {
      await JmApi.createFolder(name);
      this.newFolderName = '';
      ToastUtil.show(Translations.t('folder_created'), 1500);
      await this.loadFolders();
    } catch (e) {
      ToastUtil.fail(e);
    }
    this.favOperating = false;
  }

  /** 点赞 */
  private async toggleLike(): Promise<void> {
    if (!JmApi.isLoggedIn()) {
      ToastUtil.show(Translations.t('please_login'), 1500);
      return;
    }
    try {
      await JmApi.likeComic(this.comicId);
      this.isLiked = !this.isLiked;
      this.comic.likes = this.isLiked ? this.comic.likes + 1 : Math.max(0, this.comic.likes - 1);
    } catch (e) {
      ToastUtil.fail(e);
    }
  }

  private comicLink(): string {
    return `https://18comic.vip/album/${this.comicId}/`;
  }

  private share(): void {
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.comicLink());
      pasteboard.getSystemPasteboard().setData(data).then(() => {
        ToastUtil.show(Translations.t('link_copied'), 1500);
      }).catch(() => {
        ToastUtil.show(Translations.t('error'), 1500);
      });
    } catch (e) {
      ToastUtil.show(Translations.t('error'), 1500);
    }
  }

  /** 下载：始终打开章节多选弹窗（默认全选；面板内标注各章节已下载/排队/失败状态） */
  async download(): Promise<void> {
    if (this.chapters.length === 0) {
      return;
    }
    this.dlPicks = this.chapters.map((c: Chapter): string => c.id);
    const tasks: ChapterTask[] = await Database.queryChapterTasks(this.comicId);
    const statuses: Map<string, number> = new Map();
    for (const task of tasks) {
      statuses.set(task.chapterId, task.status);
    }
    this.dlStatuses = statuses;
    this.showDlSheet = true;
  }

  /** 下载按钮状态：存在任一下载完成的章节 → 「已下载」（删除下载后回到「下载」） */
  private async refreshDownloadState(): Promise<void> {
    const tasks: ChapterTask[] = await Database.queryChapterTasks(this.comicId);
    let done: boolean = false;
    for (const task of tasks) {
      if (task.status === ChapterDlStatus.DONE) {
        done = true;
        break;
      }
    }
    this.isDownloaded = done;
  }

  private async enqueueChapters(chapters: Chapter[]): Promise<void> {
    try {
      const n: number = await DownloadManager.enqueueComic(
        this.comicId, this.title, this.comic.coverUrl, this.source, chapters, this.comic);
      ToastUtil.show(Translations.t(n > 0 ? 'added_to_download' : 'dl_done'), 1500);
    } catch (e) {
      ToastUtil.show(Translations.t('error'), 1500);
    }
  }

  private toggleDlPick(id: string): void {
    if (this.dlPicks.includes(id)) {
      this.dlPicks = this.dlPicks.filter((x: string): boolean => x !== id);
    } else {
      const next: string[] = this.dlPicks.slice();
      next.push(id);
      this.dlPicks = next;
    }
  }

  private selectAllDl(): void {
    this.dlPicks = this.chapters.map((c: Chapter): string => c.id);
  }

  private async startDl(): Promise<void> {
    const picked: Chapter[] = this.chapters.filter(
      (c: Chapter): boolean => this.dlPicks.includes(c.id));
    this.showDlSheet = false;
    if (picked.length === 0) {
      return;
    }
    await this.enqueueChapters(picked);
  }

  private dlStatusLabel(status: number | undefined): string {
    if (status === undefined) {
      return '';
    }
    if (status === ChapterDlStatus.DONE) {
      return Translations.t('dl_done');
    }
    if (status === ChapterDlStatus.FAILED) {
      return Translations.t('dl_failed');
    }
    if (status === ChapterDlStatus.PAUSED) {
      return Translations.t('dl_paused');
    }
    if (status === ChapterDlStatus.RUNNING) {
      return Translations.t('dl_running');
    }
    return Translations.t('dl_queued');
  }

  private openComments(): void {
    const param: Record<string, Object> = {
      'comicId': this.comicId, 'source': this.source, 'title': this.title
    };
    NavUtil.push('comments', param);
  }

  /** 进入阅读器：同步转场（消除点击后的网络等待「假死」），章节图片由阅读器自取并显示 loading */
  private startReading(chapterOrder: number): void {
    const param: ReaderParam = new ReaderParam(
      this.comicId, this.source, this.title, [], this.chapters, chapterOrder);
    NavUtil.push('reader', param);
  }

  /** 主按钮：有进度则继续（回到记录章节），否则从第 1 章开始 */
  private primaryRead(): void {
    if (this.chapters.length > 0) {
      const targetOrder = this.resumeChapterOrder > 0 ? this.resumeChapterOrder : this.chapters[0].order;
      this.startReading(targetOrder);
    } else {
      this.startReading(1);
    }
  }

  private searchTag(tag: string): void {
    const param: Record<string, Object> = { 'keyword': tag };
    NavUtil.push('search', param);
  }

  /** 过滤空白标签（接口偶发空串，避免渲染出空小气泡） */
  private visibleCategories(): string[] {
    return this.comic.categories.filter((t: string) => t.trim().length > 0);
  }

  /** 长文本值：限制在行内宽度 + 允许换行（超短文本保持紧凑小按钮） */
  private isLongValue(expand: boolean, value: string): boolean {
    return expand || value.length > 24;
  }

  private openRelated(id: string, source: string): void {
    const param: Record<string, Object> = { 'comicId': id, 'title': '', 'source': source };
    NavUtil.push('comicDetail', param);
  }

  private displayChapters(): Chapter[] {
    let list: Chapter[] = this.chapters;
    if (this.chaptersReversed) {
      const reversed: Chapter[] = [];
      for (let i = list.length - 1; i >= 0; i--) {
        reversed.push(list[i]);
      }
      list = reversed;
    }
    if (this.showAllChapters || list.length <= CHAPTER_COLLAPSE_THRESHOLD) {
      return list;
    }
    return list.slice(0, CHAPTER_COLLAPSE_THRESHOLD);
  }

  @Builder
  heroSection() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 模糊封面背景，延伸至状态栏
      Column() {
        Image(this.coverSource())
          .width('100%').height('110%')
          .objectFit(ImageFit.Cover)
          .blur(24)
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      }
      .width('100%').height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])

      // 可读性遮罩：顶部压暗模糊图，底部渐入页面底色（深浅色自适应）
      Column()
        .width('100%').height('110%')
        .linearGradient({
          angle: 180,
          colors: [[$r('app.color.media_scrim'), 0.0], [$r('app.color.bg_page'), 1.0]]
        })
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])

      // 前景：封面 + 基础信息 + 开始阅读 + 操作按钮
      Column({ space: 12 }) {
        Row({ space: 16 }) {
          Image(this.coverSource())
            .width(130).height(180)
            .objectFit(ImageFit.Cover)
            .borderRadius(10)
            .backgroundColor($r('app.color.bg_fill'))
            .shadow({ radius: 12, color: $r('app.color.shadow') })
          Column({ space: 8 }) {
            Text(this.comic.title)
              .fontSize(20).fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
            if (this.comic.author.length > 0) {
              Text(Translations.t('author') + ': ' + this.comic.author)
                .fontSize(14).fontColor($r('app.color.text_secondary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            Row({ space: 12 }) {
              Row({ space: 4 }) {
                SymbolGlyph($r('sys.symbol.heart'))
                  .fontSize(14)
                  .fontColor([$r('app.color.danger')])
                Text(this.comic.likes.toString())
                  .fontSize(13).fontColor($r('app.color.danger'))
              }
              Row({ space: 4 }) {
                SymbolGlyph($r('sys.symbol.message'))
                  .fontSize(14)
                  .fontColor([$r('app.color.text_secondary')])
                Text(this.comic.comments.toString())
                  .fontSize(13).fontColor($r('app.color.text_secondary'))
              }
            }
            Text(Translations.t('jm_name'))
              .fontSize(12).fontColor(this.themeColor)
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor($r('app.color.bg_fill'))
              .borderRadius(10)
            Button(this.primaryLabel())
              .width('100%')
              .height(44)
              .fontSize(15)
              .fontColor($r('app.color.text_on_brand'))
              .backgroundColor(this.themeColor)
              .borderRadius(22)
              .margin({ top: 4 })
              .onClick(() => { this.primaryRead(); })
              .id('heroReadButton')
          }
          .layoutWeight(1).alignItems(HorizontalAlign.Start)
        }
        .width('100%')

        this.heroActionRow()
      }
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP])
      .padding({ left: 16, right: 16, top: this.topAvoid + 56, bottom: 16 })
    }
    .width('100%')
    .height(360)
    .id('heroSection')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
  }

  @Builder
  navTitleBar() {
    Row({ space: 8 }) {
      Button({ type: ButtonType.Normal, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([$r('app.color.content_on_media')])
      }
      .width(40).height(40)
      .borderRadius(24)
      .backgroundColor(Color.Transparent)
      .systemMaterial(this.favoriteMaterial)
      .onClick(() => { NavUtil.back(); })
      Blank().layoutWeight(1)
      Button({ type: ButtonType.Normal, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.star'))
          .fontSize(20)
          .fontColor([this.isFavorite ? this.themeColor : $r('app.color.content_on_media')])
      }
      .width(40).height(40)
      .borderRadius(24)
      .backgroundColor(Color.Transparent)
      .systemMaterial(this.favoriteMaterial)
      .onClick(() => { this.toggleFavorite(); })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
  }

  /** 基本信息行：label chip + 值 chip（点击值即跳转搜索）。长文本（名称/超长作者）宽度限制在行内、超长换行最多 2 行 */
  @Builder
  infoRow(label: string, value: string, expand: boolean) {
    Row({ space: ChipTokens.GAP }) {
      Text(label)
        .fontSize(ChipTokens.FONT_SIZE)
        .fontColor($r('app.color.text_secondary'))
        .padding({
          left: ChipTokens.PAD_H, right: ChipTokens.PAD_H,
          top: ChipTokens.PAD_V, bottom: ChipTokens.PAD_V
        })
        .backgroundColor($r('app.color.bg_fill'))
        .borderRadius(ChipTokens.RADIUS)
      Text(value)
        .fontSize(ChipTokens.FONT_SIZE)
        .fontColor(this.themeColor)
        .backgroundColor($r('app.color.bg_fill'))
        .padding({
          left: ChipTokens.PAD_H, right: ChipTokens.PAD_H,
          top: ChipTokens.PAD_V, bottom: ChipTokens.PAD_V
        })
        .borderRadius(ChipTokens.RADIUS)
        .maxLines(this.isLongValue(expand, value) ? 2 : 1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(this.isLongValue(expand, value) ? 1 : 0)
        .onClick(() => { this.searchTag(value); })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .id('infoRow' + label)
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
  }

  @Builder
  relatedSection() {
    Column({ space: 10 }) {
      Text(Translations.t('related_comics'))
        .fontSize(16).fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
      Scroll() {
        Row({ space: 10 }) {
          ForEach(this.comic.relatedComics, (c: Comic) => {
            Column({ space: 6 }) {
              NetworkImage({ url: c.coverUrl, imgWidth: 104, imgHeight: 146, imgBorderRadius: 8 })
              Text(c.title)
                .fontSize(12).fontColor($r('app.color.text_primary'))
                .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                .width(104)
                .textAlign(TextAlign.Start)
            }
            .width(104)
            .onClick(() => { this.openRelated(c.id, c.source); })
            .id('related' + c.id)
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
          }, (c: Comic) => c.id)
        }
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16 })
    .id('relatedSection')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
  }

  @Builder
  chapterGrid() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text(`${Translations.t('chapters')} (${this.chapters.length})`)
          .fontSize(16).fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text(Translations.t('sort'))
          .fontSize(13)
          .fontColor(this.themeColor)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor($r('app.color.bg_fill'))
          .borderRadius(12)
          .onClick(() => {
            this.chaptersReversed = !this.chaptersReversed;
            this.chapterSource.replaceAll(this.displayChapters());
          })
      }
      .width('100%')

      Grid() {
        LazyForEach(this.chapterSource, (chapter: Chapter) => {
          GridItem() {
            Text(chapter.title.length > 0 ? chapter.title : `${chapter.order}`)
              .fontSize(13)
              .fontColor(this.resumeChapterOrder === chapter.order ? this.themeColor : $r('app.color.text_primary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .height(44)
              .textAlign(TextAlign.Center)
              .backgroundColor(this.resumeChapterOrder === chapter.order ? $r('app.color.bg_fill') : $r('app.color.bg_surface'))
              .borderRadius(22)
              .onClick(() => { this.startReading(chapter.order); })
            }
            .id('chapter' + chapter.id)
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
          }, (chapter: Chapter) => chapter.id + chapter.order.toString())
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])

      if (this.chapters.length > CHAPTER_COLLAPSE_THRESHOLD && !this.showAllChapters) {
        Text(`${Translations.t('show_all')} (${this.chapters.length})`)
          .fontSize(13)
          .fontColor(this.themeColor)
          .width('100%').height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.showAllChapters = true;
            this.chapterSource.replaceAll(this.displayChapters());
          })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .id('chapterGrid')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
  }

  @Builder
  heroActionRow() {
    Row({ space: 17 }) {
      Button({type:ButtonType.Circle, stateEffect: true }) {
        Column({ space: 5 }) {
          SymbolGlyph($r('sys.symbol.message'))
            .fontSize(24)
            .fontColor([$r('app.color.text_primary')])
          Text(Translations.t('comments'))
            .fontSize(12)
            .fontColor($r('app.color.text_primary'))
        }
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .height(72)
      .backgroundColor(Color.Transparent)
      .onClick(() => { this.openComments(); })

      Button({type:ButtonType.Circle, stateEffect: true }) {
        Column({ space: 5 }) {
          SymbolGlyph($r('sys.symbol.share'))
            .fontSize(24)
            .fontColor([$r('app.color.text_primary')])
          Text(Translations.t('share'))
            .fontSize(12)
            .fontColor($r('app.color.text_primary'))
        }
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .height(72)
      .backgroundColor(Color.Transparent)
      .onClick(() => { this.share(); })

      Button({type:ButtonType.Circle, stateEffect: true }) {
        Column({ space: 5 }) {
          SymbolGlyph($r('sys.symbol.heart'))
            .fontSize(24)
            .fontColor([this.isLiked ? $r('app.color.danger') : $r('app.color.text_primary')])
          Text(Translations.t('likes'))
            .fontSize(12)
            .fontColor(this.isLiked ? $r('app.color.danger') : $r('app.color.text_primary'))
        }
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .height(72)
      .backgroundColor(Color.Transparent)
      .onClick(() => { this.toggleLike(); })

      Button({type:ButtonType.Circle, stateEffect: true }) {
        Column({ space: 5 }) {
          SymbolGlyph(this.isDownloaded
            ? $r('sys.symbol.checkmark_circle_fill') : $r('sys.symbol.arrow_down_circle'))
            .fontSize(24)
            .fontColor([this.isDownloaded ? this.themeColor : $r('app.color.text_primary')])
          Text(this.isDownloaded ? Translations.t('dl_done') : Translations.t('download'))
            .fontSize(12)
            .fontColor(this.isDownloaded ? this.themeColor : $r('app.color.text_primary'))
        }
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .height(72)
      .backgroundColor(Color.Transparent)
      .onClick(() => { this.download(); })
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .id('heroActionRow')
  }

  private primaryLabel(): string {
    if (this.resumePage > 0) {
      return `${Translations.t('continue_reading_prefix')}`;
    }
    return Translations.t('start_reading');
  }

  @Builder
  favFolderRow(label: string, folderId: string) {
    Row({ space: 8 }) {
      SymbolGlyph($r('sys.symbol.folder'))
        .fontSize(18)
        .fontColor([this.themeColor])
      Text(label)
        .fontSize(15).fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(13)
        .fontColor([$r('app.color.text_tertiary')])
    }
    .width('100%').height(50)
    .padding({ left: 16, right: 16 })
    .onClick(() => { this.pickFolder(folderId); })
    .id('favFolderRow' + folderId)
  }

  @Builder
  favSheetContent() {
    Column({ space: 0 }) {
      if (this.loadingFolders) {
        Column({ space: 8 }) {
          LoadingProgress().width(36).height(36)
        }
        .width('100%').height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 0 }) {
            if (this.isFavorite) {
              Row({ space: 8 }) {
                SymbolGlyph($r('sys.symbol.star_slash'))
                  .fontSize(18)
                  .fontColor([$r('app.color.danger')])
                Text(Translations.t('cancel_favorite'))
                  .fontSize(15).fontColor($r('app.color.danger'))
                  .layoutWeight(1)
              }
              .width('100%').height(50)
              .padding({ left: 16, right: 16 })
              .onClick(() => {
                this.showFavSheet = false;
                this.toggleFavorite();
              })
            }

            this.favFolderRow(Translations.t('uncategorized'), '0')
            ForEach(this.folders, (folder: JmFolder) => {
              this.favFolderRow(folder.name, folder.id)
            }, (folder: JmFolder) => folder.id + folder.name)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .align(Alignment.TopStart)
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])

        Divider()
          .color($r('app.color.divider'))
          .margin({ top: 8, bottom: 8 })

        Row({ space: 8 }) {
          TextInput({ placeholder: Translations.t('folder_name_hint'), text: this.newFolderName })
            .fontSize(14)
            .fontColor($r('app.color.text_primary'))
            .placeholderColor($r('app.color.text_secondary'))
            .caretColor(this.themeColor)
            .layoutWeight(1)
            .backgroundColor($r('app.color.bg_surface'))
            .onChange((v: string) => { this.newFolderName = v; })
          Button(Translations.t('confirm'))
            .fontSize(14)
            .backgroundColor(this.themeColor)
            .fontColor($r('app.color.text_on_brand'))
            .onClick(() => { this.createFolder(); })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 4, bottom: 16 })
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
      }
    }
    .width('100%')
    .height('100%')
    .id('favSheetContent')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
  }

  @Builder
  dlChapterRow(chapter: Chapter) {
    Row({ space: 10 }) {
      SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
        .fontSize(20)
        .fontColor([this.dlPicks.includes(chapter.id) ? this.themeColor : $r('app.color.text_tertiary')])
        .opacity(this.dlPicks.includes(chapter.id) ? 1 : 0.35)
      Column({ space: 2 }) {
        Text(chapter.title.length > 0 ? chapter.title : `${chapter.order}`)
          .fontSize(15)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Start)
        if (this.dlStatuses.has(chapter.id)) {
          Text(this.dlStatusLabel(this.dlStatuses.get(chapter.id)))
            .fontSize(11)
            .fontColor(this.dlStatuses.get(chapter.id) === ChapterDlStatus.FAILED
              ? $r('app.color.danger') : $r('app.color.text_secondary'))
            .width('100%')
            .textAlign(TextAlign.Start)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .onClick(() => { this.toggleDlPick(chapter.id); })
    .id('dlChapterRow' + chapter.id)
  }

  @Builder
  dlSheetContent() {
    Column({ space: 0 }) {
      Row({ space: 8 }) {
        Text(`${this.dlPicks.length}${Translations.t('items_suffix')}`)
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .layoutWeight(1)
        Text(Translations.t('select_all'))
          .fontSize(13)
          .fontColor(this.themeColor)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor($r('app.color.bg_fill'))
          .borderRadius(12)
          .onClick(() => { this.selectAllDl(); })
        Text(Translations.t('clear_selection'))
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .backgroundColor($r('app.color.bg_fill'))
          .borderRadius(12)
          .onClick(() => { this.dlPicks = []; })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 4, bottom: 4 })

      Scroll() {
        Column({ space: 0 }) {
          ForEach(this.chapters, (chapter: Chapter) => {
            this.dlChapterRow(chapter)
          }, (chapter: Chapter): string => chapter.id + chapter.order.toString())
        }
        .width('100%')
      }
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])

      Divider()
        .color($r('app.color.divider'))
        .margin({ top: 8 })

      Row() {
        Button(Translations.t('start_download'),
          { type: ButtonType.ROUNDED_RECTANGLE, stateEffect: true })
          .width('100%')
          .buttonStyle(ButtonStyleMode.EMPHASIZED)
          .backgroundColor(this.themeColor)
          .fontColor($r('app.color.text_on_brand'))
          .enabled(this.dlPicks.length > 0)
          .opacity(this.dlPicks.length > 0 ? 1 : 0.4)
          .onClick(() => { this.startDl(); })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 16 })
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
    }
    .width('100%')
    .height('100%')
    .id('dlSheetContent')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
  }

  build() {
    NavDestination() {
      
        Stack({ alignContent: Alignment.Top }) {
          if (this.loading) {
            Column({ space: 8 }) {
              LoadingProgress().width(48).height(48)
            }
            .width('100%').height('100%')
            .justifyContent(FlexAlign.Center)
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
          } else if (this.error.length > 0) {
            Column({ space: 12 }) {
              Text(this.error).fontSize(14).fontColor($r('app.color.danger'))
              Button(Translations.t('retry'))
                .fontSize(14)
                .backgroundColor(this.themeColor)
                .fontColor($r('app.color.text_on_brand'))
                .onClick(() => { this.loadDetail(); })
            }
            .width('100%').height('100%')
            .justifyContent(FlexAlign.Center)
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
          } else {
            Scroll() {
              Column({ space: 0 }) {
                this.heroSection()

                if (this.comic.description.length > 0) {
                  Text(this.comic.description)
                    .fontSize(14)
                    .fontColor($r('app.color.text_primary'))
                    .lineHeight(22)
                    .width('100%')
                    .padding({ left: 16, right: 16, top: 14 })
                    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
                }

                // 基本信息栏：名称 / ID / 作者（与标签同级）
                Column({ space: 8 }) {
                  this.infoRow(Translations.t('name_label'), this.comic.title, true)
                  this.infoRow(Translations.t('id_label'), this.comicId, false)
                  if (this.comic.author.length > 0) {
                    this.infoRow(Translations.t('author'), this.comic.author, false)
                  }
                }
                .width('100%')
                .padding({ left: 16, right: 16, top: 12 })
                .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])

                if (this.visibleCategories().length > 0) {
                  Flex({ wrap: FlexWrap.Wrap }) {
                    Text(Translations.t('tags_label'))
                      .fontSize(ChipTokens.FONT_SIZE)
                      .fontColor($r('app.color.text_secondary'))
                      .backgroundColor($r('app.color.bg_fill'))
                      .padding({
                        left: ChipTokens.PAD_H, right: ChipTokens.PAD_H,
                        top: ChipTokens.PAD_V, bottom: ChipTokens.PAD_V
                      })
                      .borderRadius(ChipTokens.RADIUS)
                      .margin({ right: ChipTokens.GAP, bottom: ChipTokens.GAP })
                      .id('detailTagLabel')
                    ForEach(this.visibleCategories(), (tag: string) => {
                      Text(tag)
                        .fontSize(ChipTokens.FONT_SIZE)
                        .fontColor(this.themeColor)
                        .backgroundColor($r('app.color.bg_fill'))
                        .borderRadius(ChipTokens.RADIUS)
                        .padding({
                          left: ChipTokens.PAD_H, right: ChipTokens.PAD_H,
                          top: ChipTokens.PAD_V, bottom: ChipTokens.PAD_V
                        })
                        .margin({ right: ChipTokens.GAP, bottom: ChipTokens.GAP })
                        .onClick(() => { this.searchTag(tag); })
                        .id('detailTag' + tag)
                    }, (tag: string) => tag)
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 12 })
                  .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
                }

                if (this.chapters.length > 1) {
                  this.chapterGrid()
                }

                if (this.comic.relatedComics.length > 0) {
                  this.relatedSection()
                }

                Blank().height(32 + this.bottomAvoid)
              }
              .width('100%')
              .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
          }
        }
        .width('100%').height('100%')
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
        .bindSheet($$this.showFavSheet, this.favSheetContent(), {
          detents: [SheetSize.MEDIUM, SheetSize.LARGE],
          blurStyle: BlurStyle.COMPONENT_THICK,
          showClose: true,
          title: { title: Translations.t('favorite_select_folder') },
          dragBar: true,
          scrollSizeMode: ScrollSizeMode.CONTINUOUS,
          shouldDismiss: () => {
            this.showFavSheet = false;
          },
          systemMaterial: new uiMaterial.ImmersiveMaterial({
            style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
          })
        })
        .bindSheet($$this.showDlSheet, this.dlSheetContent(), {
          detents: [SheetSize.MEDIUM, SheetSize.LARGE],
          blurStyle: BlurStyle.COMPONENT_THICK,
          showClose: true,
          title: { title: Translations.t('select_chapters') },
          dragBar: true,
          scrollSizeMode: ScrollSizeMode.CONTINUOUS,
          shouldDismiss: () => {
            this.showDlSheet = false;
          },
          systemMaterial: new uiMaterial.ImmersiveMaterial({
            style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
          })
        })
      
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .title(this.navTitleBar(), { barStyle: BarStyle.STACK, backgroundColor: Color.Transparent })
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .hideBackButton(true)
    .onShown(() => { this.checkResume(); })
    .backgroundColor($r('app.color.bg_page'))
  }
}
