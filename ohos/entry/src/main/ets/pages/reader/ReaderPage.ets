// pages/reader/ReaderPage.ets - 阅读器（真实图片）
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../../common/ThemeManager';
import { Logger } from '../../common/Logger';

@Entry
@Component
struct ReaderPage {
  @State comicId: string = ''
  @State images: string[] = []
  @State currentIndex: number = 0
  @State showToolbar: boolean = false
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params !== null && params !== undefined) {
      this.comicId = params['comicId'] ?? '';
      const imagesStr = params['images'] ?? '';
      if (imagesStr.length > 0) {
        this.images = imagesStr.split(',');
      }
    }
  }

  build() {
    Stack() {
      // Image swiper
      Swiper() {
        ForEach(this.images, (url: string) => {
          if (url.length > 0) {
            Image(url)
              .width('100%').height('100%')
              .objectFit(ImageFit.Contain)
              .backgroundColor('#000000')
              .onError(() => { Logger.debug('ReaderPage', `Image load failed: ${url}`); })
          } else {
            Column() { Text('...').fontSize(16).fontColor('#FFFFFF') }
              .width('100%').height('100%').justifyContent(FlexAlign.Center).backgroundColor('#000000')
          }
        })
      }
      .index(this.currentIndex)
      .indicator(false)
      .onChange((index: number) => { this.currentIndex = index; })
      .width('100%').height('100%')

      // Toolbar overlay
      if (this.showToolbar) {
        Column() {
          Row() {
            Image($rawfile('icons/ic_back.svg')).width(24).height(24).objectFit(ImageFit.Contain)
              .onClick(() => { router.back(); })
            Text(`${this.currentIndex + 1} / ${this.images.length}`).fontSize(14).fontColor('#FFFFFF').layoutWeight(1).textAlign(TextAlign.Center)
            Text(' ').width(24)
          }.width('100%').height(56).padding({ left: 16, right: 16 }).backgroundColor('rgba(0,0,0,0.6)').alignItems(VerticalAlign.Center)
          Blank().layoutWeight(1)
          Row() { Text(`${this.currentIndex + 1} / ${this.images.length}`).fontSize(14).fontColor('#FFFFFF') }
            .width('100%').height(48).backgroundColor('rgba(0,0,0,0.6)').justifyContent(FlexAlign.Center)
        }.width('100%').height('100%')
      }
    }
    .width('100%').height('100%').backgroundColor('#000000')
    .onClick(() => { this.showToolbar = !this.showToolbar; })
  }
}
