// pages/MePage.ets - 我的页（资料卡 + 历史 + 功能入口）
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { JmApi } from '../data/api/JmApi';
import { Database, HistoryItem } from '../data/database/Database';

class EntryItem {
  iconKey: string = '';
  label: string = '';
  route: string = '';
  constructor(iconKey: string, label: string, route: string) {
    this.iconKey = iconKey;
    this.label = label;
    this.route = route;
  }
}
const tabnum:number = 0

@Component
export struct MePage {

  @State historyItems: HistoryItem[] = []
  @State historyCount: number = 0
  @State loggedIn: boolean = false
  @State userName: string = ''
  @StorageProp('jmAccountChanged') @Watch('onAccountChanged') jmAccountChanged: number = 0
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @StorageLink('themeVersion') themeVersion: number = 0

  static tabnum():number {return tabnum}

  aboutToAppear(): void {
    this.loadHistory();
    this.refreshLoginState();
  }

  private onAccountChanged(): void {
    this.refreshLoginState();
  }

  private refreshLoginState(): void {
    this.loggedIn = JmApi.isLoggedIn();
    this.userName = JmApi.getUserName();
  }

  async loadHistory(): Promise<void> {
    this.historyItems = await Database.queryHistory();
    this.historyCount = this.historyItems.length;
  }

  private makeEntries(): EntryItem[] {
    const list: EntryItem[] = [];
    list.push(new EntryItem('download', Translations.t('download'), 'downloads'));
    list.push(new EntryItem('clock', Translations.t('follow'), 'follows'));
    list.push(new EntryItem('person', Translations.t('account'), 'accounts'));
    return list;
  }

  private openEntry(entry: EntryItem): void {
    if (entry.route.length === 0) {
      return;
    }
    NavUtil.push(entry.route);
  }

  @Builder
  iconBuilder(key: string) {
    if (key === 'download') {
      SymbolGlyph($r('sys.symbol.arrow_down_circle')).fontSize(28).fontColor([ThemeManager.primary])
        .id('icon' + this.themeVersion)
    } else if (key === 'clock') {
      SymbolGlyph($r('sys.symbol.clock')).fontSize(28).fontColor([ThemeManager.primary])
        .id('icon' + this.themeVersion)
    } else {
      SymbolGlyph($r('sys.symbol.person')).fontSize(28).fontColor([ThemeManager.primary])
        .id('icon' + this.themeVersion)
    }
  }

  @Builder
  profileHeader() {
    Row({ space: 14 }) {
      Stack() {
        SymbolGlyph($r('sys.symbol.person'))
          .fontSize(28)
          .fontColor(['#FFFFFF'])
      }
      .width(56).height(56)
      .borderRadius(28)
      .backgroundColor(this.loggedIn ? ThemeManager.primary : ThemeManager.textTertiary)
      Column({ space: 4 }) {
        Text(this.loggedIn && this.userName.length > 0 ? this.userName : Translations.t('tap_to_login'))
          .fontSize(17).fontWeight(FontWeight.Bold)
          .fontColor(ThemeManager.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(Translations.t('jm_name'))
          .fontSize(12).fontColor(ThemeManager.textSecondary)
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([ThemeManager.textTertiary])
    }
    .width('100%')
    .padding(16)
    .backgroundColor(ThemeManager.surfaceSecondary)
    .borderRadius(16)
    .onClick(() => {
      NavUtil.push('accounts');
    })
    .id('profile' + this.themeVersion)
  }

  @Builder
  historyCard() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        SymbolGlyph($r('sys.symbol.clock'))
          .fontSize(20)
          .fontColor([ThemeManager.primary])
        Text(Translations.t('tab_history') + ' (' + this.historyCount + ')')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeManager.textPrimary)
          .layoutWeight(1)
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(16)
          .fontColor([ThemeManager.textTertiary])
      }
      .width('100%')
      .onClick(() => { NavUtil.push('history'); })

      if (this.historyItems.length === 0) {
        Text(Translations.t('no_data'))
          .fontSize(13)
          .fontColor(ThemeManager.textSecondary)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding(16)
      } else {
        List({ space: 8 }) {
          ForEach(this.historyItems.slice(0, 10), (item: HistoryItem) => {
            ListItem() {
              Column({ space: 4 }) {
                Image(item.coverUrl)
                  .width(80).height(110)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(6)
                  .backgroundColor(ThemeManager.surface)
                Text(item.title)
                  .fontSize(11)
                  .fontColor(ThemeManager.textPrimary)
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
              .id('historyItem' + item.id + this.themeVersion)
            }
          }, (item: HistoryItem) => item.id)
        }
        .listDirection(Axis.Horizontal)
        .height(140)
        .width('100%')
      }
    }
    .width('100%')
    .padding(14)
    .backgroundColor(ThemeManager.surfaceSecondary)
    .borderRadius(16)
    .id('historyCard' + this.themeVersion)
  }

  build() {
    ForEach([this.themeVersion], (v: number) => {
      Scroll() {
        Column({ space: 12 }) {
          this.profileHeader()
          this.historyCard()

          Grid() {
            ForEach(this.makeEntries(), (entry: EntryItem) => {
              GridItem() {
                Column({ space: 8 }) {
                  this.iconBuilder(entry.iconKey)
                  Text(entry.label)
                    .fontSize(12)
                    .fontColor(ThemeManager.textPrimary)
                    .maxLines(1)
                }
                .width('100%')
                .height(88)
                .justifyContent(FlexAlign.Center)
                .alignItems(HorizontalAlign.Center)
                .backgroundColor(ThemeManager.surfaceSecondary)
                .borderRadius(12)
                .onClick(() => {
                  this.openEntry(entry);
                })
                .id('entry' + entry.label + this.themeVersion)
              }
            }, (entry: EntryItem) => entry.label)
          }
          .columnsTemplate('1fr 1fr 1fr')
          .columnsGap(10)
          .rowsGap(10)
          .width('100%')

          Row({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.gearshape'))
              .fontSize(22)
              .fontColor([ThemeManager.textSecondary])
            Text(Translations.t('tab_settings'))
              .fontSize(15)
              .fontColor(ThemeManager.textPrimary)
              .layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(16)
              .fontColor([ThemeManager.textTertiary])
          }
          .width('100%')
          .height(52)
          .padding({ left: 14, right: 14 })
          .backgroundColor(ThemeManager.surfaceSecondary)
          .borderRadius(12)
          .onClick(() => { NavUtil.push('settings'); })
          .id('settingsEntry' + this.themeVersion)

          Row({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.questionmark_circle'))
              .fontSize(22)
              .fontColor([ThemeManager.textSecondary])
            Text(Translations.t('about'))
              .fontSize(15)
              .fontColor(ThemeManager.textPrimary)
              .layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontSize(16)
              .fontColor([ThemeManager.textTertiary])
          }
          .width('100%')
          .height(52)
          .padding({ left: 14, right: 14 })
          .backgroundColor(ThemeManager.surfaceSecondary)
          .borderRadius(12)
          .onClick(() => { NavUtil.push('about'); })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 96 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ThemeManager.background)
    }, (v: number) => `theme-${v}`)
  }
}
