// pages/HistoryPage.ets - 阅读历史（可点击进入详情）- NavDestination
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
  
  @StorageProp('bottomAvoidHeight') bottomAvoid: number = 0
  @StorageProp('themeColor') themeColor: string = '#2563EB'
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
                .fontSize(14).fontColor($r('app.color.text_secondary'))
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
                      .backgroundColor($r('app.color.bg_fill'))
                    Column({ space: 8 }) {
                      Text(item.title)
                        .fontSize(15).fontWeight(FontWeight.Medium)
                        .fontColor($r('app.color.text_primary'))
                        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')
                      if (item.lastChapter.length > 0) {
                        Text(item.lastChapter)
                          .fontSize(12).fontColor($r('app.color.text_secondary'))
                          .margin({ top: 4 })
                      }
                      Text(item.source)
                        .fontSize(11).fontColor(this.themeColor)
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
                .id('historyRow' + item.id + item.source)
              }, (item: HistoryItem) => item.id + item.source)
            }
            .width('100%').layoutWeight(1)
            .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
            .padding({ bottom: this.bottomAvoid })
          }
        }
        .width('100%').height('100%')
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_page'))
  }
}
