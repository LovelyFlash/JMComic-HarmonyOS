// pages/picacg/PicacgHome.ets - Picacg 首页
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../../common/ThemeManager';
import { Comic } from '../../data/model/Comic';
import { PicacgApi } from '../../data/api/PicacgApi';

@Entry
@Component
struct PicacgHome {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State comics: Comic[] = []

  pageTransition() {
    PageTransitionEnter({ duration: 250, curve: Curve.FastOutSlowIn })
    PageTransitionExit({ duration: 200, curve: Curve.FastOutSlowIn })
  }
  @State loading: boolean = true
  @State error: string = ''

  aboutToAppear(): void { this.loadData(); }

  async loadData(): Promise<void> {
    this.loading = true;
    try { this.comics = await PicacgApi.getComics(1); }
    catch (e) { this.error = String(e); }
    this.loading = false;
  }

  build() {
    Column({ space: 8 }) {
      Row() {
        Image($rawfile('icons/ic_back.svg')).width(24).height(24).objectFit(ImageFit.Contain).onClick(() => { router.back(); })
        Text('Picacg').fontSize(22).fontWeight(FontWeight.Bold).fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF').margin({ left: 12 })
        Blank()
      }.width('100%').height(64).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      if (this.loading) { Column({ space: 8 }) { LoadingProgress().width(48).height(48) }.layoutWeight(1).justifyContent(FlexAlign.Center) }
      else if (this.error.length > 0) { Column({ space: 8 }) { Text(this.error).fontSize(14).fontColor('#FF3B30') }.layoutWeight(1).justifyContent(FlexAlign.Center) }
      else {
        Grid() {
          ForEach(this.comics, (comic: Comic) => {
            GridItem() {
              Column({ space: 8 }) {
                Image(comic.coverUrl).width('100%').height(180).objectFit(ImageFit.Cover).borderRadius(6).backgroundColor('#F0F0F0')
                Text(comic.title).fontSize(12).fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').margin({ top: 6 })
              }.width('100%').padding(6).backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF').borderRadius(8).shadow({ radius: 8, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.08)', offsetX: 0, offsetY: 2 })
              .onClick(() => { router.pushUrl({ url: 'pages/ComicDetailPage', params: { comicId: comic.id, title: comic.title, source: 'picacg' } }); })
            }
          })
        }.columnsTemplate('1fr 1fr 1fr').columnsGap(8).rowsGap(10).width('100%').padding(12).layoutWeight(1)
      }
    }.width('100%').height('100%').backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
  }
}
