// components/LoadingView.ets - 加载动画组件
@ComponentV2
export struct LoadingView {
  @Param message: string = ''

  build() {
    Column() {
      LoadingProgress().width(48).height(48).color('#007AFF')
      if (this.message.length > 0) {
        Text(this.message).fontSize(14).fontColor('#999999').margin({ top: 12 })
      }
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
  }
}
