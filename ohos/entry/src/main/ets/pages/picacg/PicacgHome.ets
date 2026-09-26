// pages/picacg/PicacgHome.ets - Picacg 棣栭〉
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../../common/ThemeManager';
import { Comic } from '../../data/model/Comic';
import { NetworkImage } from '../../components/NetworkImage';

@Entry
@Component
struct PicacgHome {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State comics: Comic[] = []

  aboutToAppear(): void {
    this.comics = this.buildPlaceholderComics();
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('<')
          .fontSize(20)
          .fontColor(this.isDarkMode ? '#4DA6FF' : '#007AFF')
          .margin({ right: 12 })
          .onClick(() => { router.back(); })
        Text('Picacg')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000')
        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 56, bottom: 12 })

      Divider()
        .color(this.isDarkMode ? '#333333' : '#E5E5EA')
        .width('100%')

      // Comic Grid
      Grid() {
        ForEach(this.comics, (comic: Comic) => {
          GridItem() {
            Column() {
              NetworkImage({
                url: comic.coverUrl,
                imgWidth: 100,
                imgHeight: 180,
                imgBorderRadius: 8
              })
              Text(comic.title)
                .fontSize(12)
                .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
                .margin({ top: 6 })
              Text(comic.subTitle)
                .fontSize(10)
                .fontColor(this.isDarkMode ? '#999999' : '#666666')
                .maxLines(1)
                .width('100%')
                .margin({ top: 2 })
            }
            .width('100%')
            .padding(6)
            .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF')
            .borderRadius(8)
            .onClick(() => {
              router.pushUrl({ url: 'pages/ComicDetailPage' });
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(8)
      .rowsGap(10)
      .width('100%')
      .padding(12)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
  }

  private buildPlaceholderComics(): Comic[] {
    const items: Comic[] = [];
    for (let i = 1; i <= 6; i++) {
      const comic: Comic = new Comic();
      comic.id = `pica_${i}`;
      comic.title = `Picacg Comic ${i}`;
      comic.subTitle = 'Manhua';
      comic.author = 'Author';
      comic.coverUrl = '';
      comic.source = 'picacg';
      comic.language = 'Chinese';
      comic.tags = ['Manhua', 'Popular'];
      items.push(comic);
    }
    return items;
  }
}
