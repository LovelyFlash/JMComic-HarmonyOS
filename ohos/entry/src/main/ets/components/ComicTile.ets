// components/ComicTile.ets - 漫画卡片（横向列表项）
import { Comic } from '../data/model/Comic';
import { NetworkImage } from './NetworkImage';

@Component
export struct ComicTile {
  @Prop comic: Comic = new Comic()
  
  
  onTap: (id: string, source: string) => void = () => {}

  build() {
    Row() {
      NetworkImage({ url: this.comic.coverUrl, imgWidth: 90, imgHeight: 120, imgBorderRadius: 6 })
      Column({ space: 8 }) {
        Text(this.comic.title)
          .fontSize(15).fontWeight(FontWeight.Medium).maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
        if (this.comic.author.length > 0) {
          Text(this.comic.author).fontSize(12).fontColor($r('app.color.text_secondary'))
            .margin({ top: 4 }).maxLines(1)
        }
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 12 })
    }
    .width('100%').padding(12)
    .onClick(() => { this.onTap(this.comic.id, this.comic.source); })
  }
}
