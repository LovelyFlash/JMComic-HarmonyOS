// components/SettingItem.ets - 跳转/值设置项（图标 + 标题 + 值 + 箭头；根为 ListItem，可直接作 List/ListItemGroup 子组件）
import { DEFAULT_THEME_COLOR } from '../common/Constants';
import { SettingCorner, settingCornerRadius } from './SettingCommon';

@Component
export struct SettingItem {
  @Prop icon: Resource = $r('sys.symbol.gearshape')
  @Prop title: string = ''
  @Prop value: string = ''
  @Prop showArrow: boolean = true
  @Prop corner: SettingCorner = SettingCorner.ALL
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR
  onTap: () => void = () => {}

  build() {
    ListItem() {
      Row({ space: 8 }) {
        SymbolGlyph(this.icon)
          .fontSize(24)
          .fontColor([this.themeColor])
        Text(this.title)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        if (this.value.length > 0) {
          Text(this.value)
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ right: 4 })
        }
        if (this.showArrow) {
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(20)
            .fontColor([$r('app.color.text_tertiary')])
        }
      }
      .width('100%')
      .height(52)
      .padding({ left: 14, right: 14 })
      .onClick(() => { this.onTap(); })
    }
    .backgroundColor($r('app.color.bg_surface'))
    .borderRadius(settingCornerRadius(this.corner))
    .clip(true)
  }
}
