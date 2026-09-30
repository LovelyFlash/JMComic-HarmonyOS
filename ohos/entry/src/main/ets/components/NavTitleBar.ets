// components/NavTitleBar.ets - Navigation 页面公共标题栏（SymbolGlyph + 主题令牌）
import { NavUtil } from '../common/NavUtil';

@Builder
export function EmptyBuilder() {
}

@Component
export struct NavTitleBar {
  @Prop title: string = '';
  @Prop showBack: boolean = true;
  
  
  @BuilderParam rightContent: () => void = EmptyBuilder;

  build() {
    Row({ space: 8 }) {
      if (this.showBack) {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(26)
          .fontColor([$r('app.color.text_primary')])
          .onClick(() => { NavUtil.back(); })
      }
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      this.rightContent()
    }
    .width('100%')
    .height(48)
    .padding({ left: 8, right: 12 })
    .alignItems(VerticalAlign.Center)
  }
}
