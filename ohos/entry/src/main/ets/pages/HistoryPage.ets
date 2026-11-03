// pages/HistoryPage.ets - 阅读历史（可点击进入详情）- NavDestination
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { NetworkImage } from '../components/NetworkImage';
import { Database, HistoryItem } from '../data/database/Database';
import { ArrayDataSource } from '../common/ArrayDataSource';
import { DEFAULT_THEME_COLOR } from '../common/Constants';
import { ToastUtil } from '../common/ToastUtil';
import { SymbolGlyphModifier, uiMaterial } from '@kit.ArkUI';

@Builder
export function HistoryPageBuilder(name: string, param: object) {
  HistoryPage()
}

@Component
export struct HistoryPage {
  
  @StorageProp('bottomAvoidHeight') bottomAvoid: number = 0
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR
  @StorageProp('historyChanged') @Watch('onHistoryChanged') historyChanged: number = 0
  /** LazyForEach 数据源固定为同一实例：删除/清空后必须用 replaceAll 通知刷新，
   *  重新赋值 dataSource 不会触发 LazyForEach 更新（历史列表长按删除后残留旧行即此原因）。 */
  private dataSource: ArrayDataSource<HistoryItem> = new ArrayDataSource<HistoryItem>()
  @State itemCount: number = 0
  @State loading: boolean = true

  aboutToAppear(): void {
    this.loadData(true);
  }

  private onHistoryChanged(): void {
    this.loadData(false);
  }

  async loadData(showLoading: boolean = true): Promise<void> {
    if (showLoading) {
      this.loading = true;
    }
    const items: HistoryItem[] = await Database.queryHistory();
    this.dataSource.replaceAll(items);
    this.itemCount = items.length;
    this.loading = false;
  }

  private confirmClearHistory(): void {
    if (this.itemCount === 0) {
      return;
    }
    this.getUIContext().showAlertDialog({
      title: Translations.t('clear_history'),
      message: Translations.t('clear_history_confirm'),
      primaryButton: {
        value: Translations.t('cancel'),
        action: () => {
        }
      },
      secondaryButton: {
        value: Translations.t('confirm'),
        fontColor: $r('app.color.danger'),
        action: () => {
          Database.clearHistory().then(() => {
            ToastUtil.show(Translations.t('deleted'), 1500);
            // 广播之外再直接刷新一次：确保当前页立刻变为空态
            this.loadData(false);
          });
        }
      }
    });
  }

  private confirmDeleteHistory(item: HistoryItem): void {
    this.getUIContext().showAlertDialog({
      title: Translations.t('delete'),
      message: `${Translations.t('history_delete_confirm_prefix')}${item.title}` +
        `${Translations.t('history_delete_confirm_suffix')}`,
      primaryButton: {
        value: Translations.t('cancel'),
        action: () => {
        }
      },
      secondaryButton: {
        value: Translations.t('delete'),
        fontColor: $r('app.color.danger'),
        action: () => {
          Database.removeHistory(item.id, item.source).then(() => {
            ToastUtil.show(Translations.t('deleted'), 1500);
            // 广播之外再直接刷新一次：不依赖 @Watch 时序，删除后当前列表立即移除该行
            this.loadData(false);
          });
        }
      }
    });
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
          } else if (this.itemCount === 0) {
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
                  .gesture(LongPressGesture().onAction(() => {
                    this.confirmDeleteHistory(item);
                  }))
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
    .menus([
      {
        value: Translations.t('clear_history'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.trash')),
        action: () => { this.confirmClearHistory(); }
      }
    ])
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .hideTitleBar(false)
    .backgroundColor($r('app.color.bg_page'))
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    }))
  }
}
