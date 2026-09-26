@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('PicaComic')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .height(100)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
