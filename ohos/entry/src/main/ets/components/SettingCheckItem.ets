// components/SettingCheckItem.ets - 勾选设置项（标题 + 对勾；根为 ListItem，可直接作 List/ListItemGroup 子组件）
import { DEFAULT_THEME_COLOR } from '../common/Constants';
import { SettingCorner, settingCornerRadius } from './SettingCommon';

@Component
export struct SettingCheckItem {
  @Prop title: string = ''
  @Prop selected: boolean = false
  @Prop interactive: boolean = true
  @Prop corner: SettingCorner = SettingCorner.MIDDLE
  @Prop itemId: string = ''
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR
  onTap: () => void = () => {}

  build() {
    ListItem() {
      Row({ space: 12 }) {
        Text(this.title)
          .fontSize(16)
          .fontColor(this.selected ? this.themeColor : $r('app.color.text_primary'))
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        if (this.selected) {
          SymbolGlyph($r('sys.symbol.checkmark'))
            .fontSize(20)
            .fontColor([this.themeColor])
        }
      }
      .width('100%')
      .height(52)
      .padding({ left: 20, right: 20 })
      .opacity(this.interactive ? 1 : 0.4)
      .onClick(() => { this.onTap(); })
    }
    .backgroundColor($r('app.color.bg_surface'))
    .borderRadius(settingCornerRadius(this.corner))
    .clip(true)
    .id(this.itemId)
  }
}
