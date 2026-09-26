// components/ComicTile.ets - 漫画卡片（横向列表项）
import { Comic } from '../data/model/Comic';
import { NetworkImage } from './NetworkImage';

@ComponentV2
export struct ComicTile {
  @Param comic: Comic = new Comic()
  @Event onTap: (id: string, source: string) => void = () => {}

  build() {
    Row() {
      NetworkImage({ url: this.comic.coverUrl, imgWidth: 90, imgHeight: 120, imgBorderRadius: 6 })
      Column() {
        Text(this.comic.title)
          .fontSize(15).fontWeight(FontWeight.Medium).maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
        if (this.comic.author.length > 0) {
          Text(this.comic.author).fontSize(12).fontColor('#999999')
            .margin({ top: 4 }).maxLines(1)
        }
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 12 })
    }
    .width('100%').padding(12)
    .onClick(() => { this.onTap(this.comic.id, this.comic.source); })
  }
}
