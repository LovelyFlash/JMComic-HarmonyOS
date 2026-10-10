// pages/settings/AboutPage.ets - 关于页 - NavDestination
import { Translations } from '../../common/Translations';
import { ApiConstants, DEFAULT_THEME_COLOR } from '../../common/Constants';
import { Changelog, ReleaseNote } from '../../common/Changelog';
import { uiMaterial } from '@kit.ArkUI';

@Builder
export function AboutPageBuilder(name: string, param: object) {
  AboutPage()
}

@Component
export struct AboutPage {
  @State title: string = Translations.t('about')
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR

  build() {
    NavDestination() {
      Column() {
        Scroll() {
          Column() {
            Column({ space: 8 }) {
              SymbolGlyph($r('sys.symbol.book'))
                .fontSize(64)
                .fontColor([this.themeColor])
              .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
              Text(ApiConstants.APP_NAME)
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .margin({ top: 48 })
              .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
              Text('HarmonyOS Version')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
              .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
              Text('v' + ApiConstants.APP_VERSION)
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
              .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
              Text(Translations.t('about_desc'))
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 24 })
              .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
              Text(Translations.t('about_original'))
                .fontSize(13)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
              .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
            }
            .alignItems(HorizontalAlign.Center)
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])

            Column({ space: 16 }) {
              Text(Translations.t('changelog'))
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.text_primary'))
                .width('100%')
                .margin({ top: 48 })
              .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])

              ForEach(Changelog.releases, (rel: ReleaseNote) => {
                Column({ space: 6 }) {
                  Row() {
                    Text('v' + rel.version)
                      .fontSize(15)
                      .fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.text_primary'))
                    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
                    Text(rel.date)
                      .fontSize(12)
                      .fontColor($r('app.color.text_secondary'))
                      .margin({ left: 8 })
                    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
                  }
                  .width('100%')

                  ForEach(rel.items, (item: string) => {
                    Text('· ' + item)
                      .fontSize(13)
                      .lineHeight(20)
                      .fontColor($r('app.color.text_secondary'))
                      .width('100%')
                    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
                  }, (item: string, index: number) => rel.version + '_' + index)
                }
                .width('100%')
                .padding({ top: 12, bottom: 12 })
              }, (rel: ReleaseNote) => rel.version)
            }
            .width('100%')
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
            .alignItems(HorizontalAlign.Start)
            .padding({ left: 24, right: 24, bottom: 48 })
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
        }
        .contentStartOffset(56)
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .width('100%').height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    }
    .backgroundColor($r('app.color.bg_page'))
    .title(this.title, {
      barStyle: BarStyle.STACK,
      scrollEffectOptions: {
        scrollEffectType: ScrollEffectType.GRADUAL_BLUR }
    })   // 标题文本 + 返回按钮
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .hideTitleBar(false)
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    }))
    .id('aboutPage')
  }
}

