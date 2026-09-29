// components/SettingSection.ets - 设置分区标题
import { ThemeManager } from '../common/ThemeManager';

@Component
export struct SettingSection {
  @Prop title: string = ''
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @StorageLink('themeVersion') themeVersion: number = 0

  build() {
    Text(this.title)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor(ThemeManager.textSecondary)
      .width('100%')
      .padding({ left: 16, top: 24, bottom: 8 })
  }
}
