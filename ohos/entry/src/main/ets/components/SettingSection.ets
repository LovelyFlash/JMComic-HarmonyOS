// components/SettingSection.ets - 设置分区标题

@Component
export struct SettingSection {
  @Prop title: string = ''
  
  

  build() {
    Text(this.title)
      .fontSize(13)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_secondary'))
      .width('100%')
      .padding({ left: 16, top: 24, bottom: 8 })
  }
}
