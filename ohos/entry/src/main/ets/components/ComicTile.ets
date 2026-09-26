// components/ComicTile.ets - 漫画卡片（横向列表项）
import { Comic } from '../data/model/Comic';
import { NetworkImage } from './NetworkImage';

@Component
export struct ComicTile {
  @Prop comic: Comic = new Comic()
  @Prop onTap: (id: string, source: string) => void = () => {}

  build() {
    Row() {
      NetworkImage({ url: this.comic.coverUrl, width: 90, height: 120, borderRadius: 6 })
      Column() {
        Text(this.comic.title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        if (this.comic.author.length > 0) {
          Text(this.comic.author)
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
            .maxLines(1)
        }
        if (this.comic.tags.length > 0) {
          Row() {
            ForEach(this.comic.tags.slice(0, 3), (tag: string) => {
              Text(tag)
                .fontSize(10)
                .fontColor('#007AFF')
                .backgroundColor('#F0F8FF')
                .borderRadius(4)
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .margin({ right: 4 })
            })
          }
          .margin({ top: 8 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(12)
    .onClick(() => {
      this.onTap(this.comic.id, this.comic.source);
    })
  }
}
