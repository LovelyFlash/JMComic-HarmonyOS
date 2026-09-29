// components/SettingOptions.ets - 设置选项容器按钮（离散选项点选）
import { ThemeManager } from '../common/ThemeManager';

@Component
export struct SettingOptions {
  @StorageLink('themeVersion') themeVersion: number = 0
  @Prop label: string = ''
  @Prop options: string[] = []
  @Prop selectedIndex: number = 0
  onSelect: (index: number) => void = () => {}

  build() {
    Column({ space: 10 }) {
      if (this.label.length > 0) {
        Text(this.label)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeManager.textPrimary)
          .width('100%')
      }
      Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row }) {
        ForEach(this.options, (option: string, index: number) => {
          Text(option)
            .fontSize(14)
            .fontColor(this.selectedIndex === index ? '#FFFFFF' : ThemeManager.textPrimary)
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .backgroundColor(this.selectedIndex === index ? ThemeManager.primary : Color.Transparent)
            .borderRadius(18)
            .border({ width: 1, color: this.selectedIndex === index ? ThemeManager.primary : ThemeManager.divider })
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.onSelect(index);
            })
        }, (option: string) => option)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 6, bottom: 6 })
  }
}
