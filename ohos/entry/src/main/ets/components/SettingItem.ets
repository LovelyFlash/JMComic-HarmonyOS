// components/SettingItem.ets - 设置项（分组卡片内透明行 + 可选分隔线）

@Component
export struct SettingItem {
  @Prop icon: Resource = $r('sys.symbol.gearshape')
  @Prop title: string = ''
  @Prop value: string = ''
  @Prop showArrow: boolean = true
  @Prop showDivider: boolean = true
  
  @StorageProp('themeColor') themeColor: string = '#2563EB'
  onTap: () => void = () => {}

  build() {
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
}

