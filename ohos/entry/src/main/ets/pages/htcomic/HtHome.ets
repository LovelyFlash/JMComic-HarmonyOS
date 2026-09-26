// pages/htcomic/HtHome.ets - 缁呭＋婕敾棣栭〉
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../../common/ThemeManager';
import { Comic } from '../../data/model/Comic';
import { NetworkImage } from '../../components/NetworkImage';

@Entry
@Component
struct HtHome {
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
          .fontColor(ThemeManager.colors.primary)
          .margin({ right: 12 })
          .onClick(() => { router.back(); })
        Text('缁呭＋婕敾')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeManager.colors.textPrimary)
        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 56, bottom: 12 })

      Divider()
        .color(ThemeManager.colors.border)
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
                .fontColor(ThemeManager.colors.textPrimary)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
                .margin({ top: 6 })
              Text(comic.subTitle)
                .fontSize(10)
                .fontColor(ThemeManager.colors.textSecondary)
                .maxLines(1)
                .width('100%')
                .margin({ top: 2 })
            }
            .width('100%')
            .padding(6)
            .backgroundColor(ThemeManager.colors.surface)
            .borderRadius(8)
            .onClick(() => {
              router.pushUrl({ url: 'pages/htcomic/HtDetail' });
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
    .backgroundColor(ThemeManager.colors.background)
  }

  private buildPlaceholderComics(): Comic[] {
    const items: Comic[] = [];
    for (let i = 1; i <= 6; i++) {
      const comic: Comic = new Comic();
      comic.id = `ht_${i}`;
      comic.title = `缁呭＋婕敾 ${i}`;
      comic.subTitle = 'Manga';
      comic.author = 'Artist';
      comic.coverUrl = '';
      comic.source = 'htmanga';
      comic.language = 'Chinese';
      comic.tags = ['Manga', 'Chinese'];
      items.push(comic);
    }
    return items;
  }
}
