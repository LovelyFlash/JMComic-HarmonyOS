// pages/FollowPage.ets - 追更页面 - NavDestination
import { promptAction } from '@kit.ArkUI';
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { Database, FollowItem } from '../data/database/Database';
import { ArrayDataSource } from '../common/ArrayDataSource';
import { DEFAULT_THEME_COLOR } from '../common/Constants';
import { uiMaterial } from '@kit.ArkUI';

@Builder
export function FollowPageBuilder(name: string, param: object) {
  FollowPage()
}

@Component
export struct FollowPage {
  @State dataSource: ArrayDataSource<FollowItem> = new ArrayDataSource<FollowItem>()
  @State loading: boolean = true
  @StorageProp('bottomAvoidHeight') bottomAvoid: number = 0
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR

  aboutToAppear(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    this.loading = true;
    this.dataSource = new ArrayDataSource<FollowItem>(await Database.queryFollows());
    this.loading = false;
  }

  removeFollow(item: FollowItem): void {
    this.getUIContext().showAlertDialog({
      title: Translations.t('unfollow'),
      message: `${Translations.t('unfollow_confirm_prefix')}${item.title}${Translations.t('unfollow_confirm_suffix')}`,
      primaryButton: {
        value: Translations.t('cancel'),
        action: () => {
        }
      },
      secondaryButton: {
        value: Translations.t('confirm'),
        fontColor: $r('app.color.danger'),
        action: () => {
          Database.removeFollow(item.id, item.source).then(() => {
            promptAction.showToast({ message: Translations.t('follow_removed'), duration: 1500 });
            this.loadData();
          });
        }
      }
    });
  }

  build() {
    NavDestination() {
      Column({ space: 0 }) {
        if (this.loading) {
          Column() {
            LoadingProgress().width(40).height(40)
          }
          .width('100%').layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.dataSource.totalCount() === 0) {
          Column({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.clock'))
              .fontSize(44)
              .fontColor([$r('app.color.text_tertiary')])
            Text(Translations.t('no_follows'))
              .fontSize(14).fontColor($r('app.color.text_secondary'))
            Text(Translations.t('follow_hint'))
              .fontSize(12).fontColor($r('app.color.text_tertiary'))
          }
          .width('100%').layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          List({ space: 1 }) {
            LazyForEach(this.dataSource, (item: FollowItem) => {
              ListItem() {
                Row({ space: 12 }) {
                  Image(item.coverUrl)
                    .width(64).height(88).objectFit(ImageFit.Cover)
                    .borderRadius(6)
                    .backgroundColor($r('app.color.bg_fill'))
                  Column({ space: 6 }) {
                    Row({ space: 6 }) {
                      Text(item.title)
                        .fontSize(15).fontWeight(FontWeight.Medium)
                        .fontColor($r('app.color.text_primary'))
                        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                        .layoutWeight(1)
                      if (item.hasUpdate) {
                        Text(Translations.t('has_update'))
                          .fontSize(11)
                          .fontColor($r('app.color.text_on_brand'))
                          .backgroundColor($r('app.color.danger'))
                          .borderRadius(8)
                          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                      }
                    }
                    Text(item.source)
                      .fontSize(12).fontColor(this.themeColor)
                  }
                  .layoutWeight(1).alignItems(HorizontalAlign.Start)
                  SymbolGlyph($r('sys.symbol.xmark'))
                    .fontSize(18)
                    .fontColor([$r('app.color.text_tertiary')])
                    .onClick(() => {
                      this.removeFollow(item);
                    })
                }
                .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 })
                .onClick(() => {
                  const param: Record<string, Object> = {
                    'comicId': item.id, 'title': item.title, 'source': item.source
                  };
                  NavUtil.push('comicDetail', param);
                })
              }
              .id('follow' + item.id + item.source)
            }, (item: FollowItem) => item.id + item.source)
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
    .title(Translations.t('follow'), { backgroundColor: $r('app.color.bg_page') })
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .hideTitleBar(false)
    .backgroundColor($r('app.color.bg_page'))
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    }))
  }
}
