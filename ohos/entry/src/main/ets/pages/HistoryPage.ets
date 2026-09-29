// pages/HistoryPage.ets - 阅读历史（可点击进入详情）- NavDestination
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { Database, HistoryItem } from '../data/database/Database';
import { NavTitleBar } from '../components/NavTitleBar';

@Builder
export function HistoryPageBuilder(name: string, param: object) {
  HistoryPage()
}

@Component
export struct HistoryPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @StorageLink('themeVersion') themeVersion: number = 0
  @State items: HistoryItem[] = []
  @State loading: boolean = true

  aboutToAppear(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    this.loading = true;
    this.items = await Database.queryHistory();
    this.loading = false;
  }

  build() {
    NavDestination() {
      ForEach([this.themeVersion], (v: number) => {
        Column({ space: 0 }) {
          NavTitleBar({ title: Translations.t('tab_history') })
          if (this.loading) {
            Column({ space: 8 }) {
              LoadingProgress().width(48).height(48)
            }
            .width('100%').layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else if (this.items.length === 0) {
            Column({ space: 8 }) {
              Text(Translations.t('no_data'))
                .fontSize(14).fontColor(ThemeManager.textSecondary)
            }
            .width('100%').layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            List({ space: 1 }) {
              ForEach(this.items, (item: HistoryItem) => {
                ListItem() {
                  Row() {
                    Image(item.coverUrl)
                      .width(70).height(100)
                      .objectFit(ImageFit.Cover)
                      .borderRadius(6)
                      .backgroundColor(ThemeManager.surface)
                    Column({ space: 8 }) {
                      Text(item.title)
                        .fontSize(15).fontWeight(FontWeight.Medium)
                        .fontColor(ThemeManager.textPrimary)
                        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')
                      if (item.lastChapter.length > 0) {
                        Text(item.lastChapter)
                          .fontSize(12).fontColor(ThemeManager.textSecondary)
                          .margin({ top: 4 })
                      }
                      Text(item.source)
                        .fontSize(11).fontColor(ThemeManager.primary)
                        .margin({ top: 2 })
                    }
                    .layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 12 })
                  }
                  .width('100%').padding(12)
                  .onClick(() => {
                    const param: Record<string, Object> = {
                      'comicId': item.id, 'title': item.title, 'source': item.source
                    };
                    NavUtil.push('comicDetail', param);
                  })
                }
                .id('history' + item.id + item.source + this.themeVersion)
              }, (item: HistoryItem) => item.id + item.source)
            }
            .width('100%').layoutWeight(1)
            .divider({ strokeWidth: 0.5, color: ThemeManager.divider })
          }
        }
        .width('100%').height('100%')
      }, (v: number) => `theme-${v}`)
    }
    .hideTitleBar(true)
    .backgroundColor(this.themeVersion >= 0 ? ThemeManager.background : '')
  }
}
