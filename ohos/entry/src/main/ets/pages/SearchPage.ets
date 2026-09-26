// pages/SearchPage.ets - 搜索页
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';
import { Comic, ComicBrief } from '../data/model/Comic';
import { NhentaiApi } from '../data/api/NhentaiApi';
import { JmApi } from '../data/api/JmApi';
import { HtcomicApi } from '../data/api/HtcomicApi';

@Entry
@Component
struct SearchPage {
  @State keyword: string = ''
  @State comics: Comic[] = []
  @State loading: boolean = false
  @State error: string = ''
  @State selectedSource: number = 0
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  private sources: string[] = ['NHentai', 'JinMan', 'HT']

  @Builder
  header() {
    Row() {
      Image($rawfile('icons/ic_back.svg')).width(24).height(24).objectFit(ImageFit.Contain)
        .onClick(() => { router.back(); })
      Text(Translations.t('search_hint')).fontSize(22).fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000').margin({ left: 12 })
    }.width('100%').height(64).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)
  }

  @Builder
  sourceTabs() {
    Row({ space: 8 }) {
      ForEach(this.sources, (src: string, idx: number) => {
        Text(src).fontSize(13).padding({ left: 12, right: 12, top: 6, bottom: 6 })
          .borderRadius(16)
          .fontColor(this.selectedSource === idx ? '#FFFFFF' : (this.isDarkMode ? '#999999' : '#666666'))
          .backgroundColor(this.selectedSource === idx ? (this.isDarkMode ? '#4DA6FF' : '#007AFF') : 'transparent')
          .onClick(() => { this.selectedSource = idx; })
      })
    }.width('100%').padding({ left: 16, right: 16, bottom: 8 })
  }

  @Builder
  results() {
    if (this.loading) {
      Column({ space: 8 }) { LoadingProgress().width(48).height(48) }.layoutWeight(1).justifyContent(FlexAlign.Center)
    } else if (this.error.length > 0) {
      Column({ space: 8 }) { Text(this.error).fontSize(14).fontColor('#FF3B30') }.layoutWeight(1).justifyContent(FlexAlign.Center)
    } else if (this.comics.length === 0) {
      Column({ space: 8 }) { Text(Translations.t('search_hint')).fontSize(14).fontColor(this.isDarkMode ? '#999999' : '#666666') }
        .layoutWeight(1).justifyContent(FlexAlign.Center)
    } else {
      List({ space: 1 }) {
        ForEach(this.comics, (comic: Comic) => {
          ListItem() {
            Row() {
              Image(comic.coverUrl).width(80).height(110).objectFit(ImageFit.Cover)
                .borderRadius(6).backgroundColor(this.isDarkMode ? '#2C2C2E' : '#F0F0F0')
              Column({ space: 8 }) {
                Text(comic.title).fontSize(15).fontWeight(FontWeight.Medium)
                  .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000')
                  .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
                if (comic.author.length > 0) {
                  Text(comic.author).fontSize(12).fontColor(this.isDarkMode ? '#999999' : '#666666')
                    .margin({ top: 4 }).maxLines(1)
                }
              }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 12 })
            }.width('100%').padding(12).onClick(() => {
              router.pushUrl({ url: 'pages/ComicDetailPage', params: { comicId: comic.id, title: comic.title, source: comic.source } });
            })
          }
        })
      }.layoutWeight(1).divider({ strokeWidth: 0.5, color: this.isDarkMode ? '#333333' : '#E5E5EA' })
        .edgeEffect(EdgeEffect.Spring)
    }
  }

  build() {
    Column({ space: 8 }) {
      this.header()
      Search({ value: $$this.keyword, placeholder: Translations.t('search_hint') })
        .layoutWeight(1).height(40).margin({ left: 16, right: 16, bottom: 8 })
        .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#F5F5F5').borderRadius(20)
        .onChange((value: string) => { this.keyword = value; })
        .onSubmit(() => { this.doSearch(); })
      this.sourceTabs()
      this.results()
    }.width('100%').height('100%').backgroundColor(this.isDarkMode ? '#000000' : '#F5F5F5')
  }

  async doSearch(): Promise<void> {
    if (this.keyword.length === 0) return;
    this.loading = true; this.error = ''; this.comics = [];
    try {
      if (this.selectedSource === 0) {
        const result = await NhentaiApi.search(this.keyword, 1);
        this.comics = result.comics.map((b: ComicBrief) => {
          const c = new Comic(); c.id = b.id; c.title = b.title; c.coverUrl = b.cover; c.source = 'nhentai'; return c;
        });
      } else if (this.selectedSource === 1) {
        this.comics = await JmApi.search(this.keyword, 1);
      } else {
        const result = await HtcomicApi.search(this.keyword, 1);
        this.comics = result.comics.map((b: ComicBrief) => {
          const c = new Comic(); c.id = b.id; c.title = b.title; c.coverUrl = b.cover; c.source = 'htcomic'; return c;
        });
      }
    } catch (e) { this.error = String(e); }
    this.loading = false;
  }
}
