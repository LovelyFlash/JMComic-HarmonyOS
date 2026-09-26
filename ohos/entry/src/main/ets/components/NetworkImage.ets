// components/NetworkImage.ets - 网络图片组件
import { Logger } from '../common/Logger';

const TAG = 'NetworkImage';

@Component
export struct NetworkImage {
  @Prop url: string = ''
  @Prop imgWidth: number = 120
  @Prop imgHeight: number = 160
  @Prop imgBorderRadius: number = 8
  @Prop fit: ImageFit = ImageFit.Cover
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  build() {
    if (this.url.length > 0) {
      Image(this.url)
        .width(this.imgWidth)
        .height(this.imgHeight)
        .borderRadius(this.imgBorderRadius)
        .objectFit(this.fit)
        .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#F0F0F0')
        .onError(() => {
          Logger.debug(TAG, `Image load failed: ${this.url}`);
        })
    } else {
      Column() {
        Text('No Image')
          .fontSize(12)
          .fontColor(this.isDarkMode ? '#8E8E93' : '#CCCCCC')
      }
      .width(this.imgWidth)
      .height(this.imgHeight)
      .borderRadius(this.imgBorderRadius)
      .backgroundColor(this.isDarkMode ? '#2C2C2E' : '#F0F0F0')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
  }
}
