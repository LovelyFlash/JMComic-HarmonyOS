// components/NetworkImage.ets - 网络图片组件（内存像素→磁盘缓存→网络写穿；GIF 走系统路径直显）
import { image } from '@kit.ImageKit';
import { ImageCache } from '../data/cache/ImageCache';
import { JmImage } from '../common/JmImage';
import { Logger } from '../common/Logger';

const TAG = 'NetworkImage';

@Component
export struct NetworkImage {
  @Prop @Watch('onUrlChange') url: string = ''
  /** 所属漫画 id（缓存归因 + 阅读中 pin 保护；可空） */
  @Prop comicId: string = ''
  @Prop imgWidth: number = 120
  @Prop imgHeight: number = 160
  @Prop imgBorderRadius: number = 8
  @Prop fit: ImageFit = ImageFit.Cover
  @State pm: image.PixelMap | undefined = undefined
  @State failed: boolean = false

  aboutToAppear(): void {
    this.load();
  }

  private onUrlChange(): void {
    this.pm = undefined;
    this.failed = false;
    this.load();
  }

  private async load(): Promise<void> {
    const url: string = this.url;
    if (url.length === 0 || JmImage.isGif(url)) {
      return;
    }
    const pm: image.PixelMap | null = await ImageCache.getCoverPixelMap(url, this.comicId);
    if (this.url !== url) {
      return;
    }
    if (pm === null) {
      Logger.debug(TAG, `load failed: ${url}`);
      this.failed = true;
      return;
    }
    this.pm = pm;
  }

  build() {
    if (this.url.length === 0) {
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
    } else if (JmImage.isGif(this.url)) {
      Image(this.url)
        .width(this.imgWidth)
        .height(this.imgHeight)
        .borderRadius(this.imgBorderRadius)
        .objectFit(this.fit)
        .backgroundColor($r('app.color.bg_fill'))
    } else if (this.pm !== undefined) {
      Image(this.pm)
        .width(this.imgWidth)
        .height(this.imgHeight)
        .borderRadius(this.imgBorderRadius)
        .objectFit(this.fit)
        .backgroundColor($r('app.color.bg_fill'))
    } else {
      // 加载中/失败：底色占位；失败时点击可重试
      Row()
        .width(this.imgWidth)
        .height(this.imgHeight)
        .borderRadius(this.imgBorderRadius)
        .backgroundColor($r('app.color.bg_fill'))
        .onClick(() => {
          if (this.failed) {
            this.failed = false;
            this.load();
          }
        })
    }
  }
}
