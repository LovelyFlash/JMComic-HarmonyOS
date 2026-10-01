// components/LoadingView.ets - 加载动画组件
import { DEFAULT_THEME_COLOR } from '../common/Constants';

@Component
export struct LoadingView {
  @Prop message: string = ''
  
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR

  build() {
    Column({ space: 8 }) {
      LoadingProgress().width(48).height(48).color(this.themeColor)
      if (this.message.length > 0) {
        Text(this.message).fontSize(14).fontColor($r('app.color.text_secondary')).margin({ top: 12 })
      }
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center)
  }
}
