// components/SettingItem.ets - 通用设置项组件
@Component
export struct SettingItem {
  @Prop icon: string = ''
  @Prop title: string = ''
  @Prop value: string = ''
  @Prop showArrow: boolean = true
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  onTap: () => void = () => {}

  build() {
    Row() {
      if (this.icon.length > 0) {
        Text(this.icon).fontSize(20).margin({ right: 12 })
      }
      Text(this.title)
        .fontSize(16)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000')
        .layoutWeight(1)
      if (this.value.length > 0) {
        Text(this.value)
          .fontSize(14)
          .fontColor(this.isDarkMode ? '#999999' : '#666666')
          .margin({ right: 4 })
      }
      if (this.showArrow) {
        Image($rawfile('icons/ic_arrow_right.svg'))
          .width(16).height(16).objectFit(ImageFit.Contain)
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: this.isDarkMode ? '#333333' : '#E5E5EA' })
    .onClick(() => { this.onTap(); })
  }
}
