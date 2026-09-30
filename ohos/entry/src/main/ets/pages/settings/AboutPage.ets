// pages/settings/AboutPage.ets - 关于页 - NavDestination
import { Translations } from '../../common/Translations';
import { ApiConstants } from '../../common/Constants';
import { NavTitleBar } from '../../components/NavTitleBar';

@Builder
export function AboutPageBuilder(name: string, param: object) {
  AboutPage()
}

@Component
export struct AboutPage {
  
  @StorageProp('themeColor') themeColor: string = '#2563EB'

  build() {
    NavDestination() {
      
        Column({ space: 8 }) {
          NavTitleBar({ title: Translations.t('about') })
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
      
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_page'))
  }
}
