// pages/JmPromotePage.ets - 禁漫主页分区漫画分页（/promote_list）- NavDestination
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { Comic } from '../data/model/Comic';
import { JmApi } from '../data/api/JmApi';
import { ArrayDataSource } from '../common/ArrayDataSource';
import { NavTitleBar } from '../components/NavTitleBar';

@Builder
export function JmPromotePageBuilder(name: string, param: object) {
  JmPromotePage({ pageParam: param })
}

@Component
export struct JmPromotePage {
  pageParam: object | undefined = undefined;
  promoteId: string = '';
  promoteTitle: string = ''
  @State dataSource: ArrayDataSource<Comic> = new ArrayDataSource<Comic>()
  @State loading: boolean = true
  @State loadingMore: boolean = false
  @State error: string = ''
  @State currentPage: number = 1
  @State maxPage: number = 1
  
  @StorageProp('themeColor') themeColor: string = '#2563EB'

  aboutToAppear(): void {
    if (this.pageParam !== undefined && this.pageParam !== null) {
      const params = this.pageParam as Record<string, Object>;
      this.promoteId = params['id'] !== undefined && params['id'] !== null ? String(params['id']) : '';
      this.promoteTitle = params['title'] !== undefined && params['title'] !== null ? String(params['title']) : '';
    }
    this.loadPage(1, true);
  }

  async loadPage(page: number, replace: boolean): Promise<void> {
    if (replace) {
      this.loading = true;
      this.error = '';
    }
    try {
      const result = await JmApi.getPromoteList(this.promoteId, page);
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
        .id('jmPromoteComic' + comic.id)
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
    .id('jmPromoteComicRows')
  }

  build() {
    NavDestination() {
      
        Column({ space: 0 }) {
          NavTitleBar({ title: this.promoteTitle })
          if (this.loading) {
            Column() {
              LoadingProgress().width(40).height(40)
            }
            .layoutWeight(1).justifyContent(FlexAlign.Center)
          } else if (this.error.length > 0) {
            Column({ space: 12 }) {
              Text(this.error).fontSize(14).fontColor($r('app.color.danger'))
              Button(Translations.t('retry'))
                .fontSize(14)
                .backgroundColor(this.themeColor)
                .fontColor($r('app.color.text_on_brand'))
                .onClick(() => { this.loadPage(1, true); })
            }
            .layoutWeight(1).justifyContent(FlexAlign.Center)
          } else {
            this.comicRows()
          }
        }
        .width('100%').height('100%')
        .backgroundColor($r('app.color.bg_page'))
      
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_page'))
  }
}
