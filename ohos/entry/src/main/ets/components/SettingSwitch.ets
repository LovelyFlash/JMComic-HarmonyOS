// components/SettingSwitch.ets - 开关设置项（ListItem 内容行：图标 + 标题 + 开关）

@Component
export struct SettingSwitch {
  @Prop icon: Resource = $r('sys.symbol.gearshape')
  @Prop title: string = ''
  @Prop isOn: boolean = false
  @StorageProp('themeColor') themeColor: string = '#2563EB'
  onToggle: (value: boolean) => void = () => {}

  build() {
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
  }
}

