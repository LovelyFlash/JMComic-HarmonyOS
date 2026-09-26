// components/LoadingView.ets - 加载动画组件
@ComponentV2
export struct LoadingView {
  @Param message: string = ''

  build() {
    Column({ space: 8 }) {
      LoadingProgress().width(48).height(48).color(this.isDarkMode ? '#4DA6FF' : '#007AFF')
      if (this.message.length > 0) {
        Text(this.message).fontSize(14).fontColor(this.isDarkMode ? '#8E8E93' : '#666666').margin({ top: 12 })
      }
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
  }
}
