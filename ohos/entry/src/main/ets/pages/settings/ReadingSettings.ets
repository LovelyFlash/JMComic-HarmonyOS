// pages/settings/ReadingSettings.ets - 阅读设置
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../../common/ThemeManager';
import { Translations } from '../../common/Translations';

@Entry
@Component
struct ReadingSettings {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State fontSize: number = 16
  @State imageQuality: number = 0

  build() {
    Column() {
      Row() {
        Text('<').fontSize(20).fontColor(this.isDarkMode ? '#4DA6FF' : '#007AFF')
          .onClick(() => { router.back(); })
        Text(Translations.t('settings_reading'))
          .fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000').margin({ left: 16 })
      }.width('100%').height(56).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      Column() {
        Text(Translations.t('font_size')).fontSize(13)
          .fontColor(this.isDarkMode ? '#999999' : '#666666').width('100%')
          .padding({ left: 16, top: 56, bottom: 8 })
        Row() {
          ForEach([12, 14, 16, 18, 20, 22], (size: number) => {
            Text(size.toString())
              .fontSize(size)
              .fontColor(size === this.fontSize ? this.isDarkMode ? '#4DA6FF' : '#007AFF' : this.isDarkMode ? '#FFFFFF' : '#000000')
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .borderRadius(8)
              .backgroundColor(size === this.fontSize ? '#F0F8FF' : 'transparent')
              .onClick(() => { this.fontSize = size; })
          })
        }.width('100%').padding({ left: 16, right: 16 })

        Text(Translations.t('image_quality')).fontSize(13)
          .fontColor(this.isDarkMode ? '#999999' : '#666666').width('100%')
          .padding({ left: 16, top: 24, bottom: 8 })
        Row() {
          ForEach(['original', 'high', 'medium'], (quality: string, index: number) => {
            Text(quality)
              .fontSize(14)
              .fontColor(index === this.imageQuality ? this.isDarkMode ? '#4DA6FF' : '#007AFF' : this.isDarkMode ? '#FFFFFF' : '#000000')
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .borderRadius(8)
              .backgroundColor(index === this.imageQuality ? '#F0F8FF' : 'transparent')
              .onClick(() => { this.imageQuality = index; })
          })
        }.width('100%').padding({ left: 16, right: 16 })
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
  }
}
