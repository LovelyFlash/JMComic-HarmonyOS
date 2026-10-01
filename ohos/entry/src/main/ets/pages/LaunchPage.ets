// pages/LaunchPage.ets - 启动页（init 完成后首帧承载窗口配置，首 Tab 数据就绪且最短展示达标后由 EntryAbility 切换主页）
import { ApiConstants, DEFAULT_THEME_COLOR } from '../common/Constants';

@Entry
@Component
struct LaunchPage {
  @StorageProp('topAvoidHeight') topAvoid: number = 0;
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR;

  build() {
    Column({ space: 18 }) {
      Image($r('app.media.app_icon'))
        .width(88)
        .height(88)
        .borderRadius(20)
      Text(ApiConstants.APP_NAME)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      LoadingProgress()
        .width(32)
        .height(32)
        .color(this.themeColor)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.bg_page'))
    .padding({ top: this.topAvoid })
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
  }
}
