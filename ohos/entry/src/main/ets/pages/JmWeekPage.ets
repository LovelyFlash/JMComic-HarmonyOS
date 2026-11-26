// pages/JmWeekPage.ets - 禁漫每周必看（周分类 × 类型 单页网格）- NavDestination
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { NetworkImage } from '../components/NetworkImage';
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
  /** LazyForEach 数据源必须固定实例；刷新只走 replaceAll/clearData */
  private dataSource: ArrayDataSource<Comic> = new ArrayDataSource<Comic>()
  @State itemCount: number = 0
  @State catLoading: boolean = true
  @State catError: string = ''
  @State loading: boolean = false
  @State error: string = ''
  
  @StorageProp('topAvoidHeight') topAvoid: number = 0
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

  private categoryOptions(): SelectOption[] {
    const opts: SelectOption[] = [];
    for (let i = 0; i < this.categories.length; i++) {
      opts.push({ value: this.categories[i].label });
    }
    return opts;
  }

  private categoryIndex(): number {
    for (let i = 0; i < this.categories.length; i++) {
      if (this.categories[i].id === this.currentId) {
        return i;
      }
    }
    return 0;
  }

  private currentCategoryLabel(): string {
    return this.categories.length > 0 ? this.categories[this.categoryIndex()].label : '';
  }

  /** 标题栏下拉按钮只显示期数（如「第265期」），完整年份与日期范围保留在下拉菜单中 */
  private currentCategoryShortLabel(): string {
    const label: string = this.currentCategoryLabel();
    const start: number = label.indexOf('第');
    const end: number = start >= 0 ? label.indexOf('期', start) : -1;
    return start >= 0 && end >= start ? label.substring(start, end + 1) : label;
  }

  private selectWeekCategory(index: number): void {
    if (index < 0 || index >= this.categories.length) {
      return;
    }
    const cat: JmWeekCategory = this.categories[index];
    if (cat.id !== this.currentId) {
      this.currentId = cat.id;
      this.loadComics();
    }
  }

  private typeOptions(): SelectOption[] {
    const types: WeekType[] = this.makeTypes();
    const opts: SelectOption[] = [];
    for (let i = 0; i < types.length; i++) {
      opts.push({ value: Translations.t(types[i].labelKey) });
    }
    return opts;
  }

  private typeIndex(): number {
    const types: WeekType[] = this.makeTypes();
    for (let i = 0; i < types.length; i++) {
      if (types[i].key === this.currentType) {
        return i;
      }
    }
    return 0;
  }

  private currentTypeLabel(): string {
    const types: WeekType[] = this.makeTypes();
    const idx: number = this.typeIndex();
    return types.length > 0 ? Translations.t(types[idx].labelKey) : '';
  }

  private selectWeekType(index: number): void {
    const types: WeekType[] = this.makeTypes();
    if (index < 0 || index >= types.length) {
      return;
    }
    const type: WeekType = types[index];
    if (type.key !== this.currentType) {
      this.currentType = type.key;
      this.loadComics();
    }
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
      const list: Comic[] = await JmApi.getWeekComics(this.currentId, this.currentType);
      this.dataSource.replaceAll(list);
      this.itemCount = list.length;
    } catch (e) {
      this.error = String(e);
      this.dataSource.clearData();
      this.itemCount = 0;
    }
    this.loading = false;
  }

  /** 期数选择：作为 .title 自定义标题的一部分，位于标题文字右侧 */
  @Builder
  weekCategorySelect() {
    if (this.categories.length > 0) {
      // 与 SettingsPage 的 SettingSelect 下拉样式保持一致：无胶囊底色，14fp 次要文字色
      Select(this.categoryOptions())
        .selected(this.categoryIndex())
        .value(this.currentCategoryShortLabel())
        .font({ size: 14 })
        .fontColor($r('app.color.text_secondary'))
        .selectedOptionFontColor(this.themeColor)
        .optionFontColor($r('app.color.text_primary'))
        .menuBackgroundColor($r('app.color.bg_elevated'))
        .menuAlign(MenuAlignType.END)
        .height(28)
        .constraintSize({ maxWidth: 112 })
        .onSelect((index: number) => {
          this.selectWeekCategory(index);
        })
    }
  }

  /** 分类选择：全部 / 韩漫 / 日漫 / 其它，同样放在 .title 内 */
  @Builder
  weekTypeSelect() {
    Select(this.typeOptions())
      .selected(this.typeIndex())
      .value(this.currentTypeLabel())
      .font({ size: 14 })
      .fontColor($r('app.color.text_secondary'))
      .selectedOptionFontColor(this.themeColor)
      .optionFontColor($r('app.color.text_primary'))
      .menuBackgroundColor($r('app.color.bg_elevated'))
      .menuAlign(MenuAlignType.END)
      .height(28)
      .constraintSize({ maxWidth: 80 })
      .onSelect((index: number) => {
        this.selectWeekType(index);
      })
  }

  /** 标题栏右侧菜单区：由系统标题栏承载，两个下拉共享系统菜单背板材质 */
  @Builder
  weekSelectors() {
    Row({ space: 8 }) {
      this.weekCategorySelect()
      this.weekTypeSelect()
    }
    .height(56)
    // 菜单区默认贴屏幕右缘，补 16vp 右边距；高度对齐标题栏，使下拉中心与返回键中心一致
    .padding({ right: 16 })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  comicRows() {
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
        .id('jmWeekComic' + comic.id)
      }, (comic: Comic) => comic.id)
    }
    .layoutWeight(1)
    .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(BarState.Off)
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
    .contentStartOffset(this.topAvoid + 56)
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
            } else if (this.itemCount === 0) {
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
        // STACK 标题栏悬浮在内容之上：内容从状态栏下方 + 标题栏高度之后开始，避免被标题栏遮挡
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .title(Translations.t('week_recommendation'), {
      barStyle: BarStyle.STACK,
      scrollEffectOptions: {
        scrollEffectType: ScrollEffectType.GRADUAL_BLUR }
    })
    .menus(this.weekSelectors())
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .hideTitleBar(false)
    .backgroundColor($r('app.color.bg_page'))
  }
}
