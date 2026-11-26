// pages/SearchPage.ets - 搜索页（禁漫 JM-only + 7 种排序 + maxPage 分页）- NavDestination
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { NetworkImage } from '../components/NetworkImage';
import { Comic } from '../data/model/Comic';
import { JmApi } from '../data/api/JmApi';
import { Settings } from '../data/preferences/Settings';
import { ArrayDataSource } from '../common/ArrayDataSource';
import { DEFAULT_THEME_COLOR } from '../common/Constants';
import { uiMaterial } from '@kit.ArkUI';
import { SearchBar } from '../components/SearchBar';

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
  @State title: string = Translations.t('search')
  @State keyword: string = ''
  /** LazyForEach 数据源必须固定实例；刷新只走 replaceAll/clearData/addAll */
  private dataSource: ArrayDataSource<Comic> = new ArrayDataSource<Comic>()
  @State itemCount: number = 0
  /** 请求世代号：新搜索/排序后，迟到的旧响应直接丢弃 */
  private requestSeq: number = 0
  @State loading: boolean = false
  @State loadingMore: boolean = false
  @State error: string = ''
  @State currentPage: number = 1
  @State maxPage: number = 1
  @State searched: boolean = false
  @State sort: string = 'mr'
  
  @StorageProp('bottomAvoidHeight') bottomAvoid: number = 0
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR

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

  private sortOptions(): SelectOption[] {
    const sorts: SortOption[] = this.makeSorts();
    const opts: SelectOption[] = [];
    for (let i = 0; i < sorts.length; i++) {
      opts.push({ value: Translations.t(sorts[i].labelKey) });
    }
    return opts;
  }

  private sortIndex(): number {
    const sorts: SortOption[] = this.makeSorts();
    for (let i = 0; i < sorts.length; i++) {
      if (sorts[i].key === this.sort) {
        return i;
      }
    }
    return 0;
  }

  private currentSortLabel(): string {
    const sorts: SortOption[] = this.makeSorts();
    const idx: number = this.sortIndex();
    return sorts.length > 0 ? Translations.t(sorts[idx].labelKey) : '';
  }

  private selectSort(index: number): void {
    const sorts: SortOption[] = this.makeSorts();
    if (index < 0 || index >= sorts.length) {
      return;
    }
    const key: string = sorts[index].key;
    if (this.sort !== key) {
      this.sort = key;
      if (this.keyword.length > 0) {
        this.doSearch();
      }
    }
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
    const seq: number = ++this.requestSeq;
    this.loading = true;
    this.loadingMore = false;
    this.error = '';
    this.title = Translations.t('search_results');
    this.dataSource.clearData();
    this.itemCount = 0;
    this.currentPage = 1;
    this.searched = true;
    this.saveHistory(this.keyword);
    // 纯数字关键词按漫画 ID 处理：命中直接进入详情页，未命中回退为关键词搜索
    if (/^\d+$/.test(this.keyword)) {
      try {
        const comic: Comic = await JmApi.getComicInfo(this.keyword);
        if (seq !== this.requestSeq) {
          return;
        }
        if (comic.id.length > 0 && comic.title.length > 0 && comic.title !== '未知') {
          this.loading = false;
          const param: Record<string, Object> = {
            'comicId': comic.id, 'title': comic.title, 'source': comic.source
          };
          NavUtil.replace('comicDetail', param);
          return;
        }
      } catch (e) {
        // ID 不存在或请求失败 → 回退关键词搜索
      }
    }
    try {
      await this.loadPage(1, true, seq);
    } catch (e) {
      if (seq === this.requestSeq) {
        this.error = String(e);
      }
    }
    if (seq === this.requestSeq) {
      this.loading = false;
    }
  }

  async loadPage(page: number, replace: boolean, seq: number): Promise<void> {
    const result = await JmApi.search(this.keyword, page, this.sort);
    if (seq !== this.requestSeq) {
      return;
    }
    this.maxPage = result.maxPage > 0 ? result.maxPage : page;
    this.currentPage = page;
    if (replace) {
      this.dataSource.replaceAll(result.comics);
      this.itemCount = result.comics.length;
    } else {
      this.dataSource.addAll(result.comics);
      this.itemCount += result.comics.length;
    }
  }

  async loadMore(): Promise<void> {
    if (this.loadingMore || this.loading) return;
    if (this.currentPage >= this.maxPage) return;
    const seq: number = this.requestSeq;
    this.loadingMore = true;
    try {
      await this.loadPage(this.currentPage + 1, false, seq);
    } catch (e) {
      if (seq === this.requestSeq) {
        this.error = String(e);
      }
    }
    if (seq === this.requestSeq) {
      this.loadingMore = false;
    }
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
    } else if (this.itemCount === 0) {
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
              NetworkImage({ url: comic.coverUrl, comicId: comic.id, imgWidth: 80, imgHeight: 110, imgBorderRadius: 6 })
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
          Column() {
            SearchBar({
              editable: true,
              text: this.keyword,
              placeholder: Translations.t('search_hint'),
              showClear: this.keyword.length > 0,
              itemId: 'searchInput',
              showSortSelect: true,
              sortOptions: this.sortOptions(),
              sortIndex: this.sortIndex(),
              sortLabel: this.currentSortLabel(),
              onSortSelect: (index: number) => { this.selectSort(index); },
              onTextChange: (value: string) => { this.keyword = value; },
              onSubmit: () => { this.doSearch(); },
              onClear: () => {
                this.requestSeq++;
                this.loading = false;
                this.loadingMore = false;
                this.keyword = '';
                this.title = Translations.t('search');
                this.dataSource.clearData();
                this.itemCount = 0;
                this.searched = false;
              }
            })
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 8 })
          this.results()
        }
        .width('100%').height('100%')
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .title(this.title, { backgroundColor: Color.Transparent })
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .hideTitleBar(false)
    .backgroundColor($r('app.color.bg_page'))
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    }))
  }
}
