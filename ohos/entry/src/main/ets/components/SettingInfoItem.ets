// components/SettingInfoItem.ets - 信息展示行（标签 + 值；根为 ListItem，可直接作 List/ListItemGroup 子组件）
import { DEFAULT_THEME_COLOR } from '../common/Constants';
import { SettingCorner, settingCornerRadius } from './SettingCommon';

@Component
export struct SettingInfoItem {
  @Prop label: string = ''
  @Prop value: string = ''
  @Prop primary: boolean = false
  @Prop corner: SettingCorner = SettingCorner.MIDDLE
  @Prop itemId: string = ''
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR

  build() {
    ListItem() {
      Row({ space: 12 }) {
        Text(this.label)
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text(this.value)
          .fontSize(14)
          .fontColor(this.primary ? this.themeColor : $r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .constraintSize({ maxWidth: '60%' })
      }
      .width('100%')
      .height(52)
      .padding({ left: 20, right: 20 })
    }
    .backgroundColor($r('app.color.bg_surface'))
    .borderRadius(settingCornerRadius(this.corner))
    .clip(true)
    .id(this.itemId)
  }
}
