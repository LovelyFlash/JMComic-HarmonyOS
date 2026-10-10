// pages/DiscoverPage.ets - 发现页（禁漫主页分区 + 最新 双模式）
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { Comic } from '../data/model/Comic';
import { JmApi, JmHomeSection } from '../data/api/JmApi';
import { NetworkImage } from '../components/NetworkImage';
import { ArrayDataSource } from '../common/ArrayDataSource';
import { DEFAULT_THEME_COLOR } from '../common/Constants';
import { SymbolGlyphModifier, uiMaterial } from '@kit.ArkUI';

@Component
export struct DiscoverPage {
  @State mode: number = 0
  // 主页模式
  @State homeSource: ArrayDataSource<JmHomeSection> = new ArrayDataSource<JmHomeSection>()
  @State homeLoading: boolean = false
  @State homeError: string = ''
  @State homeRefreshing: boolean = false
  // 最新模式
  @State latestSource: ArrayDataSource<Comic> = new ArrayDataSource<Comic>()
  @State loading: boolean = false
  @State loadingMore: boolean = false
  @State refreshing: boolean = false
  @State error: string = ''
  @State page: number = 1
  @State hasMore: boolean = true
  
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR

  aboutToAppear(): void {
    this.loadHome();
  }

  private switchMode(idx: number): void {
    if (this.mode === idx) {
      return;
    }
    this.mode = idx;
    if (idx === 0 && this.homeSource.totalCount() === 0 && !this.homeLoading) {
      this.loadHome();
    } else if (idx === 1 && this.latestSource.totalCount() === 0 && !this.loading) {
      this.loadLatest(true);
    }
  }

  private async loadHome(): Promise<void> {
    this.homeLoading = true;
    this.homeError = '';
    try {
      this.homeSource = new ArrayDataSource<JmHomeSection>(await JmApi.getHomePage());
    } catch (e) {
      this.homeError = String(e);
      this.homeSource = new ArrayDataSource<JmHomeSection>();
    }
    this.homeLoading = false;
    this.homeRefreshing = false;
  }

  private async loadLatest(reset: boolean): Promise<void> {
    if (reset) {
      this.loading = true;
      this.error = '';
      this.page = 1;
      this.hasMore = true;
    }
    try {
      const items = await JmApi.getLatest(1);
      this.latestSource = new ArrayDataSource<Comic>(items);
      this.page = 1;
      this.hasMore = items.length > 0;
    } catch (e) {
      if (reset) {
        this.error = String(e);
        this.latestSource = new ArrayDataSource<Comic>();
      }
    }
    this.loading = false;
    this.refreshing = false;
  }

  private async loadMore(): Promise<void> {
    if (this.loading || this.loadingMore || !this.hasMore || this.error.length > 0) {
      return;
    }
    this.loadingMore = true;
    try {
      const items = await JmApi.getLatest(this.page + 1);
      const existing: Set<string> = new Set<string>();
      const current: Comic[] = this.latestSource.getAllData();
      for (let i = 0; i < current.length; i++) {
        existing.add(current[i].id);
      }
      const added: Comic[] = [];
      for (let i = 0; i < items.length; i++) {
        if (!existing.has(items[i].id)) {
          added.push(items[i]);
        }
      }
      if (added.length > 0) {
        this.latestSource.addAll(added);
        this.page = this.page + 1;
      } else {
        this.hasMore = false;
      }
    } catch (e) {
      this.hasMore = false;
    }
    this.loadingMore = false;
  }

  private gotoDetail(comic: Comic): void {
    const param: Record<string, Object> = {
      'comicId': comic.id, 'title': comic.title, 'source': 'jm'
    };
    NavUtil.push('comicDetail', param);
  }





  @Builder
  homeSectionItem(section: JmHomeSection) {
    Column({ space: 10 }) {
      Row() {
        Text(section.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .layoutWeight(1)
        Text(Translations.t('view_more'))
          .fontSize(13)
          .fontColor(this.themeColor)
          .onClick(() => {
            const param: Record<string, Object> = { 'id': section.id, 'title': section.title };
            NavUtil.push('jmPromote', param);
          })
      }
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      .width('100%')

      Scroll() {
        Row({ space: 10 }) {
          ForEach(section.comics, (comic: Comic) => {
            Column({ space: 6 }) {
              NetworkImage({ url: comic.coverUrl, imgWidth: 96, imgHeight: 128, imgBorderRadius: 8 })
                .onClick(() => { this.gotoDetail(comic); })
              Text(comic.title)
                .fontSize(12)
                .fontColor($r('app.color.text_primary'))
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width(96)
                .textAlign(TextAlign.Start)
            }
            .alignItems(HorizontalAlign.Start)
            .id('sectionItem' + comic.id)
          }, (comic: Comic) => comic.id)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    }
    .width('100%')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .padding({ left: 16, right: 16, top: 6, bottom: 6 })
    .id('discoverSection' + section.id)
  }

  @Builder
  homeBody() {
    Refresh({ refreshing: $$this.homeRefreshing, offset: 64, friction: 100 }) {
      List({ space: 16 }) {
        LazyForEach(this.homeSource, (section: JmHomeSection) => {
          ListItem() {
            this.homeSectionItem(section)
          }
        }, (section: JmHomeSection) => section.id + section.title)
      }
      .scrollBar(BarState.Off)
      .contentStartOffset(56)
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .layoutWeight(1)
    .onRefreshing(() => { this.loadHome(); })
  }

  @Builder
  homeContent() {
    if (this.homeLoading) {
      Column() {
        LoadingProgress().width(40).height(40)
      }
      .layoutWeight(1).justifyContent(FlexAlign.Center)
    } else if (this.homeError.length > 0) {
      Column({ space: 12 }) {
        Text(this.homeError).fontSize(14).fontColor($r('app.color.danger'))
        Button(Translations.t('retry')).fontSize(14).backgroundColor(this.themeColor).fontColor($r('app.color.text_on_brand'))
          .onClick(() => { this.loadHome(); })
      }
      .layoutWeight(1).justifyContent(FlexAlign.Center)
      .id('homeError')
    } else {
      this.homeBody()
    }
  }

  @Builder
  latestList() {
    Refresh({ refreshing: $$this.refreshing, offset: 64, friction: 100 }) {
      List({ space: 1 }) {
        LazyForEach(this.latestSource, (comic: Comic) => {
          ListItem() {
            Row({ space: 12 }) {
              NetworkImage({ url: comic.coverUrl, imgWidth: 80, imgHeight: 110, imgBorderRadius: 6 })
              Column({ space: 6 }) {
                Text(comic.title)
                  .fontSize(15).fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                  .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                  .width('100%')
                if (comic.author.length > 0) {
                  Text(comic.author)
                    .fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
                    .maxLines(1)
                }
              }
              .layoutWeight(1).alignItems(HorizontalAlign.Start)
            }
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
            .width('100%').padding(12)
            .onClick(() => { this.gotoDetail(comic); })
            .id('latestComic' + comic.id)
          }
        }, (comic: Comic) => comic.id)

        ListItem() {
          if (this.loadingMore) {
            Column({ space: 8 }) {
              LoadingProgress().width(32).height(32)
            }
            .width('100%').height(48).justifyContent(FlexAlign.Center)
          }
        }
      }
      .layoutWeight(1)
      .contentStartOffset(56)
      .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
      .edgeEffect(EdgeEffect.Spring)
      .onReachEnd(() => { this.loadMore(); })
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    }
    .layoutWeight(1)
    .onRefreshing(() => { this.loadLatest(true); })
    .id('latestList')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
  }

  @Builder
  latestContent() {
    if (this.loading) {
      Column() {
        LoadingProgress().width(40).height(40)
      }
      .layoutWeight(1).justifyContent(FlexAlign.Center)
    } else if (this.error.length > 0) {
      Column({ space: 12 }) {
        Text(this.error).fontSize(14).fontColor($r('app.color.danger'))
        Button(Translations.t('retry')).fontSize(14).backgroundColor(this.themeColor).fontColor($r('app.color.text_on_brand'))
          .onClick(() => { this.loadLatest(true); })
      }
      .layoutWeight(1).justifyContent(FlexAlign.Center)
      .id('latestError')
    } else {
      this.latestList()
    }
  }

  @Builder
  titleSwitcher() {
    Row({ space: 4 }) {
      this.titleSegment(Translations.t('explore_home'), 0)
      this.titleSegment(Translations.t('explore_latest'), 1)
    }
    .alignItems(VerticalAlign.Center)
    .padding({ left: 16, top: 13 })
  }

  @Builder
  titleSegment(label: string, idx: number) {
    Button(label)
      .type(ButtonType.Normal)
      .fontSize(15)
      .fontWeight(this.mode === idx ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(this.mode === idx ? $r('app.color.text_on_brand') : $r('app.color.text_secondary'))
      .backgroundColor(this.mode === idx ? this.themeColor : Color.Transparent)
      .constraintSize({ minHeight: 0 })
      .height(32)
      .padding({ left: 14, right: 14 })
      .borderRadius(16)
      .onClick(() => { this.switchMode(idx); })
  }

  private refreshCurrent(): void {
    if (this.mode === 0) {
      this.loadHome();
    } else {
      this.loadLatest(true);
    }
  }

  build() {
    NavDestination() {
      Column() {
        if (this.mode === 0) {
          this.homeContent()
        } else {
          this.latestContent()
        }
      }
      .width('100%')
      .height('100%')
    }
    .title(this.titleSwitcher(), {
      barStyle: BarStyle.STACK,
      scrollEffectOptions: {
        scrollEffectType: ScrollEffectType.GRADUAL_BLUR },
    })
    .menus([
      {
        value: Translations.t('refresh'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        action: () => { this.refreshCurrent(); }
      }
    ])
    .hideBackButton(true)
    .backgroundColor($r('app.color.bg_page'))
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    }))
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
  }
}
