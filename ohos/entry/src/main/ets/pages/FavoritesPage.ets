// pages/FavoritesPage.ets - 收藏夹
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';

@Entry
@Component
struct FavoritesPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  build() {
    Column() {
      Row() {
        Text('<').fontSize(20).fontColor(ThemeManager.colors.primary)
          .onClick(() => { router.back(); })
        Text(Translations.t('tab_favorites')).fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(ThemeManager.colors.textPrimary).margin({ left: 16 })
      }.width('100%').height(56).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      Column() {
        Text(Translations.t('no_data')).fontSize(14).fontColor(ThemeManager.colors.textSecondary)
      }.layoutWeight(1).justifyContent(FlexAlign.Center)
    }.width('100%').height('100%').backgroundColor(ThemeManager.colors.background)
  }
}
