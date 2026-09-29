// components/SettingSwitch.ets - 开关设置项（分组卡片内透明行 + 可选分隔线）
import { ThemeManager } from '../common/ThemeManager';

@Component
export struct SettingSwitch {
  @Prop icon: Resource = $r('sys.symbol.gearshape')
  @Prop title: string = ''
  @Prop isOn: boolean = false
  @Prop showDivider: boolean = true
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @StorageLink('themeVersion') themeVersion: number = 0
  onToggle: (value: boolean) => void = () => {}

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
      Toggle({ type: ToggleType.Switch, isOn: this.isOn })
        .selectedColor(ThemeManager.primary)
        .switchPointColor('#FFFFFF')
        .onChange((isOn: boolean) => {
          this.onToggle(isOn);
        })
    }
    .width('100%')
    .height(52)
    .padding({ left: 20, right: 20 })
    .border({ width: { bottom: this.showDivider ? 0.5 : 0 }, color: ThemeManager.divider })
  }
}

