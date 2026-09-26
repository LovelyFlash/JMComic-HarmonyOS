// pages/DownloadPage.ets - 下载管理
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';

@Entry
@Component
struct DownloadPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  build() {
    Column() {
      Row() {
        Text('<').fontSize(20).fontColor(this.isDarkMode ? '#4DA6FF' : '#007AFF')
          .onClick(() => { router.back(); })
        Text(Translations.t('download')).fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000').margin({ left: 16 })
      }.width('100%').height(56).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      Column() {
        Text(Translations.t('no_data')).fontSize(14).fontColor(this.isDarkMode ? '#999999' : '#666666')
      }.layoutWeight(1).justifyContent(FlexAlign.Center)
    }.width('100%').height('100%').backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
  }
}
