// components/SettingSelect.ets - 下拉设置项（图标 + 标题 + Select 下拉菜单；根为 ListItem，可直接作 List/ListItemGroup 子组件）
import { DEFAULT_THEME_COLOR } from '../common/Constants';
import { SettingCorner, settingCornerRadius } from './SettingCommon';

@Component
export struct SettingSelect {
  @Prop icon: Resource = $r('sys.symbol.gearshape')
  @Prop title: string = ''
  @Prop options: string[] = []
  @Prop selectedIndex: number = 0
  @Prop corner: SettingCorner = SettingCorner.ALL
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR
  onSelect: (index: number) => void = () => {}

  private toSelectOptions(): SelectOption[] {
    const opts: SelectOption[] = [];
    for (let i = 0; i < this.options.length; i++) {
      opts.push({ value: this.options[i] });
    }
    return opts;
  }

  private selectedValue(): string {
    if (this.selectedIndex >= 0 && this.selectedIndex < this.options.length) {
      return this.options[this.selectedIndex];
    }
    return '';
  }

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
        Select(this.toSelectOptions())
          .selected(this.selectedIndex)
          .value(this.selectedValue())
          .font({ size: 14 })
          .fontColor($r('app.color.text_secondary'))
          .selectedOptionFontColor(this.themeColor)
          .optionFontColor($r('app.color.text_primary'))
          .menuBackgroundColor($r('app.color.bg_elevated'))
          .menuAlign(MenuAlignType.END)
          .onSelect((index: number) => {
            this.onSelect(index);
          })
      }
      .width('100%')
      .height(52)
      .padding({ left: 14, right: 14 })
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    }
    .backgroundColor($r('app.color.bg_surface'))
    .borderRadius(settingCornerRadius(this.corner))
    .clip(true)
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
  }
}
