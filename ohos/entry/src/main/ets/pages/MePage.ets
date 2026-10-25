// pages/MePage.ets - 我的页（资料卡 + 历史卡片 + 下载卡片）
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { NetworkImage } from '../components/NetworkImage';
import { DEFAULT_THEME_COLOR, SettingsKeys } from '../common/Constants';
import { Settings } from '../data/preferences/Settings';
import { JmApi } from '../data/api/JmApi';
import { Database, DownloadItem, HistoryItem } from '../data/database/Database';
import { DownloadManager } from '../data/download/DownloadManager';

@Component
export struct MePage {

  @State historyItems: HistoryItem[] = []
  @State historyCount: number = 0
  @State downloadItems: DownloadItem[] = []
  @State downloadCount: number = 0
  @State loggedIn: boolean = false
  @State userName: string = ''
  @State accountName: string = ''
  @StorageProp('jmAccountChanged') @Watch('onAccountChanged') jmAccountChanged: number = 0
  @StorageProp('historyChanged') @Watch('onHistoryChanged') historyChanged: number = 0
  @StorageProp('showHistoryImages') showHistoryImages: boolean = true
  @StorageProp('showDownloadImages') showDownloadImages: boolean = true
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR
  private dlReloadTimer: number = -1
  private downloadsListener: () => void = (): void => {
    this.scheduleDownloadsReload();
  }

  aboutToAppear(): void {
    this.loadHistory();
    this.loadDownloads();
    this.refreshLoginState();
    // 首页历史/下载图片显示开关（持久化 -> AppStorage，设置页/本页实时联动）
    Settings.getBool(SettingsKeys.SHOW_HISTORY_IMAGES, true).then((v: boolean) => {
      AppStorage.setOrCreate('showHistoryImages', v);
    });
    Settings.getBool(SettingsKeys.SHOW_DOWNLOAD_IMAGES, true).then((v: boolean) => {
      AppStorage.setOrCreate('showDownloadImages', v);
    });
    DownloadManager.subscribe(this.downloadsListener);
  }

  aboutToDisappear(): void {
    DownloadManager.unsubscribe(this.downloadsListener);
    if (this.dlReloadTimer >= 0) {
      clearTimeout(this.dlReloadTimer);
      this.dlReloadTimer = -1;
    }
  }

  /** 下载进度回调防抖重载（400ms），避免逐页进度触发整树重绘 */
  private scheduleDownloadsReload(): void {
    if (this.dlReloadTimer >= 0) {
      clearTimeout(this.dlReloadTimer);
    }
    this.dlReloadTimer = setTimeout(() => {
      this.dlReloadTimer = -1;
      this.loadDownloads();
    }, 400);
  }

  private onAccountChanged(): void {
    this.refreshLoginState();
  }

  /** 历史写入广播（详情/阅读页）→ 首页卡片即时重查，无需重启 */
  private onHistoryChanged(): void {
    this.loadHistory();
  }

  private refreshLoginState(): void {
    this.loggedIn = JmApi.isLoggedIn();
    this.userName = JmApi.getUserName();
    this.accountName = JmApi.getAccount();
  }

  /** 已登录时必须显示用户标识（用户名缺失回退账号名），避免误显示"点击登录" */
  private displayName(): string {
    if (!this.loggedIn) {
      return Translations.t('tap_to_login');
    }
    if (this.userName.length > 0) {
      return this.userName;
    }
    return this.accountName.length > 0 ? this.accountName : Translations.t('jm_name');
  }

  async loadHistory(): Promise<void> {
    this.historyItems = await Database.queryHistory();
    this.historyCount = this.historyItems.length;
  }

  async loadDownloads(): Promise<void> {
    const items: DownloadItem[] = await Database.queryDownloads();
    this.downloadItems = items;
    this.downloadCount = items.length;
  }

  @Builder
  searchEntry() {
    Row({ space: 8 }) {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(20)
        .fontColor([$r('app.color.text_secondary')])
      Text(Translations.t('search_hint'))
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
        .maxLines(1)
    }
    .width('100%')
    .height(44)
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.bg_fill'))
    .borderRadius(22)
    .onClick(() => { NavUtil.push('preSearch'); })
    .id('searchEntry')
  }

  @Builder
  profileHeader() {
    Row({ space: 14 }) {
      Stack() {
        SymbolGlyph($r('sys.symbol.person'))
          .fontSize(28)
          .fontColor([$r('app.color.text_on_brand')])
      }
      .width(56).height(56)
      .borderRadius(28)
      .backgroundColor(this.loggedIn ? this.themeColor : $r('app.color.text_tertiary'))
      Column({ space: 4 }) {
        Text(this.displayName())
          .fontSize(17).fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(Translations.t('jm_name'))
          .fontSize(12).fontColor($r('app.color.text_secondary'))
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([$r('app.color.text_tertiary')])
    }
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .onClick(() => {
      NavUtil.push('accounts');
    })
    .id('profile')
  }

  @Builder
  historyCard() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.clock'))
          .fontSize(20)
          .fontColor([this.themeColor])
        Text(Translations.t('tab_history') + ' (' + this.historyCount + ')')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(16)
          .fontColor([$r('app.color.text_tertiary')])
      }
      .width('100%')
      .onClick(() => { NavUtil.push('history'); })

      if (this.historyItems.length === 0) {
        Text(Translations.t('no_data'))
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding(16)
      } else if (this.showHistoryImages) {
        List({ space: 8 }) {
          ForEach(this.historyItems.slice(0, 10), (item: HistoryItem) => {
            ListItem() {
              Column({ space: 4 }) {
                NetworkImage({ url: item.coverUrl, comicId: item.id, imgWidth: 80, imgHeight: 110, imgBorderRadius: 6 })
                Text(item.title)
                  .fontSize(11)
                  .fontColor($r('app.color.text_primary'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width(80)
              }
              .onClick(() => {
                const param: Record<string, Object> = {
                  'comicId': item.id, 'title': item.title, 'source': item.source
                };
                NavUtil.push('comicDetail', param);
              })
              .id('historyItem' + item.id)
            }
          }, (item: HistoryItem) => item.id)
        }
        .listDirection(Axis.Horizontal)
        .height(140)
        .width('100%')
      } else {
        List({ space: 8 }) {
          ForEach(this.historyItems.slice(0, 10), (item: HistoryItem) => {
            ListItem() {
              Text(item.title)
                .fontSize(13)
                .fontColor($r('app.color.text_primary'))
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: 160 })
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .backgroundColor($r('app.color.bg_fill'))
                .borderRadius(8)
                .onClick(() => {
                  const param: Record<string, Object> = {
                    'comicId': item.id, 'title': item.title, 'source': item.source
                  };
                  NavUtil.push('comicDetail', param);
                })
            }
            .id('historyChip' + item.id)
          }, (item: HistoryItem) => item.id)
        }
        .listDirection(Axis.Horizontal)
        .height(56)
        .width('100%')
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.bg_surface'))
    .borderRadius(16)
    .id('historyCard')
  }

  /** 下载卡片（与历史卡片同款样式：计数头 + 横滑封面/文本，图片显示受设置开关控制） */
  @Builder
  downloadCard() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.arrow_down_circle'))
          .fontSize(20)
          .fontColor([this.themeColor])
        Text(Translations.t('download') + ' (' + this.downloadCount + ')')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(16)
          .fontColor([$r('app.color.text_tertiary')])
      }
      .width('100%')
      .onClick(() => { NavUtil.push('downloads'); })

      if (this.downloadItems.length === 0) {
        Text(Translations.t('no_downloads'))
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding(16)
      } else if (this.showDownloadImages) {
        List({ space: 8 }) {
          ForEach(this.downloadItems.slice(0, 10), (item: DownloadItem) => {
            ListItem() {
              Column({ space: 4 }) {
                NetworkImage({ url: item.coverUrl, comicId: item.id, imgWidth: 80, imgHeight: 110, imgBorderRadius: 6 })
                Text(item.title)
                  .fontSize(11)
                  .fontColor($r('app.color.text_primary'))
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width(80)
              }
              .onClick(() => {
                const param: Record<string, Object> = {
                  'comicId': item.id, 'title': item.title, 'source': item.source
                };
                NavUtil.push('comicDetail', param);
              })
              .id('downloadItem' + item.id)
            }
          }, (item: DownloadItem) => item.id + item.source)
        }
        .listDirection(Axis.Horizontal)
        .height(140)
        .width('100%')
      } else {
        List({ space: 8 }) {
          ForEach(this.downloadItems.slice(0, 10), (item: DownloadItem) => {
            ListItem() {
              Text(item.title)
                .fontSize(13)
                .fontColor($r('app.color.text_primary'))
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .constraintSize({ maxWidth: 160 })
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .backgroundColor($r('app.color.bg_fill'))
                .borderRadius(8)
                .onClick(() => {
                  const param: Record<string, Object> = {
                    'comicId': item.id, 'title': item.title, 'source': item.source
                  };
                  NavUtil.push('comicDetail', param);
                })
            }
            .id('downloadChip' + item.id)
          }, (item: DownloadItem) => item.id + item.source)
        }
        .listDirection(Axis.Horizontal)
        .height(56)
        .width('100%')
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor($r('app.color.bg_surface'))
    .borderRadius(16)
    .id('downloadCard')
  }

  build() {
    
      Scroll() {
        Column({ space: 12 }) {
          this.searchEntry()
          this.profileHeader()
          this.historyCard()
          this.downloadCard()

          Row({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.gearshape'))
              .fontSize(22)
              .fontColor([$r('app.color.text_secondary')])
            Text(Translations.t('tab_settings'))
              .fontSize(15)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(16)
              .fontColor([$r('app.color.text_tertiary')])
          }
          .width('100%')
          .height(52)
          .padding({ left: 14, right: 14 })
          .borderRadius(12)
          .onClick(() => { NavUtil.push('settings'); })
          .id('settingsEntry')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 96 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.bg_page'))
    
  }
}
