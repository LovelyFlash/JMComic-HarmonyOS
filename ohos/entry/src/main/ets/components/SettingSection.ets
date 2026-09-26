// components/SettingSection.ets - 设置分区标题组件
@Component
export struct SettingSection {
  @Prop title: string = ''
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  build() {
    Text(this.title)
      .fontSize(13)
      .fontColor(this.isDarkMode ? '#999999' : '#666666')
      .width('100%')
      .padding({ left: 16, top: 24, bottom: 8 })
  }
}
