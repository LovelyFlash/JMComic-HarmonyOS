// components/NavTitleBar.ets - Navigation 页面公共标题栏（SymbolGlyph + 主题令牌）
import { ThemeManager } from '../common/ThemeManager';
import { NavUtil } from '../common/NavUtil';

@Builder
export function EmptyBuilder() {
}

@Component
export struct NavTitleBar {
  @Prop title: string = '';
  @Prop showBack: boolean = true;
  @StorageLink('themeVersion') themeVersion: number = 0;
  @StorageLink('isDarkMode') isDarkMode: boolean = false;
  @BuilderParam rightContent: () => void = EmptyBuilder;

  build() {
    Row({ space: 8 }) {
      if (this.showBack) {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(26)
          .fontColor([ThemeManager.textPrimary])
          .onClick(() => { NavUtil.back(); })
      }
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeManager.textPrimary)
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
