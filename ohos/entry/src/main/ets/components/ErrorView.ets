// components/ErrorView.ets - 错误提示组件
@ComponentV2
export struct ErrorView {
  @Param message: string = '加载失败'
  @Event onRetry: () => void = () => {}

  build() {
    Column({ space: 8 }) {
      Text('!').fontSize(48).fontColor('#FF3B30').fontWeight(FontWeight.Bold)
      Text(this.message).fontSize(14).fontColor(this.isDarkMode ? '#999999' : '#999999').margin({ top: 12 }).textAlign(TextAlign.Center)
      Button('重试').fontSize(14).fontColor('#FFFFFF').backgroundColor(this.isDarkMode ? '#4DA6FF' : '#007AFF')
        .borderRadius(8).margin({ top: 16 }).height(36).padding({ left: 24, right: 24 })
        .onClick(() => { this.onRetry(); })
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }
}
