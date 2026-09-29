// pages/settings/AboutPage.ets - 关于页 - NavDestination
import { ThemeManager } from '../../common/ThemeManager';
import { Translations } from '../../common/Translations';
import { ApiConstants } from '../../common/Constants';
import { NavTitleBar } from '../../components/NavTitleBar';

@Builder
export function AboutPageBuilder(name: string, param: object) {
  AboutPage()
}

@Component
export struct AboutPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @StorageLink('themeVersion') themeVersion: number = 0

  build() {
    NavDestination() {
      ForEach([this.themeVersion], (v: number) => {
        Column({ space: 8 }) {
          NavTitleBar({ title: Translations.t('about') })
          Column({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.book'))
              .fontSize(64)
              .fontColor([ThemeManager.primary])
            Text(ApiConstants.APP_NAME)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(ThemeManager.textPrimary)
              .margin({ top: 56 })
            Text('HarmonyOS Version')
              .fontSize(14)
              .fontColor(ThemeManager.textSecondary)
              .margin({ top: 4 })
            Text('v' + ApiConstants.APP_VERSION)
              .fontSize(14)
              .fontColor(ThemeManager.textSecondary)
              .margin({ top: 4 })
            Text(Translations.t('about_desc'))
              .fontSize(13)
              .fontColor(ThemeManager.textSecondary)
              .margin({ top: 56 })
            Text(Translations.t('about_original'))
              .fontSize(13)
              .fontColor(ThemeManager.textSecondary)
              .margin({ top: 8 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%').height('100%')
      }, (v: number) => `theme-${v}`)
    }
    .hideTitleBar(true)
    .backgroundColor(this.themeVersion >= 0 ? ThemeManager.pageBackground : '')
  }
}
