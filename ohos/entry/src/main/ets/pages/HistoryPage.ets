// pages/HistoryPage.ets - 阅读历史（可点击进入详情）- NavDestination
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { NetworkImage } from '../components/NetworkImage';
import { Database, HistoryItem } from '../data/database/Database';
import { ArrayDataSource } from '../common/ArrayDataSource';
import { DEFAULT_THEME_COLOR } from '../common/Constants';
import { uiMaterial } from '@kit.ArkUI';

@Builder
export function HistoryPageBuilder(name: string, param: object) {
  HistoryPage()
}

@Component
export struct HistoryPage {
  
  @StorageProp('bottomAvoidHeight') bottomAvoid: number = 0
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR
  @StorageProp('historyChanged') @Watch('onHistoryChanged') historyChanged: number = 0
  @State dataSource: ArrayDataSource<HistoryItem> = new ArrayDataSource<HistoryItem>()
  @State loading: boolean = true

  aboutToAppear(): void {
    this.loadData();
  }

  private onHistoryChanged(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    this.loading = true;
    this.dataSource = new ArrayDataSource<HistoryItem>(await Database.queryHistory());
    this.loading = false;
  }

  build() {
    NavDestination() {
      
        Column({ space: 0 }) {
          if (this.loading) {
            Column({ space: 8 }) {
              LoadingProgress().width(48).height(48)
            }
            .width('100%').layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else if (this.dataSource.totalCount() === 0) {
            Column({ space: 8 }) {
              Text(Translations.t('no_data'))
                .fontSize(14).fontColor($r('app.color.text_secondary'))
            }
            .width('100%').layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else {
            List({ space: 1 }) {
              LazyForEach(this.dataSource, (item: HistoryItem) => {
                ListItem() {
                  Row() {
                    NetworkImage({ url: item.coverUrl, comicId: item.id, imgWidth: 70, imgHeight: 100, imgBorderRadius: 6 })
                    Column({ space: 8 }) {
                      Text(item.title)
                        .fontSize(15).fontWeight(FontWeight.Medium)
                        .fontColor($r('app.color.text_primary'))
                        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')
                      if (item.author.length > 0) {
                        Text(Translations.t('author') + ': ' + item.author)
                          .fontSize(12).fontColor($r('app.color.text_secondary'))
                          .margin({ top: 4 })
                          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                          .width('100%')
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
            .scrollBar(BarState.Off)
            .edgeEffect(EdgeEffect.Spring)
            .contentStartOffset(56)
            .width('100%')
            .height('100%')
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
            .padding({ left: 16, right: 16})
            .systemMaterial(new uiMaterial.ImmersiveMaterial({
              style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
            }))
          }
        }
        .width('100%').height('100%')
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .title(Translations.t('tab_history'),{
      barStyle: BarStyle.STACK,
      scrollEffectOptions: {
        scrollEffectType: ScrollEffectType.GRADUAL_BLUR }
    })
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .hideTitleBar(false)
    .backgroundColor($r('app.color.bg_page'))
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    }))
  }
}
