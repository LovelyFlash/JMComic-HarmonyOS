// components/SettingSwitch.ets - 开关设置项组件
@Component
export struct SettingSwitch {
  @Prop icon: string = ''
  @Prop title: string = ''
  @Prop isOn: boolean = false
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  onToggle: (value: boolean) => void = () => {}

  build() {
    Row() {
      if (this.icon.length > 0) {
        Text(this.icon).fontSize(20).margin({ right: 12 })
      }
      Text(this.title)
        .fontSize(16)
        .fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF')
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: this.isOn })
        .selectedColor(this.isDarkMode ? '#4DA6FF' : '#007AFF')
        .switchPointColor('#FFFFFF')
        .onChange((isOn: boolean) => {
          this.onToggle(isOn);
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: this.isDarkMode ? this.isDarkMode ? '#333333' : '#E5E5EA' : this.isDarkMode ? '#333333' : '#E5E5EA' })
  }
}
