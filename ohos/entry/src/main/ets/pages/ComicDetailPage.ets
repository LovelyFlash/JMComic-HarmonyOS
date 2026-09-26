// pages/ComicDetailPage.ets - 漫画详情页（接入 API）
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../common/ThemeManager';
import { Comic } from '../data/model/Comic';
import { Database } from '../data/database/Database';
import { NhentaiApi } from '../data/api/NhentaiApi';
import { JmApi } from '../data/api/JmApi';
import { HtcomicApi } from '../data/api/HtcomicApi';
import { EhentaiApi } from '../data/api/EhentaiApi';
import { PicacgApi } from '../data/api/PicacgApi';
import { HitomiApi } from '../data/api/HitomiApi';

@Entry
@Component
struct ComicDetailPage {
  @State comicId: string = ''
  @State title: string = ''
  @State source: string = ''
  @State comic: Comic = new Comic()
  @State loading: boolean = true
  @State error: string = ''
  @State chapterImages: string[] = []
  @State isFavorite: boolean = false
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params !== null && params !== undefined) {
      this.comicId = params['comicId'] ?? '';
      this.title = params['title'] ?? '';
      this.source = params['source'] ?? '';
    }
    this.loadDetail();
    this.checkFavorite();
  }

  async loadDetail(): Promise<void> {
    this.loading = true;
    try {
      switch (this.source) {
        case 'nhentai': this.comic = await NhentaiApi.getComicInfo(this.comicId); break;
        case 'jm': this.comic = await JmApi.getComicInfo(this.comicId); break;
        case 'ehentai': this.comic = await EhentaiApi.getComicInfo(this.comicId); break;
        case 'picacg': this.comic = await PicacgApi.getComicInfo(this.comicId); break;
        case 'hitomi': this.comic = await HitomiApi.getComicInfo(this.comicId); break;
        case 'htcomic': this.comic = await HtcomicApi.getComicInfo(this.comicId); break;
      }
      this.title = this.comic.title;
    } catch (e) { this.error = String(e); }
    this.loading = false;
  }

  async checkFavorite(): Promise<void> {
    this.isFavorite = await Database.isFavorite(this.comicId, this.source);
  }

  async toggleFavorite(): Promise<void> {
    if (this.isFavorite) {
      await Database.removeFavorite(this.comicId, this.source);
    } else {
      await Database.insertFavorite(this.comicId, this.title, this.comic.coverUrl, this.source);
    }
    this.isFavorite = !this.isFavorite;
  }

  async loadImages(): Promise<void> {
    try {
      switch (this.source) {
        case 'nhentai': this.chapterImages = await NhentaiApi.getImages(this.comicId); break;
        case 'jm': { const ch = await JmApi.getChapter(this.comicId); this.chapterImages = ch.imageUrls; } break;
        case 'htcomic': this.chapterImages = await HtcomicApi.getImages(this.comicId); break;
      }
      if (this.chapterImages.length > 0) {
        router.pushUrl({ url: 'pages/reader/ReaderPage', params: { comicId: this.comicId, images: this.chapterImages.join(','), source: this.source } });
      }
    } catch (e) { this.error = String(e); }
  }

  build() {
    Column() {
      Row() {
        Image($rawfile('icons/ic_back.svg')).width(24).height(24).objectFit(ImageFit.Contain).onClick(() => { router.back(); })
        Text(this.title).fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF')
          .layoutWeight(1).margin({ left: 12 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Image($rawfile('icons/ic_favorites.svg')).width(24).height(24).objectFit(ImageFit.Contain)
          .onClick(() => { this.toggleFavorite(); })
      }.width('100%').height(64).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      if (this.loading) { Column() { LoadingProgress().width(48).height(48) }.layoutWeight(1).justifyContent(FlexAlign.Center) }
      else if (this.error.length > 0) { Column() { Text(this.error).fontSize(14).fontColor('#FF3B30') }.layoutWeight(1).justifyContent(FlexAlign.Center) }
      else {
        Scroll() {
          Column() {
            // Cover + Info
            Row() {
              Image(this.comic.coverUrl).width(130).height(180).objectFit(ImageFit.Cover).borderRadius(8).backgroundColor('#F0F0F0')
              Column() {
                Text(this.comic.title).fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF').maxLines(3).textOverflow({ overflow: TextOverflow.Ellipsis })
                if (this.comic.author.length > 0) { Text('作者: ' + this.comic.author).fontSize(13).fontColor(this.isDarkMode ? this.isDarkMode ? '#999999' : '#999999' : this.isDarkMode ? '#999999' : '#999999').margin({ top: 8 }) }
                if (this.comic.likes > 0) { Text('❤ ' + this.comic.likes.toString()).fontSize(13).fontColor('#FF3B30').margin({ top: 4 }) }
                Text(this.comic.source).fontSize(12).fontColor(this.isDarkMode ? this.isDarkMode ? '#999999' : '#999999' : this.isDarkMode ? '#999999' : '#999999').margin({ top: 4 })
              }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 16 })
            }.width('100%').padding(16)

            // Description
            if (this.comic.description.length > 0) {
              Text(this.comic.description).fontSize(14).fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF').width('100%').padding({ left: 16, right: 16, bottom: 16 })
            }

            // Tags
            if (this.comic.tags.length > 0) {
              Flex({ wrap: FlexWrap.Wrap }) {
                ForEach(this.comic.tags, (tag: string) => {
                  Text(tag).fontSize(12).fontColor(this.isDarkMode ? '#4DA6FF' : '#007AFF').backgroundColor('#F0F8FF').borderRadius(4)
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 }).margin({ right: 6, bottom: 6 })
                })
              }.width('100%').padding({ left: 16, right: 16, bottom: 16 })
            }

            // Read button
            Button('开始阅读')
              .width('90%').height(48).fontSize(16).fontColor('#FFFFFF')
              .backgroundColor(this.isDarkMode ? '#4DA6FF' : '#007AFF').borderRadius(12)
              .margin({ top: 8, bottom: 24 })
              .onClick(() => { this.loadImages(); })
          }
        }.layoutWeight(1)
      }
    }.width('100%').height('100%').backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
  }
}
