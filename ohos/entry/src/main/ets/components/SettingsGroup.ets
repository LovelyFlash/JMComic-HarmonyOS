// components/SettingsGroup.ets - 设置分组卡片（鸿蒙分组样式：小标题 + 圆角卡片容器）
import { ThemeManager } from '../common/ThemeManager';

@Component
export struct SettingsGroup {
  @Prop title: string = ''
  @BuilderParam content: () => void
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @StorageLink('themeVersion') themeVersion: number = 0

  build() {
    Column() {
      if (this.title.length > 0) {
        Text(this.title)
          .fontSize(13)
          .fontColor(ThemeManager.textSecondary)
          .padding({ left: 20, top: 24, bottom: 8 })
      }
      Column() {
        this.content()
      }
      .width('100%')
      .backgroundColor(ThemeManager.card)
      .borderRadius(16)
      .clip(true)
    }
    .width('100%')
    .margin({ left: 16, right: 16 })
    .alignItems(HorizontalAlign.Start)
  }
}
