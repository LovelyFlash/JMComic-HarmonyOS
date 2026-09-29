// components/SettingItem.ets - 设置项（分组卡片内透明行 + 可选分隔线）
import { ThemeManager } from '../common/ThemeManager';

@Component
export struct SettingItem {
  @Prop icon: Resource = $r('sys.symbol.gearshape')
  @Prop title: string = ''
  @Prop value: string = ''
  @Prop showArrow: boolean = true
  @Prop showDivider: boolean = true
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @StorageLink('themeVersion') themeVersion: number = 0
  onTap: () => void = () => {}

  build() {
    Row({ space: 12 }) {
      SymbolGlyph(this.icon)
        .fontSize(24)
        .fontColor([ThemeManager.primary])
      Text(this.title)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor(ThemeManager.textPrimary)
        .layoutWeight(1)
      if (this.value.length > 0) {
        Text(this.value)
          .fontSize(14)
          .fontColor(ThemeManager.textSecondary)
          .margin({ right: 4 })
      }
      if (this.showArrow) {
        SymbolGlyph($r('sys.symbol.chevron_right'))
          .fontSize(20)
          .fontColor([ThemeManager.textTertiary])
      }
    }
    .width('100%')
    .height(52)
    .padding({ left: 20, right: 20 })
    .border({ width: { bottom: this.showDivider ? 0.5 : 0 }, color: ThemeManager.divider })
    .onClick(() => { this.onTap(); })
  }
}

