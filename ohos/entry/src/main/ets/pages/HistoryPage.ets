// pages/HistoryPage.ets - 阅读历史
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';
import { HistoryManager } from '../viewmodel/HistoryManager';

@Entry
@Component
struct HistoryPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State historyItems: string[] = []

  build() {
    Column() {
      Row() {
        Text('<').fontSize(20).fontColor(ThemeManager.colors.primary)
          .onClick(() => { router.back(); })
        Text(Translations.t('tab_history')).fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(ThemeManager.colors.textPrimary).margin({ left: 16 })
      }.width('100%').height(56).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      if (this.historyItems.length === 0) {
        Column() {
          Text(Translations.t('no_data')).fontSize(14).fontColor(ThemeManager.colors.textSecondary)
        }.layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.historyItems, (item: string) => {
            ListItem() {
              Text(item).fontSize(14).fontColor(ThemeManager.colors.textPrimary)
                .width('100%').padding(16)
            }
          })
        }.layoutWeight(1)
      }
    }.width('100%').height('100%').backgroundColor(ThemeManager.colors.background)
  }
}
