// pages/JmWeekPage.ets - 禁漫每周必看（周分类 × 类型 单页网格）- NavDestination
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { Comic } from '../data/model/Comic';
import { JmApi, JmWeekCategory } from '../data/api/JmApi';
import { ArrayDataSource } from '../common/ArrayDataSource';
import { DEFAULT_THEME_COLOR } from '../common/Constants';
import { uiMaterial } from '@kit.ArkUI';

class WeekType {
  key: string = '';
  labelKey: string = '';
  constructor(key: string, labelKey: string) {
    this.key = key;
    this.labelKey = labelKey;
  }
}

@Builder
export function JmWeekPageBuilder(name: string, param: object) {
  JmWeekPage()
}

@Component
export struct JmWeekPage {
  @State categories: JmWeekCategory[] = []
  @State currentId: string = ''
  @State currentType: string = ''
  @State dataSource: ArrayDataSource<Comic> = new ArrayDataSource<Comic>()
  @State catLoading: boolean = true
  @State catError: string = ''
  @State loading: boolean = false
  @State error: string = ''
  
  @StorageProp('bottomAvoidHeight') bottomAvoid: number = 0
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR

  aboutToAppear(): void {
    this.loadCategories();
  }

  private makeTypes(): WeekType[] {
    const list: WeekType[] = [];
    list.push(new WeekType('', 'all_types'));
    list.push(new WeekType('hanman', 'type_hanman'));
    list.push(new WeekType('manga', 'type_manga'));
    list.push(new WeekType('another', 'type_another'));
    return list;
  }

  private async loadCategories(): Promise<void> {
    this.catLoading = true;
    this.catError = '';
    try {
      const cats = await JmApi.getWeekCategories();
      this.categories = cats;
      if (cats.length > 0) {
        this.currentId = cats[0].id;
        this.loadComics();
      }
    } catch (e) {
      this.catError = String(e);
      this.categories = [];
    }
    this.catLoading = false;
  }

  private async loadComics(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      this.dataSource = new ArrayDataSource<Comic>(await JmApi.getWeekComics(this.currentId, this.currentType));
    } catch (e) {
      this.error = String(e);
      this.dataSource = new ArrayDataSource<Comic>();
    }
    this.loading = false;
  }

  @Builder
  categoryChips() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.categories, (cat: JmWeekCategory) => {
          Text(cat.label)
            .fontSize(13)
            .padding({ left: 14, right: 14, top: 7, bottom: 7 })
            .borderRadius(16)
            .fontColor(this.currentId === cat.id ? $r('app.color.text_on_brand') : $r('app.color.text_secondary'))
            .backgroundColor(this.currentId === cat.id ? this.themeColor : $r('app.color.bg_fill'))
            .onClick(() => {
              if (this.currentId !== cat.id) {
                this.currentId = cat.id;
                this.loadComics();
              }
            })
            .id('cat' + cat.id)
        }, (cat: JmWeekCategory) => cat.id)
      }
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .id('categoryChips')
  }

  @Builder
  typeChips() {
    Scroll() {
      Row({ space: 8 }) {
        ForEach(this.makeTypes(), (t: WeekType) => {
          Text(Translations.t(t.labelKey))
            .fontSize(12)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(14)
            .fontColor(this.currentType === t.key ? $r('app.color.text_on_brand') : $r('app.color.text_secondary'))
            .backgroundColor(this.currentType === t.key ? this.themeColor : $r('app.color.bg_fill'))
            .onClick(() => {
              if (this.currentType !== t.key) {
                this.currentType = t.key;
                this.loadComics();
              }
            })
            .id('type' + t.key)
        }, (t: WeekType) => t.key)
      }
      .padding({ left: 16, right: 16, bottom: 8 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .id('typeChips')
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
        .id('jmWeekComic' + comic.id)
      }, (comic: Comic) => comic.id)
    }
    .layoutWeight(1)
    .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
    .padding({ bottom: this.bottomAvoid })
    .id('jmWeekComicRows')
  }

  build() {
    NavDestination() {
      
        Column({ space: 0 }) {
          if (this.catLoading) {
            Column() {
              LoadingProgress().width(40).height(40)
            }
            .layoutWeight(1).justifyContent(FlexAlign.Center)
          } else if (this.catError.length > 0) {
            Column({ space: 12 }) {
              Text(this.catError).fontSize(14).fontColor($r('app.color.danger'))
              Button(Translations.t('retry'))
                .fontSize(14)
                .backgroundColor(this.themeColor)
                .fontColor($r('app.color.text_on_brand'))
                .onClick(() => { this.loadCategories(); })
            }
            .layoutWeight(1).justifyContent(FlexAlign.Center)
          } else {
            this.categoryChips()
            this.typeChips()
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
                  .onClick(() => { this.loadComics(); })
              }
              .layoutWeight(1).justifyContent(FlexAlign.Center)
            } else if (this.dataSource.totalCount() === 0) {
              Column({ space: 8 }) {
                Text(Translations.t('no_data'))
                  .fontSize(14).fontColor($r('app.color.text_secondary'))
              }
              .layoutWeight(1).justifyContent(FlexAlign.Center)
            } else {
              this.comicRows()
            }
          }
        }
        .width('100%').height('100%')
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .title(Translations.t('week_recommendation'), { backgroundColor: $r('app.color.bg_page') })
    .hideTitleBar(false)
    .backgroundColor($r('app.color.bg_page'))
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    }))
  }
}
