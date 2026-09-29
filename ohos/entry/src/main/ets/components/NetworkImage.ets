// components/NetworkImage.ets - 网络图片组件
import { Logger } from '../common/Logger';
import { ThemeManager } from '../common/ThemeManager';

const TAG = 'NetworkImage';

@Component
export struct NetworkImage {
  @Prop url: string = ''
  @Prop imgWidth: number = 120
  @Prop imgHeight: number = 160
  @Prop imgBorderRadius: number = 8
  @Prop fit: ImageFit = ImageFit.Cover
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @StorageLink('themeVersion') themeVersion: number = 0

  build() {
    if (this.url.length > 0) {
      Image(this.url)
        .width(this.imgWidth)
        .height(this.imgHeight)
        .borderRadius(this.imgBorderRadius)
        .objectFit(this.fit)
        .backgroundColor(ThemeManager.surface)
        .onError(() => {
          Logger.debug(TAG, `Image load failed: ${this.url}`);
        })
    } else {
      Column({ space: 8 }) {
        Text('No Image')
          .fontSize(12)
          .fontColor(ThemeManager.textSecondary)
      }
      .width(this.imgWidth)
      .height(this.imgHeight)
      .borderRadius(this.imgBorderRadius)
      .backgroundColor(ThemeManager.surface)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
  }
}
