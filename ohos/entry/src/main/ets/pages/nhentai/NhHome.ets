// pages/nhentai/NhHome.ets - NHentai 首页（真实 API）
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../../common/ThemeManager';
import { Comic } from '../../data/model/Comic';
import { ComicBrief } from '../../data/model/Comic';
import { NhentaiApi } from '../../data/api/NhentaiApi';

@Entry
@Component
struct NhHome {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State comics: Comic[] = []
  @State loading: boolean = true
  @State error: string = ''
  @State page: number = 1

  aboutToAppear(): void { this.loadData(); }

  async loadData(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      const result = await NhentaiApi.getHomePage(this.page);
      this.comics = result.comics.map((b: ComicBrief) => { const c = new Comic(); c.id = b.id; c.title = b.title; c.coverUrl = b.cover; c.source = 'nhentai'; return c; });
    } catch (e) { this.error = String(e); }
    this.loading = false;
  }

  build() {
    Column() {
      Row() {
        Image($rawfile('icons/ic_back.svg')).width(24).height(24).objectFit(ImageFit.Contain)
          .onClick(() => { router.back(); })
        Text('NHentai').fontSize(22).fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF').margin({ left: 12 })
        Blank()
      }.width('100%').height(64).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      if (this.loading) {
        Column() { LoadingProgress().width(48).height(48) }.layoutWeight(1).justifyContent(FlexAlign.Center)
      } else if (this.error.length > 0) {
        Column() { Text(this.error).fontSize(14).fontColor('#FF3B30') }.layoutWeight(1).justifyContent(FlexAlign.Center)
      } else {
        Grid() {
          ForEach(this.comics, (comic: Comic) => {
            GridItem() {
              Column() {
                Image(comic.coverUrl).width('100%').height(180).objectFit(ImageFit.Cover).borderRadius(6).backgroundColor('#F0F0F0')
                Text(comic.title).fontSize(12).fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF')
                  .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').margin({ top: 6 })
              }.width('100%').padding(6).backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF').borderRadius(8)
              .onClick(() => { router.pushUrl({ url: 'pages/ComicDetailPage', params: { comicId: comic.id, title: comic.title, source: 'nhentai' } }); })
            }
          })
        }.columnsTemplate('1fr 1fr 1fr').columnsGap(8).rowsGap(10).width('100%').padding(12).layoutWeight(1)
      }
    }.width('100%').height('100%').backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
  }
}
