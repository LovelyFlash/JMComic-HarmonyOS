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
        Text('<').fontSize(20).fontColor(ThemeManager.colors.primary)
          .onClick(() => { router.back(); })
        Text(Translations.t('settings_reading'))
          .fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(ThemeManager.colors.textPrimary).margin({ left: 16 })
      }.width('100%').height(56).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      Column() {
        Text(Translations.t('font_size')).fontSize(13)
          .fontColor(ThemeManager.colors.textSecondary).width('100%')
          .padding({ left: 16, top: 56, bottom: 8 })
        Row() {
          ForEach([12, 14, 16, 18, 20, 22], (size: number) => {
            Text(size.toString())
              .fontSize(size)
              .fontColor(size === this.fontSize ? ThemeManager.colors.primary : ThemeManager.colors.textPrimary)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .borderRadius(8)
              .backgroundColor(size === this.fontSize ? '#F0F8FF' : 'transparent')
              .onClick(() => { this.fontSize = size; })
          })
        }.width('100%').padding({ left: 16, right: 16 })

        Text(Translations.t('image_quality')).fontSize(13)
          .fontColor(ThemeManager.colors.textSecondary).width('100%')
          .padding({ left: 16, top: 24, bottom: 8 })
        Row() {
          ForEach(['original', 'high', 'medium'], (quality: string, index: number) => {
            Text(quality)
              .fontSize(14)
              .fontColor(index === this.imageQuality ? ThemeManager.colors.primary : ThemeManager.colors.textPrimary)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .borderRadius(8)
              .backgroundColor(index === this.imageQuality ? '#F0F8FF' : 'transparent')
              .onClick(() => { this.imageQuality = index; })
          })
        }.width('100%').padding({ left: 16, right: 16 })
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ThemeManager.colors.background)
  }
}
