@Entry
@Component
struct MainPage {
  build() {
    Column() {
      Text('PicaComic')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .height(56)
        .padding(16)
        .backgroundColor('#FFFFFF')
      Text('鸿蒙版漫画阅读器')
        .fontSize(16)
        .fontColor('#666666')
        .margin({ top: 48 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
