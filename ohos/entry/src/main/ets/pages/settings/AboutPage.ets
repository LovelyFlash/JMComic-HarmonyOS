// pages/settings/AboutPage.ets - 关于页
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../../common/ThemeManager';
import { Translations } from '../../common/Translations';
import { ApiConstants } from '../../common/Constants';

@Entry
@Component
struct AboutPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  build() {
    Column() {
      Row() {
        Text('<').fontSize(20).fontColor(this.isDarkMode ? '#4DA6FF' : this.isDarkMode ? '#4DA6FF' : '#007AFF')
          .onClick(() => { router.back(); })
        Text(Translations.t('about')).fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF').margin({ left: 16 })
      }.width('100%').height(56).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      Column() {
        Text('📚')
          .fontSize(64)
        Text(ApiConstants.APP_NAME)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF')
          .margin({ top: 56 })
        Text('HarmonyOS Version')
          .fontSize(14)
          .fontColor(this.isDarkMode ? '#8E8E93' : '#666666')
          .margin({ top: 4 })
        Text('v' + ApiConstants.APP_VERSION)
          .fontSize(14)
          .fontColor(this.isDarkMode ? '#8E8E93' : '#666666')
          .margin({ top: 4 })
        Text('基于 ArkTS/ArkUI 开发')
          .fontSize(13)
          .fontColor(this.isDarkMode ? '#8E8E93' : '#666666')
          .margin({ top: 56 })
        Text('原项目: ccbkv/PicaComic')
          .fontSize(13)
          .fontColor(this.isDarkMode ? '#8E8E93' : '#666666')
          .margin({ top: 8 })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%').height('100%').backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
  }
}
