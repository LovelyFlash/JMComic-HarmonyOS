// components/ComicGrid.ets - 漫画网格组件
import { Comic } from '../data/model/Comic';
import { NetworkImage } from './NetworkImage';

@ComponentV2
export struct ComicGrid {
  @Param comics: Comic[] = []
  @Param columns: number = 3
  @Event onTap: (id: string, source: string) => void = () => {}

  build() {
    Grid() {
      ForEach(this.comics, (comic: Comic) => {
        GridItem() {
          Column({ space: 8 }) {
            NetworkImage({ url: comic.coverUrl, imgWidth: 100, imgHeight: 140, imgBorderRadius: 6 })
            Text(comic.title)
              .fontSize(12).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%').margin({ top: 6 })
          }
          .width('100%').padding(6).onClick(() => {
            this.onTap(comic.id, comic.source);
          })
        }
      })
    }
    .columnsTemplate(this.templateString())
    .columnsGap(8).rowsGap(8).width('100%').padding(12)
  }

  private templateString(): string {
    let t = '';
    for (let i = 0; i < this.columns; i++) {
      t += '1fr';
      if (i < this.columns - 1) { t += ' '; }
    }
    return t;
  }
}
