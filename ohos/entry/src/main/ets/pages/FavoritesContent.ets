// pages/FavoritesContent.ets - 收藏内容组件（禁漫云收藏）
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { NetworkImage } from '../components/NetworkImage';
import { ToastUtil } from '../common/ToastUtil';
import { JmApi, JmFolder } from '../data/api/JmApi';
import { Comic } from '../data/model/Comic';
import { ArrayDataSource } from '../common/ArrayDataSource';
import { DEFAULT_THEME_COLOR } from '../common/Constants';
import { ListCache, CachedComicPage } from '../data/cache/ListCache';
import { uiMaterial } from '@kit.ArkUI';

@Component
export struct FavoritesContent {
  // 禁漫云收藏
  @State loggedIn: boolean = false
  @State folders: JmFolder[] = []
  @State currentFolder: string = '0'
  @State cloudDataSource: ArrayDataSource<Comic> = new ArrayDataSource<Comic>()
  @State cloudLoading: boolean = false
  @State cloudRefreshing: boolean = false
  @State cloudLoadingMore: boolean = false
  @State cloudError: string = ''
  @State currentPage: number = 1
  @State maxPage: number = 1
  @State showNewFolderSheet: boolean = false
  @State newFolderName: string = ''
  /** 已加载漫画 id 集合：防服务器分页数据重叠/超页返回导致内容重复 */
  private cloudLoadedIds: Set<string> = new Set<string>()
  @StorageProp('jmAccountChanged') @Watch('onAccountChanged') jmAccountChanged: number = 0

  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR

  aboutToAppear(): void {
    // 先读本地缓存秒开列表，再后台请求最新数据
    this.restoreCachedData().then(() => {
      this.refreshLoginState();
    });
  }

  private onAccountChanged(): void {
    // 账号切换：清空上一账号的列表，再恢复新账号缓存并刷新
    this.folders = [];
    this.currentFolder = '0';
    this.cloudDataSource.clearData();
    this.cloudLoadedIds = new Set<string>();
    this.currentPage = 1;
    this.maxPage = 1;
    this.cloudLoading = false;
    this.cloudError = '';
    this.restoreCachedData().then(() => {
      this.refreshLoginState();
    });
  }

  private cacheUserId(): string {
    return JmApi.getUserId();
  }

  /** 恢复收藏夹列表 + 当前收藏夹首屏漫画缓存 */
  private async restoreCachedData(): Promise<void> {
    if (!JmApi.isLoggedIn()) {
      return;
    }
    const userId: string = this.cacheUserId();
    const cachedFolders: JmFolder[] | null = await ListCache.loadFolders(userId);
    if (cachedFolders !== null) {
      this.folders = cachedFolders;
      // 当前收藏夹已不存在时回退到「全部」
      if (this.currentFolder !== '0') {
        let found: boolean = false;
        for (let i = 0; i < this.folders.length; i++) {
          if (this.folders[i].id === this.currentFolder) {
            found = true;
            break;
          }
        }
        if (!found) {
          this.currentFolder = '0';
        }
      }
    }
    await this.restoreCachedPage(this.currentFolder);
  }

  /** 恢复指定收藏夹的首屏缓存；无缓存时清空旧列表避免串数据 */
  private async restoreCachedPage(folderId: string): Promise<void> {
    const cached: CachedComicPage | null = await ListCache.loadFolderComics(this.cacheUserId(), folderId);
    if (cached === null) {
      this.cloudDataSource.clearData();
      this.cloudLoadedIds = new Set<string>();
      this.currentPage = 1;
      this.maxPage = 1;
      return;
    }
    this.currentPage = 1;
    this.maxPage = cached.maxPage > 0 ? cached.maxPage : 1;
    this.cloudLoadedIds = new Set<string>();
    for (let i = 0; i < cached.comics.length; i++) {
      this.cloudLoadedIds.add(cached.comics[i].id);
    }
    this.cloudDataSource.replaceAll(cached.comics);
  }

  private refreshLoginState(): void {
    this.loggedIn = JmApi.isLoggedIn();
    if (this.loggedIn) {
      // 无缓存时才展示整页加载态；有缓存则直接展示旧数据并后台刷新
      if (this.cloudDataSource.totalCount() === 0) {
        this.cloudLoading = true;
      }
      this.cloudError = '';
      this.loadFolders();
    } else {
      this.cloudLoading = false;
      this.cloudError = '';
    }
  }

  private async loadFolders(): Promise<void> {
    try {
      const fresh: JmFolder[] = await JmApi.getFolders();
      this.folders = fresh;
      ListCache.saveFolders(this.cacheUserId(), fresh).catch((e: Object) => {
        // 缓存写入失败不影响页面
      });
    } catch (e) {
      // 请求失败时保留已恢复的缓存收藏夹
    }
    if (this.currentFolder !== '0') {
      let found: boolean = false;
      for (let i = 0; i < this.folders.length; i++) {
        if (this.folders[i].id === this.currentFolder) {
          found = true;
          break;
        }
      }
      if (!found) {
        this.currentFolder = '0';
      }
    }
    await this.loadCloudPage(1, true);
  }

  /** 下拉刷新：重新拉取收藏夹列表与当前收藏夹首屏 */
  private async refreshAll(): Promise<void> {
    try {
      if (JmApi.isLoggedIn()) {
        await this.loadFolders();
      }
    } catch (e) {
      // loadFolders/loadCloudPage 内部已处理错误
    }
    this.cloudRefreshing = false;
  }

  private async loadCloudPage(page: number, replace: boolean): Promise<void> {
    const requestFolder: string = this.currentFolder;
    if (replace) {
      // 有缓存时保留列表展示，只有空列表才显示整页加载圈
      if (this.cloudDataSource.totalCount() === 0) {
        this.cloudLoading = true;
      }
      this.cloudError = '';
    }
    try {
      const result = await JmApi.getFolderComicsPage(requestFolder, page);
      // 请求期间切换了收藏夹：丢弃旧收藏夹的迟到响应，避免串数据/写错缓存
      if (this.currentFolder !== requestFolder) {
        if (replace) {
          this.cloudLoading = false;
        }
        return;
      }
      this.currentPage = page;
      if (replace) {
        // maxPage 仅按首页条数估算：用后续页条数重算会高估总页数，导致请求超范围页并重复加载
        this.maxPage = result.maxPage > 0 ? result.maxPage : page;
        this.cloudLoadedIds = new Set<string>();
        const first: Comic[] = [];
        for (let i = 0; i < result.comics.length; i++) {
          this.cloudLoadedIds.add(result.comics[i].id);
          first.push(result.comics[i]);
        }
        this.cloudDataSource.replaceAll(first);
        ListCache.saveFolderComics(this.cacheUserId(), requestFolder, first, this.maxPage)
          .catch((e: Object) => {
            // 缓存写入失败不影响页面
          });
      } else {
        const fresh: Comic[] = [];
        for (let i = 0; i < result.comics.length; i++) {
          const id: string = result.comics[i].id;
          if (!this.cloudLoadedIds.has(id)) {
            this.cloudLoadedIds.add(id);
            fresh.push(result.comics[i]);
          }
        }
        if (fresh.length > 0) {
          this.cloudDataSource.addAll(fresh);
        }
        if (result.comics.length === 0) {
          // 服务器已无更多数据：收紧 maxPage，终止后续加载
          this.maxPage = page;
        }
      }
    } catch (e) {
      if (this.currentFolder === requestFolder && replace && this.cloudDataSource.totalCount() === 0) {
        this.cloudError = String(e);
      }
    }
    if (replace) {
      this.cloudLoading = false;
    }
  }

  private async loadCloudMore(): Promise<void> {
    if (this.cloudLoadingMore || this.cloudLoading) return;
    if (this.currentPage >= this.maxPage) return;
    this.cloudLoadingMore = true;
    try {
      await this.loadCloudPage(this.currentPage + 1, false);
    } catch (e) {
      // 忽略加载更多错误
    }
    this.cloudLoadingMore = false;
  }

  private async selectFolder(folderId: string): Promise<void> {
    if (this.currentFolder === folderId) {
      return;
    }
    this.currentFolder = folderId;
    // 先展示该收藏夹的本地缓存，再请求最新数据
    await this.restoreCachedPage(folderId);
    this.loadCloudPage(1, true);
  }

  /** 收藏夹下拉数据：第 0 项固定为「全部」，其后为云端收藏夹 */
  private folderOptions(): SelectOption[] {
    const opts: SelectOption[] = [{ value: Translations.t('folder_all') }];
    for (let i = 0; i < this.folders.length; i++) {
      opts.push({ value: this.folders[i].name });
    }
    return opts;
  }

  private folderIndex(): number {
    if (this.currentFolder === '0') {
      return 0;
    }
    for (let i = 0; i < this.folders.length; i++) {
      if (this.folders[i].id === this.currentFolder) {
        return i + 1;
      }
    }
    return 0;
  }

  private currentFolderLabel(): string {
    const idx: number = this.folderIndex();
    if (idx === 0 || idx > this.folders.length) {
      return Translations.t('folder_all');
    }
    return this.folders[idx - 1].name;
  }

  private selectFolderByIndex(index: number): void {
    if (index <= 0) {
      this.selectFolder('0');
      return;
    }
    const folderIdx: number = index - 1;
    if (folderIdx >= 0 && folderIdx < this.folders.length) {
      this.selectFolder(this.folders[folderIdx].id);
    }
  }

  private confirmDeleteCurrentFolder(): void {
    for (let i = 0; i < this.folders.length; i++) {
      if (this.folders[i].id === this.currentFolder) {
        this.confirmDeleteFolder(this.folders[i]);
        return;
      }
    }
  }

  private confirmDeleteFolder(folder: JmFolder): void {
    this.getUIContext().showAlertDialog({
      title: Translations.t('delete_folder'),
      message: `${Translations.t('delete_folder_confirm_prefix')}${folder.name}${Translations.t('delete_folder_confirm_suffix')}`,
      primaryButton: {
        value: Translations.t('cancel'),
        action: () => {
        }
      },
      secondaryButton: {
        value: Translations.t('confirm'),
        fontColor: $r('app.color.danger'),
        action: () => {
          this.deleteFolder(folder);
        }
      }
    });
  }

  private async deleteFolder(folder: JmFolder): Promise<void> {
    try {
      await JmApi.deleteFolder(folder.id);
      ToastUtil.show(Translations.t('folder_deleted'), 1500);
      this.loadFolders();
    } catch (e) {
      ToastUtil.fail(e);
    }
  }

  private async createFolder(): Promise<void> {
    const name: string = this.newFolderName.trim();
    if (name.length === 0) {
      return;
    }
    try {
      await JmApi.createFolder(name);
      this.newFolderName = '';
      this.showNewFolderSheet = false;
      ToastUtil.show(Translations.t('folder_created'), 1500);
      this.loadFolders();
    } catch (e) {
      ToastUtil.fail(e);
    }
  }

  /** 标题栏右侧：收藏夹下拉 + 新建/删除收藏夹 */
  @Builder
  folderMenus() {
    if (this.loggedIn) {
      Row({ space: 4 }) {
        Select(this.folderOptions())
          .selected(this.folderIndex())
          .value(this.currentFolderLabel())
          .font({ size: 14 })
          .fontColor($r('app.color.text_secondary'))
          .selectedOptionFontColor(this.themeColor)
          .optionFontColor($r('app.color.text_primary'))
          .menuBackgroundColor($r('app.color.bg_elevated'))
          .menuAlign(MenuAlignType.END)
          .height(28)
          .constraintSize({ maxWidth: 132 })
          .onSelect((index: number) => {
            this.selectFolderByIndex(index);
          })
          .id('folderSelect')
        SymbolGlyph($r('sys.symbol.folder_badge_plus'))
          .fontSize(22)
          .fontColor([this.themeColor])
          .padding(6)
          .onClick(() => {
            this.newFolderName = '';
            this.showNewFolderSheet = true;
          })
          .id('folderCreate')
        if (this.currentFolder !== '0') {
          SymbolGlyph($r('sys.symbol.trash'))
            .fontSize(20)
            .fontColor([$r('app.color.text_secondary')])
            .padding(6)
            .onClick(() => { this.confirmDeleteCurrentFolder(); })
            .id('folderDelete')
        }
      }
      .height(56)
      .padding({ right: 12 })
      .alignItems(VerticalAlign.Center)
    }
  }

  @Builder
  cloudComicRows() {
    Refresh({ refreshing: $$this.cloudRefreshing, offset: 64, friction: 100 }) {
      List({ space: 1 }) {
      LazyForEach(this.cloudDataSource, (comic: Comic) => {
        ListItem() {
          Row({ space: 12 }) {
            NetworkImage({ url: comic.coverUrl, comicId: comic.id, imgWidth: 80, imgHeight: 110, imgBorderRadius: 6 })
            Column({ space: 6 }) {
              Text(comic.title)
                .fontSize(15).fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
              if (comic.author.length > 0) {
                Text(comic.author)
                  .fontSize(12).fontColor($r('app.color.text_secondary'))
                  .maxLines(1)
              }
            }
            .layoutWeight(1).alignItems(HorizontalAlign.Start)
          }
          .width('100%').padding(12)
          .onClick(() => {
            const param: Record<string, Object> = {
              'comicId': comic.id, 'title': comic.title, 'source': 'jm'
            };
            NavUtil.push('comicDetail', param);
          })
        }
        .id('favComic' + comic.id)
      }, (comic: Comic) => comic.id)

      ListItem() {
        if (this.cloudLoadingMore) {
          Column({ space: 8 }) {
            LoadingProgress().width(32).height(32)
          }
          .width('100%').height(48).justifyContent(FlexAlign.Center)
        } else if (this.currentPage < this.maxPage) {
          Text(Translations.t('load_more'))
            .fontSize(13)
            .fontColor(this.themeColor)
            .width('100%').height(48)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.loadCloudMore(); })
        }
      }
    }
    .layoutWeight(1)
    .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
    .edgeEffect(EdgeEffect.Spring)
    .contentStartOffset(56)
    .contentEndOffset(120)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    .onReachEnd(() => { this.loadCloudMore(); })
    .id('cloudComicRows')
    }
    .layoutWeight(1)
    .onRefreshing(() => { this.refreshAll(); })
  }

  @Builder
  cloudBody() {
    if (!this.loggedIn) {
      Column({ space: 16 }) {
        SymbolGlyph($r('sys.symbol.person'))
          .fontSize(56)
          .fontColor([$r('app.color.text_tertiary')])
        Text(Translations.t('please_login'))
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
        Button(Translations.t('login'))
          .fontSize(14)
          .backgroundColor(this.themeColor)
          .fontColor($r('app.color.text_on_brand'))
          .onClick(() => { NavUtil.push('accounts'); })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .id('cloudBodyLogin')
    } else {
      if (this.cloudLoading) {
        Column() {
          LoadingProgress().width(40).height(40)
        }
        .layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.cloudError.length > 0) {
        Column({ space: 12 }) {
          Text(this.cloudError).fontSize(14).fontColor($r('app.color.danger'))
          Button(Translations.t('retry'))
            .fontSize(14)
            .backgroundColor(this.themeColor)
            .fontColor($r('app.color.text_on_brand'))
            .onClick(() => { this.loadCloudPage(1, true); })
        }
        .layoutWeight(1).justifyContent(FlexAlign.Center)
        .id('cloudBodyError')
      } else if (this.cloudDataSource.totalCount() === 0) {
        Refresh({ refreshing: $$this.cloudRefreshing, offset: 64, friction: 100 }) {
          Scroll() {
            Column({ space: 8 }) {
              Text(Translations.t('no_data'))
                .fontSize(14).fontColor($r('app.color.text_secondary'))
            }
            .width('100%').height('100%')
            .justifyContent(FlexAlign.Center)
          }
          .width('100%').height('100%')
          .edgeEffect(EdgeEffect.Spring)
        }
        .layoutWeight(1)
        .onRefreshing(() => { this.refreshAll(); })
        .id('cloudBodyEmpty')
      } else {
        this.cloudComicRows()
      }
    }
  }

  @Builder
  newFolderSheetContent() {

    Column({ space: 16 }) {
      Text(Translations.t('new_folder'))
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
      TextInput({ placeholder: Translations.t('folder_name_hint'), text: this.newFolderName })
        .width('100%')
        .height(44)
        .fontSize(14)
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_secondary'))
        .caretColor(this.themeColor)
        .backgroundColor($r('app.color.bg_fill'))
        .borderRadius(12)
        .onChange((v: string) => { this.newFolderName = v; })
      Row({ space: 12 }) {
        Button(Translations.t('cancel'))
          .layoutWeight(1)
          .height(42)
          .fontSize(14)
          .backgroundColor($r('app.color.bg_fill'))
          .fontColor($r('app.color.text_primary'))
          .onClick(() => { this.showNewFolderSheet = false; })
        Button(Translations.t('confirm'))
          .layoutWeight(1)
          .height(42)
          .fontSize(14)
          .backgroundColor(this.themeColor)
          .fontColor($r('app.color.text_on_brand'))
          .onClick(() => { this.createFolder(); })
      }
      .width('100%')
    }
    .width('100%')
    .padding(20)
    .id('newFolderSheetContent')

  }

  build() {

    NavDestination() {
      Column({ space: 0 }) {
        this.cloudBody()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.bg_page'))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
      .bindSheet($$this.showNewFolderSheet, this.newFolderSheetContent(), {
        preferType: SheetType.BOTTOM,
        height: SheetSize.MEDIUM,
        dragBar: true,
        onDisappear: () => {
        }
      })
    }
    .title(Translations.t('favorite_title'), {
      barStyle: BarStyle.STACK,
      scrollEffectOptions: {
        scrollEffectType: ScrollEffectType.GRADUAL_BLUR
      },
      systemMaterial: new uiMaterial.ImmersiveMaterial({
        style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
      })
    })
    .menus(this.folderMenus())
    .hideBackButton(true)
    .backgroundColor($r('app.color.bg_page'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])

  }
}
