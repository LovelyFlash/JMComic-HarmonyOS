// pages/JmCategoryPage.ets - 禁漫分类漫画分页（/categories/filter + 排序）- NavDestination
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { Comic } from '../data/model/Comic';
import { JmApi } from '../data/api/JmApi';
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
export function JmCategoryPageBuilder(name: string, param: object) {
  JmCategoryPage({ pageParam: param })
}

@Component
export struct JmCategoryPage {
  pageParam: object | undefined = undefined;
  slug: string = ''
  categoryTitle: string = ''
  @State sort: string = 'mr'
  @State dataSource: ArrayDataSource<Comic> = new ArrayDataSource<Comic>()
  @State loading: boolean = true
  @State loadingMore: boolean = false
  @State error: string = ''
  @State currentPage: number = 1
  @State maxPage: number = 1
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @StorageLink('themeVersion') themeVersion: number = 0

  aboutToAppear(): void {
    if (this.pageParam !== undefined && this.pageParam !== null) {
      const params = this.pageParam as Record<string, Object>;
      this.slug = params['slug'] !== undefined && params['slug'] !== null ? String(params['slug']) : '';
      this.categoryTitle = params['title'] !== undefined && params['title'] !== null ? String(params['title']) : '';
      const order = params['order'] !== undefined && params['order'] !== null ? String(params['order']) : '';
      if (order.length > 0) {
        this.sort = order;
      }
    }
    this.loadPage(1, true);
  }

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

  async loadPage(page: number, replace: boolean): Promise<void> {
    if (replace) {
      this.loading = true;
      this.error = '';
    }
    try {
      const result = await JmApi.getCategoryComics(this.slug, this.sort, page);
      this.maxPage = result.maxPage > 0 ? result.maxPage : page;
      this.currentPage = page;
      if (replace) {
        this.dataSource = new ArrayDataSource<Comic>(result.comics);
      } else {
        this.dataSource.addAll(result.comics);
      }
    } catch (e) {
      if (replace) {
        this.error = String(e);
      }
    }
    if (replace) {
      this.loading = false;
    }
  }

  async loadMore(): Promise<void> {
    if (this.loadingMore || this.loading) return;
    if (this.currentPage >= this.maxPage) return;
    this.loadingMore = true;
    try {
      await this.loadPage(this.currentPage + 1, false);
    } catch (e) {
      // 忽略加载更多错误
    }
    this.loadingMore = false;
  }

  private changeSort(key: string): void {
    if (this.sort === key) {
      return;
    }
    this.sort = key;
    this.loadPage(1, true);
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
            .fontColor(this.sort === opt.key ? '#FFFFFF' : ThemeManager.textSecondary)
            .backgroundColor(this.sort === opt.key ? ThemeManager.primary : ThemeManager.surface)
            .onClick(() => { this.changeSort(opt.key); })
            .id('sort' + opt.key + this.themeVersion)
        }, (opt: SortOption) => opt.key)
      }
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .id('sortBar' + this.themeVersion)
  }

  @Builder
  comicRows() {
    List({ space: 1 }) {
      LazyForEach(this.dataSource, (comic: Comic) => {
        ListItem() {
          Row({ space: 12 }) {
            Image(comic.coverUrl)
              .width(80).height(110)
              .objectFit(ImageFit.Cover)
              .borderRadius(6)
              .backgroundColor(ThemeManager.surface)
            Column({ space: 6 }) {
              Text(comic.title)
                .fontSize(15).fontWeight(FontWeight.Medium)
                .fontColor(ThemeManager.textPrimary)
                .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
              if (comic.author.length > 0) {
                Text(comic.author)
                  .fontSize(12).fontColor(ThemeManager.textSecondary)
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
        .id('comic' + comic.id + this.themeVersion)
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
            .fontColor(ThemeManager.primary)
            .width('100%').height(48)
            .textAlign(TextAlign.Center)
            .onClick(() => { this.loadMore(); })
        }
      }
    }
    .layoutWeight(1)
    .divider({ strokeWidth: 0.5, color: ThemeManager.divider })
    .edgeEffect(EdgeEffect.Spring)
    .onReachEnd(() => { this.loadMore(); })
    .id('comicRows' + this.themeVersion)
  }

  build() {
    NavDestination() {
      ForEach([this.themeVersion], (v: number) => {
        Column({ space: 0 }) {
          NavTitleBar({ title: this.categoryTitle })
          this.sortBar()
          if (this.loading) {
            Column() {
              LoadingProgress().width(40).height(40)
            }
            .layoutWeight(1).justifyContent(FlexAlign.Center)
          } else if (this.error.length > 0) {
            Column({ space: 12 }) {
              Text(this.error).fontSize(14).fontColor(ThemeManager.danger)
              Button(Translations.t('retry'))
                .fontSize(14)
                .backgroundColor(ThemeManager.primary)
                .fontColor('#FFFFFF')
                .onClick(() => { this.loadPage(1, true); })
            }
            .layoutWeight(1).justifyContent(FlexAlign.Center)
          } else {
            this.comicRows()
          }
        }
        .width('100%').height('100%')
        .backgroundColor(ThemeManager.background)
      }, (v: number) => `theme-${v}`)
    }
    .hideTitleBar(true)
    .backgroundColor(this.themeVersion >= 0 ? ThemeManager.background : '')
  }
}
