// pages/SearchPage.ets - 搜索页（禁漫 JM-only + 7 种排序 + maxPage 分页）- NavDestination
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { Comic } from '../data/model/Comic';
import { JmApi } from '../data/api/JmApi';
import { Settings } from '../data/preferences/Settings';
import { ArrayDataSource } from '../common/ArrayDataSource';
import { NavTitleBar } from '../components/NavTitleBar';

class SortOption {
  key: string = '';
  labelKey: string = '';
  constructor(key: string, labelKey: string) {
    this.key = key;
    this.labelKey = labelKey;
  }
}

@Builder
export function SearchPageBuilder(name: string, param: object) {
  SearchPage({ pageParam: param })
}

@Component
export struct SearchPage {
  pageParam: object | undefined = undefined;
  @State keyword: string = ''
  @State dataSource: ArrayDataSource<Comic> = new ArrayDataSource<Comic>()
  @State loading: boolean = false
  @State loadingMore: boolean = false
  @State error: string = ''
  @State currentPage: number = 1
  @State maxPage: number = 1
  @State searched: boolean = false
  @State sort: string = 'mr'
  
  @StorageProp('bottomAvoidHeight') bottomAvoid: number = 0
  @StorageProp('themeColor') themeColor: string = '#2563EB'

  private makeSorts(): SortOption[] {
    const list: SortOption[] = [];
    list.push(new SortOption('mr', 'order_mr'));
    list.push(new SortOption('mv', 'order_mv'));
    list.push(new SortOption('mv_m', 'order_mv_m'));
    list.push(new SortOption('mv_w', 'order_mv_w'));
    list.push(new SortOption('mv_t', 'order_mv_t'));
    list.push(new SortOption('mp', 'order_mp'));
    list.push(new SortOption('tf', 'order_tf'));
    return list;
  }

  aboutToAppear(): void {
    if (this.pageParam !== undefined && this.pageParam !== null) {
      const params = this.pageParam as Record<string, Object>;
      const kw = params['keyword'] !== undefined && params['keyword'] !== null ? String(params['keyword']) : '';
      const srt = params['sort'] !== undefined && params['sort'] !== null ? String(params['sort']) : '';
      if (kw.length > 0) { this.keyword = kw; }
      if (srt.length > 0) { this.sort = srt; }
      if (kw.length > 0 || srt.length > 0) { this.doSearch(); }
    }
  }

  private async saveHistory(kw: string): Promise<void> {
    const raw = await Settings.getString('searchHistory', '');
    const parts = raw.length > 0 ? raw.split('|') : [];
    const filtered: string[] = [];
    filtered.push(kw);
    for (let i = 0; i < parts.length && filtered.length < 20; i++) {
      if (parts[i] !== kw && parts[i].length > 0) {
        filtered.push(parts[i]);
      }
    }
    await Settings.putString('searchHistory', filtered.join('|'));
  }

  async doSearch(): Promise<void> {
    if (this.keyword.length === 0) {
      return;
    }
    this.loading = true;
    this.error = '';
    this.dataSource = new ArrayDataSource<Comic>();
    this.currentPage = 1;
    this.searched = true;
    this.saveHistory(this.keyword);
    try {
      await this.loadPage(1, true);
    } catch (e) {
      this.error = String(e);
    }
    this.loading = false;
  }

  async loadPage(page: number, replace: boolean): Promise<void> {
    const result = await JmApi.search(this.keyword, page, this.sort);
    this.maxPage = result.maxPage > 0 ? result.maxPage : page;
    this.currentPage = page;
    if (replace) {
      this.dataSource = new ArrayDataSource<Comic>(result.comics);
    } else {
      this.dataSource.addAll(result.comics);
    }
  }

  async loadMore(): Promise<void> {
    if (this.loadingMore || this.loading) return;
    if (this.currentPage >= this.maxPage) return;
    this.loadingMore = true;
    try {
      await this.loadPage(this.currentPage + 1, false);
    } catch (e) {
      this.error = String(e);
    }
    this.loadingMore = false;
  }

  @Builder
  searchInput() {
    Row({ space: 8 }) {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(20)
        .fontColor([$r('app.color.text_secondary')])
      TextInput({ text: this.keyword, placeholder: Translations.t('search_hint') })
        .layoutWeight(1)
        .height(36)
        .fontSize(14)
        .backgroundColor(Color.Transparent)
        .fontColor($r('app.color.text_primary'))
        .placeholderColor($r('app.color.text_secondary'))
        .caretColor(this.themeColor)
        .onChange((value: string) => { this.keyword = value; })
        .onSubmit(() => { this.doSearch(); })
      if (this.keyword.length > 0) {
        SymbolGlyph($r('sys.symbol.xmark_circle_fill'))
          .fontSize(18)
          .fontColor([$r('app.color.text_tertiary')])
          .onClick(() => {
            this.keyword = '';
            this.dataSource = new ArrayDataSource<Comic>();
            this.searched = false;
          })
      }
    }
    .width('100%')
    .height(44)
    .padding({ left: 12, right: 12 })
    .margin({ left: 16, right: 16, bottom: 8 })
    .backgroundColor($r('app.color.bg_fill'))
    .borderRadius(22)
    .id('searchInput')
  }

  @Builder
  sortBar() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.makeSorts(), (opt: SortOption) => {
          Text(Translations.t(opt.labelKey))
            .fontSize(12)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(14)
            .fontColor(this.sort === opt.key ? $r('app.color.text_on_brand') : $r('app.color.text_secondary'))
            .backgroundColor(this.sort === opt.key ? this.themeColor : $r('app.color.bg_fill'))
            .onClick(() => {
              if (this.sort !== opt.key) {
                this.sort = opt.key;
                if (this.keyword.length > 0) {
                  this.doSearch();
                }
              }
            })
            .id('searchSort' + opt.key)
        }, (opt: SortOption) => opt.key)
      }
      .padding({ left: 16, right: 16, bottom: 8 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .id('searchSortBar')
  }

  @Builder
  results() {
    if (this.loading) {
      Column({ space: 8 }) {
        LoadingProgress().width(48).height(48)
      }
      .layoutWeight(1).justifyContent(FlexAlign.Center)
    } else if (this.error.length > 0) {
      Column({ space: 12 }) {
        Text(this.error).fontSize(14).fontColor($r('app.color.danger'))
        Button(Translations.t('retry'))
          .fontSize(14)
          .backgroundColor(this.themeColor)
          .fontColor($r('app.color.text_on_brand'))
          .onClick(() => { this.doSearch(); })
      }
      .layoutWeight(1).justifyContent(FlexAlign.Center)
      .id('resultsError')
    } else if (!this.searched) {
      Column({ space: 8 }) {
        Text(Translations.t('search_hint'))
          .fontSize(14).fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1).justifyContent(FlexAlign.Center)
      .id('resultsHint')
    } else if (this.dataSource.totalCount() === 0) {
      Column({ space: 8 }) {
        Text(Translations.t('no_data'))
          .fontSize(14).fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1).justifyContent(FlexAlign.Center)
      .id('resultsEmpty')
    } else {
      List({ space: 1 }) {
        LazyForEach(this.dataSource, (comic: Comic) => {
          ListItem() {
            Row({ space: 12 }) {
              Image(comic.coverUrl)
                .width(80).height(110)
                .objectFit(ImageFit.Cover)
                .borderRadius(6)
                .backgroundColor($r('app.color.bg_fill'))
              Column({ space: 6 }) {
                Text(comic.title)
                  .fontSize(15).fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                  .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                if (comic.author.length > 0) {
                  Text(comic.author)
                    .fontSize(12).fontColor($r('app.color.text_secondary'))
                    .maxLines(1)
                }
              }
              .layoutWeight(1).alignItems(HorizontalAlign.Start)
            }
            .width('100%').padding(12)
            .onClick(() => {
              const param: Record<string, Object> = {
                'comicId': comic.id, 'title': comic.title, 'source': 'jm'
              };
              NavUtil.push('comicDetail', param);
            })
          }
          .id('searchComic' + comic.id)
        }, (comic: Comic) => comic.id)

        ListItem() {
          if (this.loadingMore) {
            Column({ space: 8 }) {
              LoadingProgress().width(32).height(32)
            }
            .width('100%').height(48).justifyContent(FlexAlign.Center)
          } else if (this.currentPage < this.maxPage) {
            Text(Translations.t('load_more'))
              .fontSize(13)
              .fontColor(this.themeColor)
              .width('100%').height(48)
              .textAlign(TextAlign.Center)
              .onClick(() => { this.loadMore(); })
          }
        }
      }
      .layoutWeight(1)
      .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
      .edgeEffect(EdgeEffect.Spring)
      .onReachEnd(() => { this.loadMore(); })
      .id('resultsList')
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
      .padding({ bottom: this.bottomAvoid })
    }
  }

  build() {
    NavDestination() {
      
        Column({ space: 0 }) {
          NavTitleBar({ title: Translations.t('search') })
          this.searchInput()
          this.sortBar()
          this.results()
        }
        .width('100%').height('100%')
        .backgroundColor($r('app.color.bg_page'))
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_page'))
  }
}
