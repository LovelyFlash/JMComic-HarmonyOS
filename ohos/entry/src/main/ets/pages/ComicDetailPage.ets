// pages/ComicDetailPage.ets - 漫画详情页（JM：沉浸式头图 + 章节 + 相关推荐 + 云收藏 + 点赞）- NavDestination
import { pasteboard } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { Comic } from '../data/model/Comic';
import { Chapter } from '../data/model/Chapter';
import { ReaderParam } from '../data/model/ReaderParam';
import { Database, ReadingProgress } from '../data/database/Database';
import { JmApi, JmFolder } from '../data/api/JmApi';
import { NetworkImage } from '../components/NetworkImage';

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
  @State startingRead: boolean = false
  @State resumePage: number = 0
  @State resumeChapterOrder: number = 0
  // 云收藏 sheet
  @State showFavSheet: boolean = false
  @State folders: JmFolder[] = []
  @State loadingFolders: boolean = false
  @State newFolderName: string = ''
  @State favOperating: boolean = false
  
  @StorageProp('themeColor') themeColor: string = '#2563EB'
  @StorageProp('topAvoidHeight') topAvoid: number = 0
  @StorageProp('bottomAvoidHeight') bottomAvoid: number = 0

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

  async loadDetail(): Promise<void> {
    this.loading = true;
    this.error = '';
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
      this.isFavorite = this.comic.isFavorite;
      this.isLiked = this.comic.isLiked;
      await Database.insertHistory(this.comicId, this.title, this.comic.coverUrl, this.source);
    } catch (e) {
      this.error = String(e);
    }
    this.loading = false;
  }

  async checkResume(): Promise<void> {
    const progress: ReadingProgress = await Database.getReadingProgress(this.comicId, this.source);
    this.resumePage = progress.lastPage;
    this.resumeChapterOrder = progress.lastChapter.length > 0 ? Number(progress.lastChapter) : 0;
  }

  /** 收藏星标：已收藏→取消；未收藏→弹收藏夹 sheet */
  async toggleFavorite(): Promise<void> {
    if (!JmApi.isLoggedIn()) {
      promptAction.showToast({ message: Translations.t('please_login'), duration: 1500 });
      return;
    }
    if (this.isFavorite) {
      try {
        await JmApi.favoriteComic(this.comicId, null);
        this.isFavorite = false;
        promptAction.showToast({ message: Translations.t('favorite_removed'), duration: 1500 });
      } catch (e) {
        promptAction.showToast({ message: String(e), duration: 1500 });
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
      promptAction.showToast({ message: String(e), duration: 1500 });
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
      promptAction.showToast({ message: Translations.t('favorite_added'), duration: 1500 });
    } catch (e) {
      promptAction.showToast({ message: String(e), duration: 1500 });
    }
    this.favOperating = false;
  }

  /** 新建收藏夹（成功后刷新列表） */
  private async createFolder(): Promise<void> {
    const name: string = this.newFolderName.trim();
    if (name.length === 0) {
      promptAction.showToast({ message: Translations.t('folder_name_hint'), duration: 1500 });
      return;
    }
    if (this.favOperating) {
      return;
    }
    this.favOperating = true;
    try {
      await JmApi.createFolder(name);
      this.newFolderName = '';
      promptAction.showToast({ message: Translations.t('folder_created'), duration: 1500 });
      await this.loadFolders();
    } catch (e) {
      promptAction.showToast({ message: String(e), duration: 1500 });
    }
    this.favOperating = false;
  }

  /** 点赞 */
  private async toggleLike(): Promise<void> {
    if (!JmApi.isLoggedIn()) {
      promptAction.showToast({ message: Translations.t('please_login'), duration: 1500 });
      return;
    }
    try {
      await JmApi.likeComic(this.comicId);
      this.isLiked = !this.isLiked;
      this.comic.likes = this.isLiked ? this.comic.likes + 1 : Math.max(0, this.comic.likes - 1);
    } catch (e) {
      promptAction.showToast({ message: String(e), duration: 1500 });
    }
  }

  private comicLink(): string {
    return `https://18comic.vip/album/${this.comicId}/`;
  }

  private share(): void {
    try {
      const data = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.comicLink());
      pasteboard.getSystemPasteboard().setData(data).then(() => {
        promptAction.showToast({ message: Translations.t('link_copied'), duration: 1500 });
      }).catch(() => {
        promptAction.showToast({ message: Translations.t('error'), duration: 1500 });
      });
    } catch (e) {
      promptAction.showToast({ message: Translations.t('error'), duration: 1500 });
    }
  }

  async download(): Promise<void> {
    try {
      await Database.insertDownload(this.comicId, this.title, this.comic.coverUrl, this.source, '');
      promptAction.showToast({ message: Translations.t('added_to_download'), duration: 1500 });
    } catch (e) {
      promptAction.showToast({ message: Translations.t('error'), duration: 1500 });
    }
  }

  private openComments(): void {
    const param: Record<string, Object> = {
      'comicId': this.comicId, 'source': this.source, 'title': this.title
    };
    NavUtil.push('comments', param);
  }

  /** 进入阅读器：按章节 order 找章节 id 加载图片 */
  async startReading(chapterOrder: number): Promise<void> {
    if (this.startingRead) {
      return;
    }
    this.startingRead = true;
    try {
      let chapterId: string = this.comicId;
      for (let i = 0; i < this.chapters.length; i++) {
        if (this.chapters[i].order === chapterOrder) {
          chapterId = this.chapters[i].id;
          break;
        }
      }
      const ch: Chapter = await JmApi.getChapter(chapterId);
      const images: string[] = ch.imageUrls;
      if (images.length === 0) {
        promptAction.showToast({ message: Translations.t('no_images'), duration: 1500 });
      } else {
        const param: ReaderParam = new ReaderParam(
          this.comicId, this.source, this.title, images, this.chapters, chapterOrder);
        NavUtil.push('reader', param);
      }
    } catch (e) {
      this.error = String(e);
      promptAction.showToast({ message: Translations.t('error'), duration: 1500 });
    }
    this.startingRead = false;
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
      // 模糊封面背景 + 渐变遮罩，延伸至状态栏
      Column() {
        Image(this.comic.coverUrl)
          .width('100%').height('100%')
          .objectFit(ImageFit.Cover)
          .blur(24)
      }
      .width('100%').height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])

      // 前景：封面 + 基础信息
      Row({ space: 16 }) {
        Image(this.comic.coverUrl)
          .width(130).height(180)
          .objectFit(ImageFit.Cover)
          .borderRadius(10)
          .backgroundColor($r('app.color.bg_fill'))
          .shadow({ radius: 12, color: $r('app.color.shadow') })
        Column({ space: 8 }) {
          Text(this.comic.title)
            .fontSize(18).fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.comic.author.length > 0) {
            Text(Translations.t('author') + ': ' + this.comic.author)
              .fontSize(13).fontColor($r('app.color.text_secondary'))
              .maxLines(2)
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
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: this.topAvoid + 56 })
    }
    .width('100%')
    .height(280 + this.topAvoid)
    .id('heroSection')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
  }

  @Builder
  floatingTopBar() {
    Row({ space: 8 }) {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([Color.White])
      }
      .width(40).height(40)
      .backgroundColor('rgba(0,0,0,0.25)')
      .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
      .onClick(() => { NavUtil.back(); })
      Blank().layoutWeight(1)
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.star'))
          .fontSize(20)
          .fontColor([this.isFavorite ? this.themeColor : Color.White])
      }
      .width(40).height(40)
      .backgroundColor('rgba(0,0,0,0.25)')
      .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
      .onClick(() => { this.toggleFavorite(); })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: this.topAvoid + 8 })
    .id('floatingTopBar')
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
          }, (c: Comic) => c.id)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 16 })
    .id('relatedSection')
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
          .onClick(() => { this.chaptersReversed = !this.chaptersReversed; })
      }
      .width('100%')

      Grid() {
        ForEach(this.displayChapters(), (chapter: Chapter) => {
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
          }, (chapter: Chapter) => chapter.id + chapter.order.toString() + this.chaptersReversed.toString())
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(8)
      .rowsGap(8)
      .width('100%')

      if (this.chapters.length > CHAPTER_COLLAPSE_THRESHOLD && !this.showAllChapters) {
        Text(`${Translations.t('show_all')} (${this.chapters.length})`)
          .fontSize(13)
          .fontColor(this.themeColor)
          .width('100%').height(40)
          .textAlign(TextAlign.Center)
          .onClick(() => { this.showAllChapters = true; })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .id('chapterGrid')
  }

  @Builder
  bottomBar() {
    Row({ space: 10 }) {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.message'))
          .fontSize(20)
          .fontColor([$r('app.color.text_primary')])
      }
      .width(46).height(46)
      .backgroundColor($r('app.color.bg_surface'))
      .onClick(() => { this.openComments(); })

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.share'))
          .fontSize(20)
          .fontColor([$r('app.color.text_primary')])
      }
      .width(46).height(46)
      .backgroundColor($r('app.color.bg_surface'))
      .onClick(() => { this.share(); })

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.heart'))
          .fontSize(20)
          .fontColor([this.isLiked ? $r('app.color.danger') : $r('app.color.text_primary')])
      }
      .width(46).height(46)
      .backgroundColor($r('app.color.bg_surface'))
      .onClick(() => { this.toggleLike(); })

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.arrow_down_circle'))
          .fontSize(20)
          .fontColor([$r('app.color.text_primary')])
      }
      .width(46).height(46)
      .backgroundColor($r('app.color.bg_surface'))
      .onClick(() => { this.download(); })

      Button(this.primaryLabel())
        .layoutWeight(1)
        .height(46)
        .fontSize(15)
        .fontColor($r('app.color.text_on_brand'))
        .backgroundColor(this.themeColor)
        .borderRadius(23)
        .onClick(() => { this.primaryRead(); })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: this.bottomAvoid + 8 })
    .backgroundColor($r('app.color.bg_page'))
    .alignItems(VerticalAlign.Center)
    .id('bottomBar')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
  }

  private primaryLabel(): string {
    if (this.resumePage > 0) {
      return `${Translations.t('continue_reading_prefix')}${this.resumePage + 1}`;
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
        Row({ space: 8 }) {
          Text(Translations.t('favorite_select_folder'))
            .fontSize(17).fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize(16)
              .fontColor([$r('app.color.text_secondary')])
          }
          .width(32).height(32)
          .backgroundColor(Color.Transparent)
          .onClick(() => { this.showFavSheet = false; })
        }
        .width('100%')
        .padding({ left: 16, right: 12, top: 14, bottom: 6 })
        .alignItems(VerticalAlign.Center)

        if (this.loadingFolders) {
          Column({ space: 8 }) {
            LoadingProgress().width(36).height(36)
          }
          .width('100%').height(200)
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
            }
            .width('100%')
          }
          .layoutWeight(1)
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
      .id('favSheetContent')
    
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
                }

                if (this.comic.categories.length > 0) {
                  Flex({ wrap: FlexWrap.Wrap }) {
                    ForEach(this.comic.categories, (tag: string) => {
                      Text(tag)
                        .fontSize(12)
                        .fontColor(this.themeColor)
                        .backgroundColor($r('app.color.bg_fill'))
                        .borderRadius(12)
                        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                        .margin({ right: 6, bottom: 6 })
                        .onClick(() => { this.searchTag(tag); })
                        .id('detailTag' + tag)
                    }, (tag: string) => tag)
                  }
                  .width('100%')
                  .padding({ left: 16, right: 16, top: 12 })
                }

                if (this.chapters.length > 1) {
                  this.chapterGrid()
                }

                if (this.comic.relatedComics.length > 0) {
                  this.relatedSection()
                }

                Blank().height(120 + this.bottomAvoid)
              }
              .width('100%')
              .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
            }
            .layoutWeight(1)
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])

            this.floatingTopBar()
            Column() {
              Blank().layoutWeight(1)
              this.bottomBar()
            }
            .width('100%').height('100%')
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
          }
        }
        .width('100%').height('100%')
        .backgroundColor($r('app.color.bg_page'))
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
        .bindSheet($$this.showFavSheet, this.favSheetContent(), {
          detents: [SheetSize.MEDIUM, SheetSize.LARGE],
          blurStyle: BlurStyle.COMPONENT_THICK,
          showClose: false,
          dragBar: true,
          shouldDismiss: () => {
            this.showFavSheet = false;
          }
        })
      
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_page'))
  }
}
