// pages/JmWeekPage.ets - 禁漫每周必看（周分类 × 类型 单页网格）- NavDestination
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { Comic } from '../data/model/Comic';
import { JmApi, JmWeekCategory } from '../data/api/JmApi';
import { NavTitleBar } from '../components/NavTitleBar';

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
  @State comics: Comic[] = []
  @State catLoading: boolean = true
  @State catError: string = ''
  @State loading: boolean = false
  @State error: string = ''
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @StorageLink('themeVersion') themeVersion: number = 0

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
      this.comics = await JmApi.getWeekComics(this.currentId, this.currentType);
    } catch (e) {
      this.error = String(e);
      this.comics = [];
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
            .fontColor(this.currentId === cat.id ? '#FFFFFF' : ThemeManager.textSecondary)
            .backgroundColor(this.currentId === cat.id ? ThemeManager.primary : ThemeManager.surface)
            .onClick(() => {
              if (this.currentId !== cat.id) {
                this.currentId = cat.id;
                this.loadComics();
              }
            })
            .id('cat' + cat.id + this.themeVersion)
        }, (cat: JmWeekCategory) => cat.id)
      }
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .id('categoryChips' + this.themeVersion)
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
            .fontColor(this.currentType === t.key ? '#FFFFFF' : ThemeManager.textSecondary)
            .backgroundColor(this.currentType === t.key ? ThemeManager.primary : ThemeManager.surface)
            .onClick(() => {
              if (this.currentType !== t.key) {
                this.currentType = t.key;
                this.loadComics();
              }
            })
            .id('type' + t.key + this.themeVersion)
        }, (t: WeekType) => t.key)
      }
      .padding({ left: 16, right: 16, bottom: 8 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .id('typeChips' + this.themeVersion)
  }

  @Builder
  comicRows() {
    List({ space: 1 }) {
      ForEach(this.comics, (comic: Comic) => {
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
    }
    .layoutWeight(1)
    .divider({ strokeWidth: 0.5, color: ThemeManager.divider })
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .id('comicRows' + this.themeVersion)
  }

  build() {
    NavDestination() {
      ForEach([this.themeVersion], (v: number) => {
        Column({ space: 0 }) {
          NavTitleBar({ title: Translations.t('week_recommendation') })
          if (this.catLoading) {
            Column() {
              LoadingProgress().width(40).height(40)
            }
            .layoutWeight(1).justifyContent(FlexAlign.Center)
          } else if (this.catError.length > 0) {
            Column({ space: 12 }) {
              Text(this.catError).fontSize(14).fontColor(ThemeManager.danger)
              Button(Translations.t('retry'))
                .fontSize(14)
                .backgroundColor(ThemeManager.primary)
                .fontColor('#FFFFFF')
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
                Text(this.error).fontSize(14).fontColor(ThemeManager.danger)
                Button(Translations.t('retry'))
                  .fontSize(14)
                  .backgroundColor(ThemeManager.primary)
                  .fontColor('#FFFFFF')
                  .onClick(() => { this.loadComics(); })
              }
              .layoutWeight(1).justifyContent(FlexAlign.Center)
            } else if (this.comics.length === 0) {
              Column({ space: 8 }) {
                Text(Translations.t('no_data'))
                  .fontSize(14).fontColor(ThemeManager.textSecondary)
              }
              .layoutWeight(1).justifyContent(FlexAlign.Center)
            } else {
              this.comicRows()
            }
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
