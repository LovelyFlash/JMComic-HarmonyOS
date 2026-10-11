// pages/FavoritesContent.ets - 收藏内容组件（禁漫云收藏）
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { ToastUtil } from '../common/ToastUtil';
import { JmApi, JmFolder } from '../data/api/JmApi';
import { Comic } from '../data/model/Comic';
import { ArrayDataSource } from '../common/ArrayDataSource';
import { DEFAULT_THEME_COLOR } from '../common/Constants';

@Component
export struct FavoritesContent {
  // 禁漫云收藏
  @State loggedIn: boolean = false
  @State folders: JmFolder[] = []
  @State currentFolder: string = '0'
  @State cloudDataSource: ArrayDataSource<Comic> = new ArrayDataSource<Comic>()
  @State cloudLoading: boolean = false
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
    this.refreshLoginState();
  }

  private onAccountChanged(): void {
    this.refreshLoginState();
  }

  private refreshLoginState(): void {
    this.loggedIn = JmApi.isLoggedIn();
    if (this.loggedIn) {
      this.loadFolders();
    }
  }

  private async loadFolders(): Promise<void> {
    try {
      this.folders = await JmApi.getFolders();
    } catch (e) {
      this.folders = [];
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
    this.loadCloudPage(1, true);
  }

  private async loadCloudPage(page: number, replace: boolean): Promise<void> {
    if (replace) {
      this.cloudLoading = true;
      this.cloudError = '';
    }
    try {
      const result = await JmApi.getFolderComicsPage(this.currentFolder, page);
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
        this.cloudDataSource = new ArrayDataSource<Comic>(first);
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
      if (replace) {
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

  private selectFolder(folderId: string): void {
    if (this.currentFolder === folderId) {
      return;
    }
    this.currentFolder = folderId;
    this.loadCloudPage(1, true);
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

  @Builder
  folderChips() {
    Scroll() {
      Row({ space: 8 }) {
        Text(Translations.t('folder_all'))
          .fontSize(13)
          .padding({ left: 14, right: 14, top: 7, bottom: 7 })
          .borderRadius(16)
          .fontColor(this.currentFolder === '0' ? $r('app.color.text_on_brand') : $r('app.color.text_secondary'))
          .backgroundColor(this.currentFolder === '0' ? this.themeColor : $r('app.color.bg_fill'))
          .onClick(() => { this.selectFolder('0'); })
        ForEach(this.folders, (folder: JmFolder) => {
          Text(folder.name)
            .fontSize(13)
            .padding({ left: 14, right: 14, top: 7, bottom: 7 })
            .borderRadius(16)
            .fontColor(this.currentFolder === folder.id ? $r('app.color.text_on_brand') : $r('app.color.text_secondary'))
            .backgroundColor(this.currentFolder === folder.id ? this.themeColor : $r('app.color.bg_fill'))
            .onClick(() => { this.selectFolder(folder.id); })
            .gesture(LongPressGesture().onAction(() => { this.confirmDeleteFolder(folder); }))
            .id('folder' + folder.id)
        }, (folder: JmFolder) => folder.id)
        Row({ space: 4 }) {
          SymbolGlyph($r('sys.symbol.folder'))
            .fontSize(14)
            .fontColor([this.themeColor])
          Text(Translations.t('new_folder'))
            .fontSize(13)
            .fontColor(this.themeColor)
        }
        .padding({ left: 14, right: 14, top: 7, bottom: 7 })
        .borderRadius(16)
        .backgroundColor($r('app.color.bg_fill'))
        .onClick(() => {
          this.newFolderName = '';
          this.showNewFolderSheet = true;
        })
      }
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .id('folderChips')
  }

  @Builder
  cloudComicRows() {
    List({ space: 1 }) {
      LazyForEach(this.cloudDataSource, (comic: Comic) => {
        ListItem() {
          Row({ space: 12 }) {
            Image(comic.coverUrl)
              .width(80).height(110)
              .objectFit(ImageFit.Cover)
              .borderRadius(6)
              .backgroundColor($r('app.color.bg_fill'))
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
    .onReachEnd(() => { this.loadCloudMore(); })
    .id('cloudComicRows')
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
      this.folderChips()
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
        Column({ space: 8 }) {
          Text(Translations.t('no_data'))
            .fontSize(14).fontColor($r('app.color.text_secondary'))
        }
        .layoutWeight(1).justifyContent(FlexAlign.Center)
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

    Column({ space: 0 }) {
      this.cloudBody()
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: 76 })
    .backgroundColor($r('app.color.bg_page'))
    .bindSheet($$this.showNewFolderSheet, this.newFolderSheetContent(), {
      height: SheetSize.MEDIUM,
      dragBar: true,
      onDisappear: () => {
      }
    })

  }
}
