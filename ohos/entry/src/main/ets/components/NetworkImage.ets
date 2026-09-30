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
  
  

  build() {
    if (this.url.length > 0) {
      Image(this.url)
        .width(this.imgWidth)
        .height(this.imgHeight)
        .borderRadius(this.imgBorderRadius)
        .objectFit(this.fit)
        .backgroundColor($r('app.color.bg_fill'))
        .onError(() => {
          Logger.debug(TAG, `Image load failed: ${this.url}`);
        })
    } else {
      Column({ space: 8 }) {
        Text('No Image')
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
      }
      .width(this.imgWidth)
      .height(this.imgHeight)
      .borderRadius(this.imgBorderRadius)
      .backgroundColor($r('app.color.bg_fill'))
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
  }
}
