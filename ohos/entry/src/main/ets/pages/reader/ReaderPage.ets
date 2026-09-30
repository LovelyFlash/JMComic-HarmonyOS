// pages/reader/ReaderPage.ets - 阅读器（6 阅读模式 + 手势缩放 + bindSheet 设置/章节 + 续读 + 进度保存）- NavDestination
import { window } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { inputConsumer, KeyCode, KeyEvent } from '@kit.InputKit';
import { Translations } from '../../common/Translations';
import { NavUtil } from '../../common/NavUtil';
import { ReadingConfig } from '../../common/ReadingConfig';
import { Database, ReadingProgress } from '../../data/database/Database';
import { ReaderParam } from '../../data/model/ReaderParam';
import { Chapter } from '../../data/model/Chapter';
import { JmApi } from '../../data/api/JmApi';
import { Logger } from '../../common/Logger';
import { ReaderImage, ReaderImageCache } from '../../components/ReaderImage';
import { ArrayDataSource } from '../../common/ArrayDataSource';

const MAX_ZOOM = 4.0;
const DOUBLE_TAP_ZOOM = 2.5;
const ZOOM_RESET_THRESHOLD = 1.05;
/** 侧边页码条：轨道与滑块尺寸（vp） */
const SIDE_TRACK: number = 280;
const SIDE_THUMB: number = 36;
/** 自动翻页可选间隔（秒） */
const AUTO_TIMES: number[] = [3, 5, 8, 10, 15];

@Builder
export function ReaderPageBuilder(name: string, param: object) {
  ReaderPage({ pageParam: param })
}

@Component
export struct ReaderPage {
  pageParam: object | undefined = undefined;
  comicId: string = '';
  source: string = '';
  title: string = '';
  @State images: string[] = [];
  @State chapters: Chapter[] = [];
  @State currentChapterOrder: number = 0;
  @State currentIndex: number = 0;
  @State showToolbar: boolean = false;
  @State showSheet: boolean = false;
  sheetMode: string = 'settings';
  @State loadingChapter: boolean = false;
  // 阅读配置
  @State readMode: number = 2;
  @State tapTurnPage: boolean = true;
  @State invertTap: boolean = false;
  @State showPageInfo: boolean = true;
  @State pageAnimation: boolean = true;
  @State imageLayout: number = 0;
  @State keepScreenOn: boolean = false;
  @State doubleTapZoom: boolean = true;
  @State longPressZoom: boolean = true;
  @State volumeKeyTurnPage: boolean = true;
  @State sidePageTurn: boolean = false;
  @State imageQuality: number = 0;
  @State autoPageTime: number = 5;
  @State autoPlay: boolean = false;
  // 缩放
  @State zoomScale: number = 1.0;
  private pinchBaseScale: number = 1.0;
  // LazyForEach 数据源（构建一次，章节/模式切换时 replaceAll）
  private singleDS: ArrayDataSource<string> = new ArrayDataSource<string>();
  private dualDS: ArrayDataSource<number> = new ArrayDataSource<number>();
  private stripDS: ArrayDataSource<string> = new ArrayDataSource<string>();
  private stripScroller: Scroller = new Scroller();
  // 音量键翻页订阅
  private volumeUpOptions: inputConsumer.KeyPressedConfig = {
    key: KeyCode.KEYCODE_VOLUME_UP,
    action: 1,
    isRepeat: false
  };
  private volumeDownOptions: inputConsumer.KeyPressedConfig = {
    key: KeyCode.KEYCODE_VOLUME_DOWN,
    action: 1,
    isRepeat: false
  };
  private volumeUpCallback: (event: KeyEvent) => void = () => {
  };
  private volumeDownCallback: (event: KeyEvent) => void = () => {
  };
  private volumeRegistered: boolean = false;
  // 自动翻页定时器
  private autoTimer: number = -1;
  // 侧边页码条拖动基准（PanGesture offset 为相对手势起点的位移）
  private sideBarDragBase: number = 0;
  private sideBarDragOffset: number = 0;
  
  @StorageProp('themeColor') themeColor: string = '#2563EB'
  @StorageProp('topAvoidHeight') topAvoid: number = 0
  @StorageProp('bottomAvoidHeight') bottomAvoid: number = 0

  aboutToAppear(): void {
    if (this.pageParam !== undefined && this.pageParam !== null) {
      const p = this.pageParam as ReaderParam;
      this.comicId = p.comicId;
      this.source = p.source;
      this.title = p.title;
      this.images = p.images;
      this.chapters = p.chapters;
      this.currentChapterOrder = p.currentChapterOrder;
    }
    this.refreshDataSources();
    this.loadConfig().then(() => {
      // 等配置加载完再预取，保证按正确质量档解码
      this.preloadAround(this.currentIndex);
      this.restoreProgress();
    });
  }

  aboutToDisappear(): void {
    this.saveProgress();
    this.setKeepScreenOn(false);
    this.stopAutoPlay();
    this.unregisterVolumeKey();
  }

  private async loadConfig(): Promise<void> {
    await ReadingConfig.load();
    this.readMode = ReadingConfig.readMode;
    this.tapTurnPage = ReadingConfig.tapTurnPage;
    this.invertTap = ReadingConfig.invertTap;
    this.showPageInfo = ReadingConfig.showPageInfo;
    this.pageAnimation = ReadingConfig.pageAnimation;
    this.imageLayout = ReadingConfig.imageLayout;
    this.keepScreenOn = ReadingConfig.keepScreenOn;
    this.doubleTapZoom = ReadingConfig.doubleTapZoom;
    this.longPressZoom = ReadingConfig.longPressZoom;
    this.volumeKeyTurnPage = ReadingConfig.volumeKeyTurnPage;
    this.sidePageTurn = ReadingConfig.sidePageTurn;
    this.imageQuality = ReadingConfig.imageQuality;
    this.autoPageTime = ReadingConfig.autoPageTime;
    this.setKeepScreenOn(this.keepScreenOn);
    this.updateVolumeKeySubscription();
  }

  // ---------- 音量键翻页（inputConsumer 优先响应系统功能键，API16+） ----------
  private updateVolumeKeySubscription(): void {
    if (this.volumeKeyTurnPage && !this.volumeRegistered) {
      this.volumeUpCallback = (_event: KeyEvent) => {
        if (this.showSheet || this.loadingChapter) {
          return;
        }
        this.prevPage();
      };
      this.volumeDownCallback = (_event: KeyEvent) => {
        if (this.showSheet || this.loadingChapter) {
          return;
        }
        this.nextPage();
      };
      try {
        inputConsumer.on('keyPressed', this.volumeUpOptions, this.volumeUpCallback);
        inputConsumer.on('keyPressed', this.volumeDownOptions, this.volumeDownCallback);
        this.volumeRegistered = true;
      } catch (e) {
        Logger.warn('ReaderPage', `volume key subscribe failed: ${String(e)}`);
        this.volumeRegistered = false;
      }
    } else if (!this.volumeKeyTurnPage && this.volumeRegistered) {
      this.unregisterVolumeKey();
    }
  }

  private unregisterVolumeKey(): void {
    if (!this.volumeRegistered) {
      return;
    }
    this.volumeRegistered = false;
    try {
      inputConsumer.off('keyPressed', this.volumeUpCallback);
      inputConsumer.off('keyPressed', this.volumeDownCallback);
    } catch (e) {
      Logger.warn('ReaderPage', `volume key unsubscribe failed: ${String(e)}`);
    }
  }

  // ---------- 自动翻页 ----------
  private toggleAutoPlay(): void {
    if (this.autoPlay) {
      this.stopAutoPlay();
      return;
    }
    this.autoPlay = true;
    this.showToolbar = false;
    const interval: number = Math.max(1, this.autoPageTime) * 1000;
    this.autoTimer = setInterval(() => {
      if (this.showSheet || this.loadingChapter) {
        return;
      }
      if (this.currentIndex >= this.images.length - 1 && this.nextChapterOrder() === 0) {
        // 漫画末页：自动翻页停止
        this.stopAutoPlay();
        return;
      }
      this.nextPage();
    }, interval);
  }

  private stopAutoPlay(): void {
    if (this.autoTimer >= 0) {
      clearInterval(this.autoTimer);
      this.autoTimer = -1;
    }
    this.autoPlay = false;
  }

  private restartAutoPlayIfOn(): void {
    if (this.autoPlay) {
      this.stopAutoPlay();
      this.toggleAutoPlay();
    }
  }

  private async setKeepScreenOn(on: boolean): Promise<void> {
    try {
      const win = await window.getLastWindow(getContext(this));
      await win.setWindowKeepScreenOn(on);
    } catch (e) {
      Logger.error('ReaderPage', `setKeepScreenOn failed: ${String(e)}`);
    }
  }

  private async restoreProgress(): Promise<void> {
    if (this.comicId.length === 0 || this.source.length === 0) {
      return;
    }
    const progress: ReadingProgress = await Database.getReadingProgress(this.comicId, this.source);
    const chapterMatches: boolean = this.chapters.length === 0 ||
      progress.lastChapter.length === 0 || Number(progress.lastChapter) === this.currentChapterOrder;
    if (progress.lastPage > 0 && progress.lastPage < this.images.length && chapterMatches) {
      const page: number = progress.lastPage;
      this.getUIContext().showAlertDialog({
        title: Translations.t('resume_reading'),
        message: `${Translations.t('resume_hint_prefix')}${page + 1}${Translations.t('resume_hint_suffix')}`,
        primaryButton: {
          value: Translations.t('from_start'),
          action: () => {
            this.navigateToIndex(0);
            this.saveProgress();
          }
        },
        secondaryButton: {
          value: Translations.t('resume_reading'),
          fontColor: this.themeColor,
          action: () => {
            this.navigateToIndex(page);
          }
        }
      });
    }
  }

  private async saveProgress(): Promise<void> {
    if (this.comicId.length === 0 || this.source.length === 0) {
      return;
    }
    const chapter: string = this.chapters.length > 0 ? String(this.currentChapterOrder) : '';
    await Database.updateReadingProgress(this.comicId, this.source, chapter, this.currentIndex);
  }

  // ---------- 模式判定与数据映射 ----------
  private isRtl(): boolean {
    return this.readMode === 1;
  }

  private isDual(): boolean {
    return this.readMode === 4 || this.readMode === 5;
  }

  /** 连续滚动（列表模式，无缩放无翻页动画） */
  private isStrip(): boolean {
    return this.readMode === 3;
  }

  /** 从上至下：纵向分页 Swiper */
  private isVerticalPaging(): boolean {
    return this.readMode === 2;
  }

  /** 纵向点按分区（TTB/连续）：上=上一页，下=下一页 */
  private isVerticalZones(): boolean {
    return this.readMode === 2 || this.readMode === 3;
  }

  private toDisplay(real: number): number {
    return this.isRtl() ? this.images.length - 1 - real : real;
  }

  private toReal(display: number): number {
    return this.isRtl() ? this.images.length - 1 - display : display;
  }

  /** 章节/模式切换后重建 LazyForEach 数据源（RTL 反转仅作用于单页数据源） */
  private refreshDataSources(): void {
    const singleArr: string[] = [];
    if (this.isRtl()) {
      for (let i = this.images.length - 1; i >= 0; i--) {
        singleArr.push(this.images[i]);
      }
    } else {
      for (let i = 0; i < this.images.length; i++) {
        singleArr.push(this.images[i]);
      }
    }
    this.singleDS.replaceAll(singleArr);
    const dualArr: number[] = [];
    for (let i = 0; i < this.images.length; i += 2) {
      dualArr.push(i);
    }
    this.dualDS.replaceAll(dualArr);
    const stripArr: string[] = [];
    for (let i = 0; i < this.images.length; i++) {
      stripArr.push(this.images[i]);
    }
    this.stripDS.replaceAll(stripArr);
  }

  /** 预取当前页前后各 2 页（像素缓存命中时零开销） */
  private preloadAround(idx: number): void {
    if (this.images.length === 0) {
      return;
    }
    const targets: string[] = [];
    for (let d = 1; d <= 2; d++) {
      const after: number = idx + d;
      const before: number = idx - d;
      if (after < this.images.length) {
        targets.push(this.images[after]);
      }
      if (before >= 0) {
        targets.push(this.images[before]);
      }
    }
    if (targets.length > 0) {
      ReaderImageCache.preload(targets, this.imageQuality, this.getUIContext());
    }
  }

  /** 统一跳页入口：翻页模式驱动 Swiper.index 属性，连续模式驱动 Scroller */
  private navigateToIndex(target: number): void {
    const idx: number = Math.max(0, Math.min(target, this.images.length - 1));
    this.zoomScale = 1.0;
    this.currentIndex = idx;
    if (this.isStrip()) {
      this.stripScrollTo(idx);
    }
    this.preloadAround(idx);
  }

  /** 连续模式滚动到指定页（List 未创建时静默忽略，由 initialIndex 兜底） */
  private stripScrollTo(idx: number): void {
    try {
      this.stripScroller.scrollToIndex(idx, false);
    } catch (e) {
      Logger.warn('ReaderPage', `scrollToIndex failed: ${String(e)}`);
    }
  }

  /** 双页一次翻一“跨”（两页），单页/TTB 翻一页 */
  private pageStep(): number {
    return this.isDual() ? 2 : 1;
  }

  // ---------- 交互 ----------
  private resetZoom(): void {
    this.getUIContext().animateTo({ duration: 150, curve: Curve.FastOutSlowIn }, () => {
      this.zoomScale = 1.0;
    });
  }

  private handleDoubleTap(): void {
    if (!this.doubleTapZoom || this.readMode === 3) {
      return;
    }
    if (this.zoomScale > 1.0) {
      this.resetZoom();
    } else {
      this.getUIContext().animateTo({ duration: 200, curve: Curve.FastOutSlowIn }, () => {
        this.zoomScale = DOUBLE_TAP_ZOOM;
      });
    }
  }

  private toggleToolbar(): void {
    if (this.showSheet) {
      this.showSheet = false;
      return;
    }
    this.showToolbar = !this.showToolbar;
  }

  private prevPage(): void {
    if (this.currentIndex > 0) {
      this.navigateToIndex(this.currentIndex - this.pageStep());
      return;
    }
    // 首页：尝试上一章
    const prevOrder: number = this.prevChapterOrder();
    if (prevOrder > 0) {
      this.loadChapter(prevOrder, true);
    } else {
      promptAction.showToast({ message: Translations.t('start_of_chapter'), duration: 1200 });
    }
  }

  private nextPage(): void {
    if (this.currentIndex + this.pageStep() < this.images.length) {
      this.navigateToIndex(this.currentIndex + this.pageStep());
      return;
    }
    // 末页：尝试下一章
    const nextOrder: number = this.nextChapterOrder();
    if (nextOrder > 0) {
      this.loadChapter(nextOrder, false);
    } else {
      promptAction.showToast({ message: Translations.t('end_of_chapter'), duration: 1200 });
    }
  }

  private prevChapterOrder(): number {
    let result: number = 0;
    for (let i = 0; i < this.chapters.length; i++) {
      if (this.chapters[i].order < this.currentChapterOrder) {
        result = this.chapters[i].order;
      }
    }
    return result;
  }

  private nextChapterOrder(): number {
    for (let i = 0; i < this.chapters.length; i++) {
      if (this.chapters[i].order > this.currentChapterOrder) {
        return this.chapters[i].order;
      }
    }
    return 0;
  }

  private currentChapterTitle(): string {
    for (let i = 0; i < this.chapters.length; i++) {
      if (this.chapters[i].order === this.currentChapterOrder) {
        return this.chapters[i].title;
      }
    }
    return '';
  }

  private async loadChapter(order: number, startAtEnd: boolean): Promise<void> {
    if (this.loadingChapter) {
      return;
    }
    this.loadingChapter = true;
    try {
      // 按章节 order 找到章节 id（JM）
      let chapterId: string = this.comicId;
      for (let i = 0; i < this.chapters.length; i++) {
        if (this.chapters[i].order === order) {
          chapterId = this.chapters[i].id;
          break;
        }
      }
      const ch: Chapter = await JmApi.getChapter(chapterId);
      const imgs: string[] = ch.imageUrls;
      if (imgs.length > 0) {
        this.images = imgs;
        this.currentChapterOrder = order;
        this.currentIndex = startAtEnd ? imgs.length - 1 : 0;
        this.zoomScale = 1.0;
        this.showSheet = false;
        this.refreshDataSources();
        if (this.isStrip()) {
          this.stripScrollTo(this.currentIndex);
        }
        this.preloadAround(this.currentIndex);
        this.saveProgress();
        promptAction.showToast({ message: Translations.t('chapter_switched'), duration: 1200 });
      } else {
        promptAction.showToast({ message: Translations.t('no_images'), duration: 1200 });
      }
    } catch (e) {
      promptAction.showToast({ message: Translations.t('error'), duration: 1200 });
    }
    this.loadingChapter = false;
  }

  private onZoneTap(zone: number): void {
    if (this.showToolbar) {
      // 工具栏可见时任意点按关闭（对齐原版交互）
      this.showToolbar = false;
      return;
    }
    if (!this.tapTurnPage && zone !== 1) {
      return;
    }
    if (zone === 1) {
      this.toggleToolbar();
      return;
    }
    let goNext: boolean = zone === 2;
    if (this.invertTap) {
      goNext = !goNext;
    }
    if (this.isRtl()) {
      goNext = !goNext;
    }
    if (goNext) {
      this.nextPage();
    } else {
      this.prevPage();
    }
  }

  // ---------- 内容区 ----------
  @Builder
  pageImage(url: string, dual: boolean) {
    if (url.length > 0) {
      ReaderImage({ url: url, imageLayout: this.imageLayout, fill: true, dual: dual })
    } else {
      Column({ space: 8 }) {
        LoadingProgress().width(40).height(40).color('#FFFFFF')
      }
      .width('100%').height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#000000')
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    }
  }

  @Builder
  buildSingleSwiper() {
    Swiper() {
      LazyForEach(this.singleDS, (url: string, idx: number) => {
        Stack() {
          this.pageImage(url, false)
        }
        .width('100%').height('100%')
        .clip(true)
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
        .scale({
          x: idx === this.toDisplay(this.currentIndex) ? this.zoomScale : 1,
          y: idx === this.toDisplay(this.currentIndex) ? this.zoomScale : 1
        })
        .gesture(
          GestureGroup(GestureMode.Parallel,
            PinchGesture({ fingers: 2 })
              .onActionStart(() => {
                if (idx !== this.toDisplay(this.currentIndex)) {
                  return;
                }
                this.pinchBaseScale = this.zoomScale;
              })
              .onActionUpdate((event: GestureEvent) => {
                if (idx !== this.toDisplay(this.currentIndex)) {
                  return;
                }
                this.zoomScale = Math.min(MAX_ZOOM, Math.max(1.0, this.pinchBaseScale * event.scale));
              })
              .onActionEnd(() => {
                if (idx !== this.toDisplay(this.currentIndex)) {
                  return;
                }
                if (this.zoomScale < ZOOM_RESET_THRESHOLD) {
                  this.resetZoom();
                }
              }),
            LongPressGesture({ repeat: false })
              .onAction(() => {
                if (!this.longPressZoom || idx !== this.toDisplay(this.currentIndex)) {
                  return;
                }
                this.zoomScale = DOUBLE_TAP_ZOOM;
              })
              .onActionEnd(() => {
                if (idx !== this.toDisplay(this.currentIndex)) {
                  return;
                }
                this.resetZoom();
              })
          )
        )
      }, (url: string, idx: number) => `${idx}-${this.readMode}-${url}`)
    }
    .index(this.toDisplay(this.currentIndex))
    .vertical(this.isVerticalPaging())
    .cachedCount(2)
    .disableSwipe(this.zoomScale > ZOOM_RESET_THRESHOLD)
    .indicator(false)
    .loop(false)
    .duration(this.pageAnimation ? 250 : 0)
    .onChange((index: number) => {
      this.zoomScale = 1.0;
      this.currentIndex = this.toReal(index);
      this.preloadAround(this.currentIndex);
    })
    .width('100%').height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
  }

  @Builder
  buildDualSwiper() {
    Swiper() {
      LazyForEach(this.dualDS, (p: number) => {
        Row({ space: 0 }) {
          if (this.readMode === 5) {
            // 双页反向：右页在前；两半贴中线对齐（消除中部间隔）
            if (p + 1 < this.images.length) {
              Stack({ alignContent: Alignment.End }) {
                this.pageImage(this.images[p + 1], true)
              }
              .width('50%').height('100%').clip(true)
              Stack({ alignContent: Alignment.Start }) {
                this.pageImage(this.images[p], true)
              }
              .width('50%').height('100%').clip(true)
            } else {
              Stack() {
                this.pageImage(this.images[p], true)
              }
              .width('100%').height('100%').clip(true)
            }
          } else {
            Stack({ alignContent: Alignment.End }) {
              this.pageImage(this.images[p], true)
            }
            .width('50%').height('100%').clip(true)
            if (p + 1 < this.images.length) {
              Stack({ alignContent: Alignment.Start }) {
                this.pageImage(this.images[p + 1], true)
              }
              .width('50%').height('100%').clip(true)
            }
          }
        }
        .width('100%').height('100%')
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
        .scale({
          x: p === Math.floor(this.currentIndex / 2) ? this.zoomScale : 1,
          y: p === Math.floor(this.currentIndex / 2) ? this.zoomScale : 1
        })
        .gesture(
          GestureGroup(GestureMode.Parallel,
            PinchGesture({ fingers: 2 })
              .onActionStart(() => {
                if (p !== Math.floor(this.currentIndex / 2)) {
                  return;
                }
                this.pinchBaseScale = this.zoomScale;
              })
              .onActionUpdate((event: GestureEvent) => {
                if (p !== Math.floor(this.currentIndex / 2)) {
                  return;
                }
                this.zoomScale = Math.min(MAX_ZOOM, Math.max(1.0, this.pinchBaseScale * event.scale));
              })
              .onActionEnd(() => {
                if (p !== Math.floor(this.currentIndex / 2)) {
                  return;
                }
                if (this.zoomScale < ZOOM_RESET_THRESHOLD) {
                  this.resetZoom();
                }
              }),
            LongPressGesture({ repeat: false })
              .onAction(() => {
                if (!this.longPressZoom || p !== Math.floor(this.currentIndex / 2)) {
                  return;
                }
                this.zoomScale = DOUBLE_TAP_ZOOM;
              })
              .onActionEnd(() => {
                if (p !== Math.floor(this.currentIndex / 2)) {
                  return;
                }
                this.resetZoom();
              })
          )
        )
      }, (p: number) => `${p}-${this.readMode}`)
    }
    .index(Math.floor(this.currentIndex / 2))
    .cachedCount(2)
    .disableSwipe(this.zoomScale > ZOOM_RESET_THRESHOLD)
    .indicator(false)
    .loop(false)
    .duration(this.pageAnimation ? 250 : 0)
    .onChange((index: number) => {
      this.zoomScale = 1.0;
      this.currentIndex = Math.min(index * 2, this.images.length - 1);
      this.preloadAround(this.currentIndex);
    })
    .width('100%').height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
  }

  @Builder
  buildStripList() {
    List({ scroller: this.stripScroller, initialIndex: this.currentIndex }) {
      LazyForEach(this.stripDS, (url: string, idx: number) => {
        ListItem() {
          if (url.length > 0) {
            ReaderImage({ url: url, imageLayout: this.imageLayout, fill: false })
          } else {
            Column({ space: 8 }) {
              LoadingProgress().width(40).height(40).color('#FFFFFF')
            }
            .width('100%').height(400)
            .justifyContent(FlexAlign.Center)
            .backgroundColor('#000000')
          }
        }
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      }, (url: string, idx: number) => `${idx}-${url}`)
    }
    .width('100%').height('100%')
    .cachedCount(3)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .onScrollIndex((first: number) => {
      this.currentIndex = first;
    })
  }

  @Builder
  buildContent() {
    if (this.readMode === 0 || this.readMode === 1 || this.readMode === 2) {
      this.buildSingleSwiper()
    } else if (this.readMode === 3) {
      this.buildStripList()
    } else {
      this.buildDualSwiper()
    }
  }

  // ---------- 点按区（双击缩放 + 单击分区） ----------
  @Builder
  tapZone(w: string, h: string, zone: number) {
    Column()
      .width(w).height(h)
      .hitTestBehavior(HitTestMode.Transparent)
      .gesture(
        GestureGroup(GestureMode.Exclusive,
          TapGesture({ count: 2 })
            .onAction(() => {
              this.handleDoubleTap();
            }),
          TapGesture({ count: 1 })
            .onAction(() => {
              this.onZoneTap(zone);
            })
        )
      )
  }

  @Builder
  buildTapZones() {
    if (this.isVerticalZones()) {
      // 纵向（从上至下/连续）：上=上一页，中=工具栏，下=下一页
      Column({ space: 0 }) {
        this.tapZone('100%', '30%', 0)
        this.tapZone('100%', '40%', 1)
        this.tapZone('100%', '30%', 2)
      }
      .width('100%').height('100%')
      .hitTestBehavior(HitTestMode.Transparent)
    } else {
      Row({ space: 0 }) {
        this.tapZone('30%', '100%', 0)
        this.tapZone('40%', '100%', 1)
        this.tapZone('30%', '100%', 2)
      }
      .width('100%').height('100%')
      .hitTestBehavior(HitTestMode.Transparent)
    }
  }

  // ---------- 侧边页码条（悬浮，拖动快速跳页） ----------
  private sideBarThumbY(): number {
    const max: number = Math.max(this.images.length - 1, 1);
    const ratio: number = Math.min(1, Math.max(0, this.currentIndex / max));
    return ratio * (SIDE_TRACK - SIDE_THUMB);
  }

  private sideBarSeek(ratio: number): void {
    const max: number = Math.max(this.images.length - 1, 0);
    const clamped: number = Math.min(1, Math.max(0, ratio));
    const target: number = Math.round(clamped * max);
    if (target !== this.currentIndex) {
      this.navigateToIndex(target);
    }
  }

  @Builder
  buildSidePageBar() {
    Column({ space: 6 }) {
      if (this.showPageInfo) {
        Text(this.pageLabel())
          .fontSize(10)
          .fontColor('#FFFFFF')
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor('rgba(0,0,0,0.55)')
          .borderRadius(8)
      }
      Stack({ alignContent: Alignment.Top }) {
        Column()
          .width(4)
          .height(SIDE_TRACK)
          .borderRadius(2)
          .backgroundColor('rgba(255,255,255,0.25)')
          .position({ x: 10 })
        Column()
          .width(4)
          .height(SIDE_THUMB)
          .borderRadius(2)
          .backgroundColor(this.themeColor)
          .position({ x: 10, y: this.sideBarThumbY() })
      }
      .width(24)
      .height(SIDE_TRACK)
      .gesture(
        PanGesture({ fingers: 1, distance: 1, direction: PanDirection.Vertical })
          .onActionStart((event: GestureEvent) => {
            this.sideBarDragBase = this.images.length > 1 ?
              this.currentIndex / (this.images.length - 1) : 0;
            this.sideBarDragOffset = event.offsetY;
          })
          .onActionUpdate((event: GestureEvent) => {
            const delta: number = (event.offsetY - this.sideBarDragOffset) / (SIDE_TRACK - SIDE_THUMB);
            this.sideBarSeek(this.sideBarDragBase + delta);
          })
      )
    }
    .padding({ right: 4 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildSidePageBarLayer() {
    Row() {
      this.buildSidePageBar()
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.End)
    .alignItems(VerticalAlign.Center)
    .hitTestBehavior(HitTestMode.Transparent)
  }

  // ---------- 工具栏 ----------
  private pageLabel(): string {
    return `${this.currentIndex + 1} / ${this.images.length}`;
  }

  @Builder
  buildToolbar() {
    
      Column({ space: 0 }) {
        Row({ space: 12 }) {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(22)
            .fontColor(['#FFFFFF'])
        }
        .width(36).height(36)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.saveProgress();
          NavUtil.back();
        })
        Column({ space: 2 }) {
          Text(this.title)
            .fontSize(14).fontColor('#FFFFFF')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.chapters.length > 0 && this.currentChapterTitle().length > 0) {
            Text(this.currentChapterTitle())
              .fontSize(11).fontColor('rgba(255,255,255,0.7)')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph(this.autoPlay ? $r('sys.symbol.pause') : $r('sys.symbol.play_fill'))
            .fontSize(20)
            .fontColor(['#FFFFFF'])
        }
        .width(36).height(36)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.toggleAutoPlay();
        })
        if (this.chapters.length > 0) {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.list_bullet'))
              .fontSize(20)
              .fontColor(['#FFFFFF'])
          }
          .width(36).height(36)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.showToolbar = false;
            this.sheetMode = 'chapters';
            this.showSheet = true;
          })
        }
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph($r('sys.symbol.gearshape'))
            .fontSize(20)
            .fontColor(['#FFFFFF'])
        }
        .width(36).height(36)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.showToolbar = false;
          this.sheetMode = 'settings';
          this.showSheet = true;
        })
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: this.topAvoid + 6, bottom: 6 })
      .backgroundColor('rgba(0,0,0,0.55)')
      .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
      .alignItems(VerticalAlign.Center)

      Blank().layoutWeight(1)

      Column({ space: 6 }) {
        if (this.showPageInfo) {
          Text(this.pageLabel())
            .fontSize(13).fontColor('#FFFFFF')
            .width('100%').textAlign(TextAlign.Center)
        }
        Slider({
          value: this.currentIndex,
          min: 0,
          max: Math.max(this.images.length - 1, 1),
          step: 1,
          style: SliderStyle.OutSet
        })
        .selectedColor(this.themeColor)
        .trackColor('rgba(255,255,255,0.3)')
        .width('92%')
        .onChange((value: number) => {
          this.navigateToIndex(Math.floor(value));
        })
        if (this.chapters.length > 0) {
          Row({ space: 12 }) {
            Text(Translations.t('prev_chapter'))
              .fontSize(13).fontColor('#FFFFFF')
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .backgroundColor('rgba(255,255,255,0.15)')
              .borderRadius(14)
              .onClick(() => {
                const prev: number = this.prevChapterOrder();
                if (prev > 0) {
                  this.loadChapter(prev, true);
                } else {
                  promptAction.showToast({ message: Translations.t('start_of_chapter'), duration: 1200 });
                }
              })
            Text(Translations.t('next_chapter'))
              .fontSize(13).fontColor('#FFFFFF')
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .backgroundColor('rgba(255,255,255,0.15)')
              .borderRadius(14)
              .onClick(() => {
                const next: number = this.nextChapterOrder();
                if (next > 0) {
                  this.loadChapter(next, false);
                } else {
                  promptAction.showToast({ message: Translations.t('end_of_chapter'), duration: 1200 });
                }
              })
          }
        }
      }
      .width('100%')
      .padding({ top: 8, bottom: this.bottomAvoid + 10 })
      .backgroundColor('rgba(0,0,0,0.55)')
      .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
    }
    .width('100%').height('100%')
    .id('toolbar')
    
  }

  // ---------- bindSheet：设置 / 章节 ----------
  private readModeLabel(): string {
    const labels: string[] = [
      Translations.t('mode_ltr'),
      Translations.t('mode_rtl'),
      Translations.t('mode_ttb'),
      Translations.t('mode_continuous'),
      Translations.t('mode_dual'),
      Translations.t('mode_dual_rtl')
    ];
    return labels[this.readMode];
  }

  private imageLayoutLabel(): string {
    const labels: string[] = [
      Translations.t('layout_contain'),
      Translations.t('layout_fill'),
      Translations.t('layout_cover')
    ];
    return labels[this.imageLayout];
  }

  private imageQualityLabel(): string {
    const labels: string[] = ['Original', 'High', 'Medium'];
    if (this.imageQuality >= 0 && this.imageQuality < labels.length) {
      return labels[this.imageQuality];
    }
    return labels[0];
  }

  private autoTimeLabel(): string {
    return `${this.autoPageTime}${Translations.t('seconds_suffix')}`;
  }

  @Builder
  sheetHeader(title: string) {
    Row({ space: 8 }) {
      Text(title)
        .fontSize(17).fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(16)
          .fontColor([$r('app.color.text_secondary')])
      }
      .width(32).height(32)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.showSheet = false;
      })
    }
    .width('100%')
    .padding({ left: 16, right: 12, top: 14, bottom: 6 })
    .alignItems(VerticalAlign.Center)
    .id('sheetHeader')
  }

  @Builder
  settingRow(label: string, value: string, action: () => void) {
    Row({ space: 8 }) {
      Text(label)
        .fontSize(15).fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      Text(value)
        .fontSize(13).fontColor(this.themeColor)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(13)
        .fontColor([$r('app.color.text_tertiary')])
    }
    .width('100%').height(50)
    .padding({ left: 16, right: 16 })
    .onClick(action)
    .id('settingRow' + label)
  }

  @Builder
  settingToggle(label: string, isOn: boolean, onChange: (v: boolean) => void) {
    Row({ space: 8 }) {
      Text(label)
        .fontSize(15).fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: isOn })
        .selectedColor(this.themeColor)
        .switchPointColor('#FFFFFF')
        .onChange((v: boolean) => {
          onChange(v);
        })
    }
    .width('100%').height(50)
    .padding({ left: 16, right: 16 })
    .id('settingToggle' + label)
  }

  @Builder
  settingsSheetContent() {
    
      Column({ space: 0 }) {
        this.sheetHeader(Translations.t('reading_settings'))
      Scroll() {
        Column({ space: 0 }) {
          this.settingRow(Translations.t('reading_mode'), this.readModeLabel(), () => {
            this.readMode = (this.readMode + 1) % 6;
            this.zoomScale = 1.0;
            this.refreshDataSources();
            if (this.isStrip()) {
              this.stripScrollTo(this.currentIndex);
            }
            ReadingConfig.readMode = this.readMode;
            ReadingConfig.saveAll();
          })
          this.settingToggle(Translations.t('tap_turn_page'), this.tapTurnPage, (v: boolean) => {
            this.tapTurnPage = v;
            ReadingConfig.tapTurnPage = v;
            ReadingConfig.saveAll();
          })
          this.settingToggle(Translations.t('invert_tap'), this.invertTap, (v: boolean) => {
            this.invertTap = v;
            ReadingConfig.invertTap = v;
            ReadingConfig.saveAll();
          })
          this.settingToggle(Translations.t('show_page_info'), this.showPageInfo, (v: boolean) => {
            this.showPageInfo = v;
            ReadingConfig.showPageInfo = v;
            ReadingConfig.saveAll();
          })
          this.settingToggle(Translations.t('page_animation'), this.pageAnimation, (v: boolean) => {
            this.pageAnimation = v;
            ReadingConfig.pageAnimation = v;
            ReadingConfig.saveAll();
          })
          this.settingRow(Translations.t('image_layout'), this.imageLayoutLabel(), () => {
            this.imageLayout = (this.imageLayout + 1) % 3;
            ReadingConfig.imageLayout = this.imageLayout;
            ReadingConfig.saveAll();
          })
          this.settingToggle(Translations.t('keep_screen_on'), this.keepScreenOn, (v: boolean) => {
            this.keepScreenOn = v;
            ReadingConfig.keepScreenOn = v;
            ReadingConfig.saveAll();
            this.setKeepScreenOn(v);
          })
          this.settingToggle(Translations.t('double_tap_zoom'), this.doubleTapZoom, (v: boolean) => {
            this.doubleTapZoom = v;
            ReadingConfig.doubleTapZoom = v;
            ReadingConfig.saveAll();
          })
          this.settingToggle(Translations.t('long_press_zoom'), this.longPressZoom, (v: boolean) => {
            this.longPressZoom = v;
            ReadingConfig.longPressZoom = v;
            ReadingConfig.saveAll();
          })
          this.settingToggle(Translations.t('volume_key'), this.volumeKeyTurnPage, (v: boolean) => {
            this.volumeKeyTurnPage = v;
            ReadingConfig.volumeKeyTurnPage = v;
            ReadingConfig.saveAll();
            this.updateVolumeKeySubscription();
          })
          this.settingToggle(Translations.t('side_page_turn'), this.sidePageTurn, (v: boolean) => {
            this.sidePageTurn = v;
            ReadingConfig.sidePageTurn = v;
            ReadingConfig.saveAll();
          })
          this.settingRow(Translations.t('image_quality'), this.imageQualityLabel(), () => {
            this.imageQuality = (this.imageQuality + 1) % 3;
            ReadingConfig.imageQuality = this.imageQuality;
            ReadingConfig.saveAll();  // 触发 AppStorage 同步 → ReaderImage 重载
          })
          this.settingRow(Translations.t('auto_page_interval'), this.autoTimeLabel(), () => {
            const idx: number = AUTO_TIMES.indexOf(this.autoPageTime);
            this.autoPageTime = AUTO_TIMES[(idx + 1) % AUTO_TIMES.length];
            ReadingConfig.autoPageTime = this.autoPageTime;
            ReadingConfig.saveAll();
            this.restartAutoPlayIfOn();
          })
        }
        .width('100%')
      }
      .padding(SafeAreaEdge.BOTTOM)
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .id('settingsSheet')
    
  }

  @Builder
  chaptersSheetContent() {
    
      Column({ space: 0 }) {
        this.sheetHeader(Translations.t('select_chapter'))
      if (this.loadingChapter) {
        Column({ space: 8 }) {
          LoadingProgress().width(36).height(36)
        }
        .width('100%').height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        List({ space: 0 }) {
          ForEach(this.chapters, (chapter: Chapter) => {
            ListItem() {
              Text(chapter.title.length > 0 ? chapter.title : `${chapter.order}`)
                .fontSize(14)
                .fontColor(chapter.order === this.currentChapterOrder ? this.themeColor : $r('app.color.text_primary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%').height(48)
                .padding({ left: 16, right: 16 })
                .onClick(() => {
                  if (chapter.order !== this.currentChapterOrder) {
                    this.loadChapter(chapter.order, false);
                  } else {
                    this.showSheet = false;
                  }
                })
                .id('chapterItem' + chapter.id)
            }
          }, (chapter: Chapter) => `${chapter.id}-${chapter.order}`)
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .divider({
          strokeWidth: 0.5,
          color: $r('app.color.divider'),
          startMargin: 16,
          endMargin: 16
        })
      }
    }
    .width('100%')
    .height('100%')
    .id('chaptersSheet')
    
  }

  @Builder
  sheetContent() {
    if (this.sheetMode === 'chapters') {
      this.chaptersSheetContent()
    } else {
      this.settingsSheetContent()
    }
  }

  build() {
    NavDestination() {
      Stack({ alignContent: Alignment.Top }) {
        this.buildContent()
        this.buildTapZones()
        if (this.sidePageTurn && !this.showToolbar && !this.showSheet && this.images.length > 1) {
          this.buildSidePageBarLayer()
        }
        if (this.showToolbar) {
          this.buildToolbar()
        }
      }
      .width('100%').height('100%')
      .backgroundColor('#000000')
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      .bindSheet($$this.showSheet, this.sheetContent(), {
        detents: [SheetSize.MEDIUM, SheetSize.LARGE],
        blurStyle: BlurStyle.COMPONENT_THICK,
        showClose: false,
        dragBar: true,
        shouldDismiss: () => {
          this.showSheet = false;
        }
      })
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .hideTitleBar(true)
    .backgroundColor('#000000')
    .onBackPressed(() => {
      this.saveProgress();
      return false;
    })
  }
}
