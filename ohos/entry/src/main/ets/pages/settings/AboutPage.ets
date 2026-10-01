// pages/settings/AboutPage.ets - 关于页 - NavDestination
import { Translations } from '../../common/Translations';
import { ApiConstants, DEFAULT_THEME_COLOR } from '../../common/Constants';
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
      
        Column({ space: 8 }) {
          Column({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.book'))
              .fontSize(64)
              .fontColor([this.themeColor])
            Text(ApiConstants.APP_NAME)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .margin({ top: 56 })
            Text('HarmonyOS Version')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 4 })
            Text('v' + ApiConstants.APP_VERSION)
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 4 })
            Text(Translations.t('about_desc'))
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 56 })
            Text(Translations.t('about_original'))
              .fontSize(13)
              .fontColor($r('app.color.text_secondary'))
              .margin({ top: 8 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%').height('100%')
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      
    }
    .backgroundColor($r('app.color.bg_page'))
    .title(this.title, { backgroundColor: $r('app.color.bg_page') })   // 标题文本 + 返回按钮
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .hideTitleBar(false)
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    }))
    .id('aboutPage')
  }
}
