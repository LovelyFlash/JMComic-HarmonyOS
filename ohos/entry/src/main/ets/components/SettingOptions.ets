// components/SettingOptions.ets - 设置选项容器按钮（离散选项点选）

@Component
export struct SettingOptions {
  @StorageProp('themeColor') themeColor: string = '#2563EB'
  @Prop label: string = ''
  @Prop options: string[] = []
  @Prop selectedIndex: number = 0
  onSelect: (index: number) => void = () => {}

  build() {
    Column({ space: 10 }) {
      if (this.label.length > 0) {
        Text(this.label)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
      }
      Flex({ wrap: FlexWrap.Wrap, direction: FlexDirection.Row }) {
        ForEach(this.options, (option: string, index: number) => {
          Text(option)
            .fontSize(14)
            .fontColor(this.selectedIndex === index ? $r('app.color.text_on_brand') : $r('app.color.text_primary'))
            .padding({ left: 14, right: 14, top: 8, bottom: 8 })
            .backgroundColor(this.selectedIndex === index ? this.themeColor : Color.Transparent)
            .borderRadius(18)
            .border({ width: 1, color: this.selectedIndex === index ? this.themeColor : $r('app.color.divider') })
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.onSelect(index);
            })
        }, (option: string) => option)
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 6, bottom: 6 })
  }
}
