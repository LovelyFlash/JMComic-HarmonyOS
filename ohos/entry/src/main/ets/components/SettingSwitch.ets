// components/SettingSwitch.ets - 开关设置项（图标 + 标题 + 开关；根为 ListItem，可直接作 List/ListItemGroup 子组件）
import { DEFAULT_THEME_COLOR } from '../common/Constants';
import { SettingCorner, settingCornerRadius } from './SettingCommon';

@Component
export struct SettingSwitch {
  @Prop icon: Resource = $r('sys.symbol.gearshape')
  @Prop title: string = ''
  @Prop isOn: boolean = false
  @Prop corner: SettingCorner = SettingCorner.ALL
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR
  onToggle: (value: boolean) => void = () => {}

  build() {
    ListItem() {
      Row({ space: 12 }) {
        SymbolGlyph(this.icon)
          .fontSize(24)
          .fontColor([this.themeColor])
        Text(this.title)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.isOn })
          .selectedColor(this.themeColor)
          .switchPointColor($r('app.color.text_on_brand'))
          .onChange((isOn: boolean) => {
            this.onToggle(isOn);
          })
      }
      .width('100%')
      .height(52)
      .padding({ left: 20, right: 20 })
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    }
    .backgroundColor($r('app.color.bg_surface'))
    .borderRadius(settingCornerRadius(this.corner))
    .clip(true)
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
  }
}
