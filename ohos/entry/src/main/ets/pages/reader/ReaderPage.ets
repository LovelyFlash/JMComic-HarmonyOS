// pages/reader/ReaderPage.ets - 阅读器（6 阅读模式 + 手势缩放 + bindSheet 设置/章节 + 续读 + 进度保存）- NavDestination
import { window } from '@kit.ArkUI';
import { uiMaterial } from '@kit.ArkUI';
import { HdsTabs, HdsTabsController, hdsMaterial } from '@kit.UIDesignKit';
import { inputConsumer, KeyCode, KeyEvent } from '@kit.InputKit';
import { Translations } from '../../common/Translations';
import { NavUtil } from '../../common/NavUtil';
import { ToastUtil } from '../../common/ToastUtil';
import { ReadingConfig } from '../../common/ReadingConfig';
import { Database, ReadingProgress } from '../../data/database/Database';
import { ReaderParam } from '../../data/model/ReaderParam';
import { Chapter } from '../../data/model/Chapter';
import { JmApi } from '../../data/api/JmApi';
import { DownloadManager } from '../../data/download/DownloadManager';
import { Network } from '../../common/Network';
import { Logger } from '../../common/Logger';
import { ArrayDataSource } from '../../common/ArrayDataSource';
import { ReaderImage } from '../../components/ReaderImage';
import { ReaderImageCache } from '../../components/ReaderImageCache';
import { SettingSwitch } from '../../components/SettingSwitch';
import { SettingSelect } from '../../components/SettingSelect';
import { SettingCorner } from '../../components/SettingCommon';
import { ImageCache } from '../../data/cache/ImageCache';
import { DEFAULT_THEME_COLOR } from '../../common/Constants';

const MAX_ZOOM = 4.0;
const DOUBLE_TAP_ZOOM = 2.5;
const ZOOM_RESET_THRESHOLD = 1.05;
/** 连续模式触发上一章/下一章的边界上滑阈值（vp） */
const CHAPTER_EDGE_THRESHOLD: number = 80;
/** 水平滚动条显示后自动隐藏的延时（ms） */
const SCROLL_BAR_HIDE_MS: number = 600;
/** 自动翻页可选间隔（秒） */
const AUTO_TIMES: number[] = [3, 5, 8, 10, 15];
/** 进入阅读器后隐藏状态栏的延时（ms，跨过 push 转场再切换避让） */
const ENTRY_BAR_HIDE_DELAY: number = 400;

/** onScrollFrameBegin 返回值（ArkTS 不允许对象字面量直接作为接口返回值） */
class ScrollFrameOffset {
  offsetRemain: number;

  constructor(offsetRemain: number) {
    this.offsetRemain = offsetRemain;
  }
}

/** 连续滚动模式中已拼接的章节段：order + 在全局列表中的起始下标 + 页 URL */
class StripSegment {
  order: number;
  start: number;
  pages: string[];

  constructor(order: number, start: number, pages: string[]) {
    this.order = order;
    this.start = start;
    this.pages = pages;
  }
}

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
  @State sheetMode: string = 'settings';
  /** 底部系统 TabBar 当前项：0 自动 / 1 章节 / 2 进度 / 3 设置 */
  @State toolbarTab: number = 2;
  @State showProgressPanel: boolean = false;
  /** 进度滑块拖动中：翻页模式临时启用翻页动画，拖动跟手过渡 */
  @State sliderDragging: boolean = false;
  /** 翻页模式边界提示：-1=上一章，1=下一章，0=无 */
  @State chapterEdgeHint: number = 0;
  /** 连续模式滚动条显隐（滑动时显示，600ms 后隐藏） */
  @State stripScrollBarVisible: boolean = false;
  /** 连续模式边界下拉/上拉的拉动距离与方向（-1 上一章 / 1 下一章） */
  @State stripEdgePull: number = 0;
  @State stripEdgeDirection: number = 0;
  @State stripEdgeReady: boolean = false;
  private chapterHintTimer: number = -1;
  private stripScrollBarTimer: number = -1;
  /** onScroll 可能在首帧 build 期间触发；显示状态延迟到下一轮事件循环，避免渲染期改 @State */
  private stripScrollBarShowTimer: number = -1;
  private stripAtStartFlag: boolean = true;
  private stripAtEndFlag: boolean = false;
  /** 连续模式是否有手指按住（惯性滑动时已松手，不得在滚动停止时误触发切章） */
  private stripTouchActive: boolean = false;
  /** 边界回弹动画进行中：忽略新的边缘拉动，避免动画与滚动相互抢帧造成卡顿 */
  private stripEdgeSettling: boolean = false;
  private toolbarTabs: HdsTabsController = new HdsTabsController();
  @State loadingChapter: boolean = false;
  /** 首章自取（push-first 进入）失败：内容层错误态 + 点击重试 */
  @State chapterError: boolean = false;
  // 阅读配置
  @State readMode: number = 2;
  @State tapTurnPage: boolean = true;
  @State invertTap: boolean = false;
  @State showPageInfo: boolean = true;
  @State pageAnimation: boolean = true;
  @State imageLayout: number = 0;
  @State keepScreenOn: boolean = false;
  @State doubleTapZoom: boolean = true;
  @State pinchZoom: boolean = true;
  @State autoPreloadNext: boolean = true;
  @State preloadChapterCount: number = 1;
  @State volumeKeyTurnPage: boolean = true;
  @State imageQuality: number = 0;
  @State autoPageTime: number = 5;
  @State autoPlay: boolean = false;
  // 缩放
  @State zoomScale: number = 1.0;
  /** 双指触摸中：临时禁用 Swiper 滑动，保证 1x 状态也能识别双指放大 */
  @State multiTouch: boolean = false;
  private pinchBaseScale: number = 1.0;
  // 三模式页数据源（章节/模式切换时 replaceAll 全量重建）：单页/双页 Swiper 与连续模式 List
  // 均走 LazyForEach 惰性构建——进入/切章只创建 visible+cachedCount 节点，避免整章 N 页一帧 eager 重建掉帧
  private singleSource: ArrayDataSource<string> = new ArrayDataSource<string>();
  private dualSource: ArrayDataSource<number> = new ArrayDataSource<number>();
  private stripScroller: Scroller = new Scroller();
  /** 连续模式缩放值（@State 驱动 List.scale；双指缩放时逐帧更新，List 仅更新变换属性） */
  @State stripZoom: number = 1.0;
  /** 连续模式双指缩放的基准值 */
  private stripPinchBase: number = 1.0;
  /** 连续模式是否处于缩放态 */
  @State stripZoomed: boolean = false;
  /** 连续模式数据源（LazyForEach：replaceAll→onDataReloaded 切章刷新，List cachedCount 预建屏外节点） */
  private stripSource: ArrayDataSource<string> = new ArrayDataSource<string>();
  /** 连续模式定位重校期：期间忽略 onScrollIndex 上报（防瞬时索引污染窗口/预热/进度，参考 restoreGuard） */
  private stripGuard: boolean = false;
  /** 连续模式章节世代号：切章 ++，延迟回调校验后丢弃旧章结果（参考 chapterGeneration） */
  private stripGeneration: number = 0;
  /** 定位重校定时器集合 */
  private stripAnchorTimers: number[] = [];
  /** 预载章节页列表缓存（最多保留 preloadChapterCount 章，默认 1-2 章） */
  private preloadPages: Map<string, string[]> = new Map();
  private preloadOrder: string[] = [];
  private preloadInflight: Set<string> = new Set();
  /** 连续模式已拼接的章节段（无缝跨章滚动） */
  private stripSegments: StripSegment[] = [];
  private stripAppending: boolean = false;
  /** 进度防抖保存定时器 */
  private stripSaveTimer: number = -1;
  /** push-first 进入：首章自取完成后触发一次续读检查（期间禁止落盘，防止把已存进度覆盖为 0） */
  private pendingRestore: boolean = false;
  /** 组件存活标记：异步回调（取章/续读）返回时若已退出则丢弃状态写入 */
  private alive: boolean = true;
  /** 状态栏切换世代号（并发切换仅末次生效，防止隐藏/恢复乱序） */
  private statusBarGen: number = 0;
  /** 进入阅读器后延时隐藏状态栏的定时器（退出时清除，避免退出后误隐藏详情页状态栏） */
  private statusBarHideTimer: number = -1;
  /** 当前状态栏实际可见状态：避免退出时与 aboutToDisappear 重复恢复造成二次避让区回写 */
  private statusBarShown: boolean = true;
  /** 退出阅读器流程防重入：先恢复状态栏，再 pop，避免详情页在转场后跳高度 */
  private exitingReader: boolean = false;
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
  /** 续读确认弹窗可见：视作覆盖层，音量键交还系统 */
  private resumeDialogVisible: boolean = false;
  // 自动翻页定时器
  private autoTimer: number = -1;
  
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR
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
    // 阅读中漫画 pin：该漫画的缓存资源（页面图/封面/详情）超限淘汰时跳过
    ImageCache.pinComic(this.comicId);
    ImageCache.readingComicId = this.comicId;
    this.refreshDataSources();
    this.loadConfig().then(() => {
      // 等配置加载完再预取，保证按正确质量档解码
      this.preloadAround(this.currentIndex);
      if (this.images.length > 0) {
        this.restoreProgress();
        void this.preloadNextChapters();
      } else {
        // push-first 进入：详情页同步转场后由阅读器自取首章（内容层 loading overlay），
        // 取到图片再做续读检查（restoreProgress 依赖 images.length 判定）
        this.pendingRestore = true;
        const order: number = this.currentChapterOrder > 0 ? this.currentChapterOrder :
          (this.chapters.length > 0 ? this.chapters[0].order : 0);
        if (order > 0) {
          void this.loadChapter(order, false, true);
        } else {
          this.chapterError = true;
        }
      }
    });
    // Q2：阅读器内状态栏全程隐藏（打开菜单/半模态也不恢复，避免避让区变化
    // 触发 @StorageProp 整树重渲染导致图片错位）；延后到 push 转场结束，
    // 避免前一页避让区在转场中塌陷（渲染顺序：转场稳定后再切换避让）
    this.statusBarHideTimer = setTimeout(() => {
      this.statusBarHideTimer = -1;
      void this.setStatusBarVisible(false);
    }, ENTRY_BAR_HIDE_DELAY);
  }

  aboutToDisappear(): void {
    this.alive = false;
    if (this.statusBarHideTimer >= 0) {
      clearTimeout(this.statusBarHideTimer);
      this.statusBarHideTimer = -1;
    }
    if (this.stripScrollBarTimer >= 0) {
      clearTimeout(this.stripScrollBarTimer);
      this.stripScrollBarTimer = -1;
    }
    if (this.stripScrollBarShowTimer >= 0) {
      clearTimeout(this.stripScrollBarShowTimer);
      this.stripScrollBarShowTimer = -1;
    }
    if (this.chapterHintTimer >= 0) {
      clearTimeout(this.chapterHintTimer);
      this.chapterHintTimer = -1;
    }
    this.chapterEdgeHint = 0;
    this.stripEdgePull = 0;
    this.stripEdgeDirection = 0;
    this.stripEdgeReady = false;
    this.stripTouchActive = false;
    this.stripEdgeSettling = false;
    this.preloadPages.clear();
    this.preloadOrder = [];
    this.preloadInflight.clear();
    // 离开阅读器：解除 pin，恢复可淘汰
    ImageCache.unpinComic(this.comicId);
    if (ImageCache.readingComicId === this.comicId) {
      ImageCache.readingComicId = '';
    }
    this.flushStripSave();
    this.clearStripAnchorTimers();
    this.setKeepScreenOn(false);
    this.stopAutoPlay();
    this.unregisterVolumeKey();
    // 离开阅读器：恢复状态栏（世代号令挂起的隐藏失效），保证下一页避让就绪
    void this.setStatusBarVisible(true);
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
    this.pinchZoom = ReadingConfig.pinchZoom;
    this.autoPreloadNext = ReadingConfig.autoPreloadNext;
    this.preloadChapterCount = Math.min(2, Math.max(1, ReadingConfig.preloadChapterCount));
    this.volumeKeyTurnPage = ReadingConfig.volumeKeyTurnPage;
    this.imageQuality = ReadingConfig.imageQuality;
    this.autoPageTime = ReadingConfig.autoPageTime;
    this.setKeepScreenOn(this.keepScreenOn);
    this.updateVolumeKeySubscription();
  }

  // ---------- 音量键翻页（inputConsumer 优先响应系统功能键，API16+） ----------
  /** 漫画上方是否有覆盖层：工具栏 / 进度面板 / 半模态 / 加载或错误遮罩 / 续读弹窗 */
  private hasOverlay(): boolean {
    return this.showToolbar || this.showProgressPanel || this.showSheet ||
      this.loadingChapter || this.chapterError || this.resumeDialogVisible;
  }

  private updateVolumeKeySubscription(): void {
    const shouldRegister: boolean = this.volumeKeyTurnPage && !this.hasOverlay();
    if (shouldRegister && !this.volumeRegistered) {
      this.volumeUpCallback = (_event: KeyEvent) => {
        if (this.hasOverlay()) {
          return;
        }
        this.prevPage();
      };
      this.volumeDownCallback = (_event: KeyEvent) => {
        if (this.hasOverlay()) {
          return;
        }
        this.nextPage();
      };
      try {
        inputConsumer.on('keyPressed', this.volumeUpOptions, this.volumeUpCallback);
        inputConsumer.on('keyPressed', this.volumeDownOptions, this.volumeDownCallback);
        this.volumeRegistered = true;
      } catch (e) {
        Logger.warn('ReaderPage', `volume key subscribe failed: ${Logger.describe(e)}`);
        this.volumeRegistered = false;
      }
    } else if (!shouldRegister && this.volumeRegistered) {
      // 有覆盖层时注销监听，让音量键恢复系统音量调节
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
      Logger.warn('ReaderPage', `volume key unsubscribe failed: ${Logger.describe(e)}`);
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
      if (this.currentIndex >= this.stripTotalCount() - 1 &&
        this.nextOrderAfter(this.isStrip() && this.stripSegments.length > 0
          ? this.stripSegments[this.stripSegments.length - 1].order : this.currentChapterOrder) === 0) {
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
      const host: Context | undefined = this.getUIContext().getHostContext();
      if (host === undefined) {
        return;
      }
      const win = await window.getLastWindow(host);
      await win.setWindowKeepScreenOn(on);
    } catch (e) {
      Logger.error('ReaderPage', `setKeepScreenOn failed: ${Logger.describe(e)}`);
    }
  }

  private async restoreProgress(): Promise<void> {
    if (this.comicId.length === 0 || this.source.length === 0) {
      return;
    }
    const progress: ReadingProgress = await Database.getReadingProgress(this.comicId, this.source);
    if (!this.alive) {
      return;
    }
    const chapterMatches: boolean = this.chapters.length === 0 ||
      progress.lastChapter.length === 0 || Number(progress.lastChapter) === this.currentChapterOrder;
    if (progress.lastPage > 0 && progress.lastPage < this.images.length && chapterMatches) {
      const page: number = progress.lastPage;
      this.resumeDialogVisible = true;
      this.updateVolumeKeySubscription();
      this.getUIContext().showAlertDialog({
        title: Translations.t('resume_reading'),
        message: `${Translations.t('resume_hint_prefix')}${page + 1}${Translations.t('resume_hint_suffix')}`,
        primaryButton: {
          value: Translations.t('from_start'),
          action: () => {
            this.resumeDialogVisible = false;
            this.updateVolumeKeySubscription();
            this.navigateToIndex(0);
            this.saveProgress();
          }
        },
        secondaryButton: {
          value: Translations.t('resume_reading'),
          fontColor: this.themeColor,
          action: () => {
            this.resumeDialogVisible = false;
            this.updateVolumeKeySubscription();
            this.navigateToIndex(page);
            if (this.isStrip()) {
              // 连续模式：START 对齐 + 80/400ms 重校（解码前后高度变化需重复校正落点）
              this.stripAnchor(page);
            }
          }
        },
        cancel: () => {
          this.resumeDialogVisible = false;
          this.updateVolumeKeySubscription();
        }
      });
    }
  }

  private async saveProgress(): Promise<void> {
    if (this.comicId.length === 0 || this.source.length === 0) {
      return;
    }
    const chapter: string = this.chapters.length > 0 ? String(this.currentChapterOrder) : '';
    const page: number = this.isStrip() ? this.localPageIndex() : this.currentIndex;
    await Database.updateReadingProgress(this.comicId, this.source, chapter, page);
  }

  /** 进度防抖保存（参考项目 scheduleSavePosition：索引变化 500ms 后落盘，快速滑动不频繁写库） */
  private scheduleStripSave(): void {
    if (this.stripSaveTimer >= 0) {
      clearTimeout(this.stripSaveTimer);
    }
    this.stripSaveTimer = setTimeout(() => {
      this.stripSaveTimer = -1;
      this.saveProgress();
    }, 500);
  }

  /** 立即落盘并清防抖定时器（退出/返回/切章前调用，参考 flushSavePosition） */
  private flushStripSave(): void {
    if (this.stripSaveTimer >= 0) {
      clearTimeout(this.stripSaveTimer);
      this.stripSaveTimer = -1;
    }
    this.saveProgress();
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

  /** 章节/模式切换后重建三模式页数据（RTL 反转仅作用于单页数据源） */
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
    this.singleSource.replaceAll(singleArr);
    const dualArr: number[] = [];
    for (let i = 0; i < this.images.length; i += 2) {
      dualArr.push(i);
    }
    this.dualSource.replaceAll(dualArr);
    const stripArr: string[] = [];
    for (let i = 0; i < this.images.length; i++) {
      stripArr.push(this.images[i]);
    }
    // LazyForEach 刷新走 replaceAll→onDataReloaded（等价参考项目 reload()，避免切章不刷新）
    this.stripSource.replaceAll(stripArr);
  }

  /** 预取当前页：普通前向 6 页/后向 2 页；连续模式双向各 10 页（与 cachedCount 对齐，保证向上/向下滚动进场前比例已缓存，
   *  占位高度不跳变——这是不做锚点补偿的前提，参考项目 ±10 窗口）。入队尾顺序消化、可见页优先插队，队列限流防加载风暴 */
  private preloadAround(idx: number): void {
    const total: number = this.stripTotalCount();
    if (total === 0) {
      return;
    }
    const forward: number = this.isStrip() ? 10 : 6;
    const backward: number = this.isStrip() ? 10 : 2;
    const targets: string[] = [];
    for (let d = 1; d <= forward; d++) {
      const after: number = idx + d;
      if (after < total) {
        targets.push(this.isStrip() ? this.stripSource.getData(after) : this.images[after]);
      }
    }
    for (let d = 1; d <= backward; d++) {
      const before: number = idx - d;
      if (before >= 0) {
        targets.push(this.isStrip() ? this.stripSource.getData(before) : this.images[before]);
      }
    }
    if (targets.length > 0) {
      ReaderImageCache.preload(targets, this.imageQuality, this.getUIContext());
    }
  }

  private preloadCount(): number {
    return Math.min(2, Math.max(1, this.preloadChapterCount));
  }

  /** 连续模式已拼接列表的总页数；翻页模式为当前章页数 */
  private stripTotalCount(): number {
    return this.isStrip() && this.stripSegments.length > 0 ? this.stripSource.totalCount() : this.images.length;
  }

  /** 当前全局索引所在的章节段 */
  private segmentAt(index: number): StripSegment | undefined {
    for (let i = this.stripSegments.length - 1; i >= 0; i--) {
      const seg: StripSegment = this.stripSegments[i];
      if (index >= seg.start && index < seg.start + seg.pages.length) {
        return seg;
      }
    }
    return this.stripSegments.length > 0 ? this.stripSegments[0] : undefined;
  }

  /** 当前章内页码（连续模式全局索引 → 章内索引） */
  private localPageIndex(): number {
    const seg: StripSegment | undefined = this.segmentAt(this.currentIndex);
    return seg !== undefined ? this.currentIndex - seg.start : this.currentIndex;
  }

  private nextOrderAfter(order: number): number {
    let result: number = 0;
    for (let i = 0; i < this.chapters.length; i++) {
      if (this.chapters[i].order > order && (result === 0 || this.chapters[i].order < result)) {
        result = this.chapters[i].order;
      }
    }
    return result;
  }

  /** 下一章 chapterId（order 紧跟当前段末尾）；没有下一章返回空串 */
  private nextChapterIdAfter(order: number): string {
    const nextOrder: number = this.nextOrderAfter(order);
    if (nextOrder <= 0) {
      return '';
    }
    for (let i = 0; i < this.chapters.length; i++) {
      if (this.chapters[i].order === nextOrder) {
        return this.chapters[i].id;
      }
    }
    return '';
  }

  /** 连续模式下无缝拼接下一章：滚动到末尾前提前追加，避免出现边界切换 */
  private async appendNextStripChapter(): Promise<number> {
    if (!this.isStrip() || !this.autoPreloadNext || this.stripAppending || this.stripSegments.length === 0) {
      Logger.debug('ReaderPage', `append skip: strip=${this.isStrip()} auto=${this.autoPreloadNext}` +
        ` appending=${this.stripAppending} seg=${this.stripSegments.length}`);
      return -1;
    }
    const lastSeg: StripSegment = this.stripSegments[this.stripSegments.length - 1];
    const nextOrder: number = this.nextOrderAfter(lastSeg.order);
    if (nextOrder <= 0) {
      return -1;
    }
    let chapterId: string = '';
    for (let i = 0; i < this.chapters.length; i++) {
      if (this.chapters[i].order === nextOrder) {
        chapterId = this.chapters[i].id;
        break;
      }
    }
    const pages: string[] | undefined = this.preloadPages.get(chapterId);
    if (pages === undefined || pages.length === 0) {
      Logger.debug('ReaderPage', `append waiting preload: nextOrder=${nextOrder} chapterId=${chapterId}`);
      void this.preloadNextChapters();
      return -1;
    }
    this.stripAppending = true;
    try {
      this.preloadPages.delete(chapterId);
      const cacheIdx: number = this.preloadOrder.indexOf(chapterId);
      if (cacheIdx >= 0) {
        this.preloadOrder.splice(cacheIdx, 1);
      }
      const start: number = this.stripSource.totalCount();
      this.stripSegments.push(new StripSegment(nextOrder, start, pages));
      this.stripSource.addAll(pages);
      this.stripAtEndFlag = false;
      Logger.info('ReaderPage', `seamless append chapter order=${nextOrder} start=${start} pages=${pages.length}`);
      return start;
    } catch (e) {
      Logger.warn('ReaderPage', `seamless append failed order=${nextOrder}: ${Logger.describe(e)}`);
      return -1;
    } finally {
      // addAll/通知异常时也必须复位，否则后续所有拼接都会被 stripAppending 挡住
      this.stripAppending = false;
      void this.preloadNextChapters();
    }
  }

  /** 后台预载接下来 N 章（1-2 章）的页列表与首屏图片，切章命中缓存即可无缝衔接 */
  private async preloadNextChapters(): Promise<void> {
    if (!this.autoPreloadNext || this.chapters.length === 0 || !this.alive) {
      return;
    }
    const keep: number = this.preloadCount();
    const baseOrder: number = this.isStrip() && this.stripSegments.length > 0
      ? this.stripSegments[this.stripSegments.length - 1].order : this.currentChapterOrder;
    const sorted: Chapter[] = this.chapters.slice();
    sorted.sort((a: Chapter, b: Chapter) => a.order - b.order);
    const targets: Chapter[] = [];
    for (let i = 0; i < sorted.length && targets.length < keep; i++) {
      if (sorted[i].order > baseOrder) {
        targets.push(sorted[i]);
      }
    }
    for (const chapter of targets) {
      if (this.preloadPages.has(chapter.id) || this.preloadInflight.has(chapter.id)) {
        continue;
      }
      this.preloadInflight.add(chapter.id);
      try {
        let pages: string[] = await DownloadManager.readChapterPages(chapter.id);
        if (pages.length === 0) {
          const ch: Chapter = await JmApi.getChapter(chapter.id);
          pages = ch.imageUrls;
        }
        if (pages.length > 0 && this.alive) {
          this.preloadPages.set(chapter.id, pages);
          this.preloadOrder.push(chapter.id);
          this.evictPreloadCache();
          // 只预热每章前 8 页，后续页由阅读时按需加载
          ReaderImageCache.preload(pages.slice(0, 8), this.imageQuality, this.getUIContext());
          Logger.info('ReaderPage', `preload chapter order=${chapter.order} pages=${pages.length}`);
        }
      } catch (e) {
        Logger.warn('ReaderPage', `preload chapter failed order=${chapter.order}: ${Logger.describe(e)}`);
      }
      this.preloadInflight.delete(chapter.id);
    }
    // 预载异步完成时用户可能已经停在列表末尾（尤其“阅读中才开启预载”），
    // 此时滚动回调不会再触发拼接，这里补一次检查。
    if (this.alive && this.isStrip() && this.autoPreloadNext && this.stripSegments.length > 0) {
      const lastOrder: number = this.stripSegments[this.stripSegments.length - 1].order;
      const nextId: string = this.nextChapterIdAfter(lastOrder);
      const nearEnd: boolean = this.stripTotalCount() - this.currentIndex <= 3;
      if (nextId.length > 0 && nearEnd && this.preloadPages.has(nextId)) {
        void this.appendNextStripChapter();
      }
    }
  }

  /** 超出用户设置章数的预载页列表直接销毁（最大保留 2 章） */
  private evictPreloadCache(): void {
    const keep: number = this.preloadCount();
    while (this.preloadOrder.length > keep) {
      const oldId: string | undefined = this.preloadOrder.shift();
      if (oldId !== undefined) {
        this.preloadPages.delete(oldId);
        Logger.info('ReaderPage', `preload evict chapterId=${oldId} keep=${keep}`);
      }
    }
  }

  private isNextChapterPreloaded(): boolean {
    const nextOrder: number = this.nextChapterOrder();
    if (nextOrder <= 0) {
      return false;
    }
    for (let i = 0; i < this.chapters.length; i++) {
      if (this.chapters[i].order === nextOrder) {
        return this.preloadPages.has(this.chapters[i].id);
      }
    }
    return false;
  }

  /** 统一跳页入口：翻页模式驱动 Swiper.index 属性，连续模式驱动 Scroller；smooth=true 用于进度条拖动过渡 */
  private navigateToIndex(target: number, smooth: boolean = false): void {
    this.clearChapterEdgeHint();
    const total: number = this.stripTotalCount();
    const idx: number = Math.max(0, Math.min(target, total - 1));
    this.zoomScale = 1.0;
    this.resetStripZoom();
    this.currentIndex = idx;
    this.stripAtStartFlag = idx <= 0;
    this.stripAtEndFlag = idx >= total - 1;
    if (!this.stripEdgeSettling) {
      this.stripEdgePull = 0;
      this.stripEdgeDirection = 0;
      this.stripEdgeReady = false;
    }
    if (this.isStrip()) {
      this.stripScrollTo(idx, smooth);
    }
    this.preloadAround(idx);
  }

  /** 连续模式滚动到指定页（START 顶部对齐：默认 AUTO 在图片矮于视口时贴底，导致首可见项退 1 页，参考项目踩坑注释） */
  private stripScrollTo(idx: number, smooth: boolean = false): void {
    try {
      this.stripScroller.scrollToIndex(idx, smooth, ScrollAlign.START);
    } catch (e) {
      Logger.warn('ReaderPage', `scrollToIndex failed: ${Logger.describe(e)}`);
    }
  }

  /** 关键落点重校（参考项目 restoreReadPosition）：立即 START 对齐 + 80/400ms 两次校正（图片解码前后 item 高度会变化），
   *  期间 stripGuard 屏蔽 onScrollIndex 上报，最后一次再等 400ms 释放；全程带世代校验 */
  private stripAnchor(idx: number): void {
    this.clearStripAnchorTimers();
    this.stripGuard = true;
    const gen: number = this.stripGeneration;
    this.stripScrollTo(idx);
    const delays: number[] = [80, 400];
    for (let i = 0; i < delays.length; i++) {
      const delay: number = delays[i];
      const isLast: boolean = i === delays.length - 1;
      const timer: number = setTimeout(() => {
        this.stripAnchorTimers = this.stripAnchorTimers.filter((t: number) => t !== timer);
        if (gen !== this.stripGeneration) {
          this.stripGuard = false;
          return;
        }
        this.stripScrollTo(idx);
        Logger.info('ReaderPage', `strip anchor idx=${idx} delay=${delay}ms gen=${gen}`);
        if (isLast) {
          const release: number = setTimeout(() => {
            this.stripAnchorTimers = this.stripAnchorTimers.filter((t: number) => t !== release);
            if (gen === this.stripGeneration) {
              this.stripGuard = false;
              Logger.debug('ReaderPage', `strip guard released gen=${gen}`);
            }
          }, 400);
          this.stripAnchorTimers.push(release);
        }
      }, delay);
      this.stripAnchorTimers.push(timer);
    }
  }

  private clearStripAnchorTimers(): void {
    for (let i = 0; i < this.stripAnchorTimers.length; i++) {
      clearTimeout(this.stripAnchorTimers[i]);
    }
    this.stripAnchorTimers = [];
  }

  /** 双页一次翻一“跨”（两页），单页/TTB 翻一页 */
  private pageStep(): number {
    return this.isDual() ? 2 : 1;
  }

  // ---------- 交互 ----------
  /** 连续模式缩放复位（普通字段 + 单个 @State 开关，两次属性切换完成复位） */
  private resetStripZoom(): void {
    this.getUIContext().animateTo({ duration: 150, curve: Curve.FastOutSlowIn }, () => {
      this.stripZoom = 1.0;
      this.stripZoomed = false;
    });
  }

  /** 连续模式双击缩放：200ms 过渡，避免瞬间跳变 */
  private animateStripZoom(target: number, zoomed: boolean): void {
    this.getUIContext().animateTo({ duration: 200, curve: Curve.FastOutSlowIn }, () => {
      this.stripZoom = target;
      this.stripZoomed = zoomed;
    });
  }

  private resetZoom(): void {
    this.resetStripZoom();
    this.zoomScale = 1.0;
  }

  private handleDoubleTap(): void {
    if (!this.doubleTapZoom) {
      return;
    }
    if (this.isStrip()) {
      // 连续模式：双击切换外层 Scroll 缩放（与 pinch 共用 stripZoom/stripZoomed 状态）
      if (this.stripZoom > 1.0) {
        this.resetStripZoom();
      } else {
        this.animateStripZoom(DOUBLE_TAP_ZOOM, true);
      }
      return;
    }
    if (this.zoomScale > 1.0) {
      this.resetZoom();
    } else {
      this.zoomScale = DOUBLE_TAP_ZOOM;
    }
  }

  private toggleToolbar(): void {
    if (this.showSheet) {
      this.showSheet = false;
      this.updateVolumeKeySubscription();
      return;
    }
    if (this.showToolbar) {
      // 先撤浮层；阅读器内状态栏本就隐藏，内容容器不读避让高度 → 高度不变
      this.showToolbar = false;
      this.showProgressPanel = false;
      this.updateVolumeKeySubscription();
      return;
    }
    // 每次打开工具栏回到进度项并自动展开进度面板
    this.clearChapterEdgeHint();
    this.toolbarTab = 2;
    this.showProgressPanel = true;
    this.showToolbar = true;
    this.updateVolumeKeySubscription();
  }

  /** 底部 TabBar 动作分发：自动翻页 / 章节 / 进度 / 设置 */
  private onToolbarTab(index: number): void {
    this.toolbarTab = index;
    if (index === 0) {
      this.showProgressPanel = false;
      this.updateVolumeKeySubscription();
      this.toggleAutoPlay();
      return;
    }
    if (index === 1) {
      this.showProgressPanel = false;
      this.showToolbar = false;
      this.sheetMode = 'chapters';
      this.showSheet = true;
      this.updateVolumeKeySubscription();
      return;
    }
    if (index === 2) {
      this.showProgressPanel = !this.showProgressPanel;
      this.updateVolumeKeySubscription();
      return;
    }
    this.showProgressPanel = false;
    this.showToolbar = false;
    this.sheetMode = 'settings';
    this.showSheet = true;
    this.updateVolumeKeySubscription();
  }

  /**
   * Q2 状态栏可见性：阅读器内全程隐藏（内容层/工具栏/半模态均为顶层），
   * 仅退出阅读器时恢复。开菜单不再切换状态栏 → 无避让区回写 → 无整树重渲染错位。
   * 世代号防乱序（进入隐藏/退出恢复并发时仅末次生效）。
   */
  private async setStatusBarVisible(show: boolean): Promise<void> {
    if (this.statusBarShown === show) {
      return;
    }
    const gen: number = ++this.statusBarGen;
    try {
      const host: Context | undefined = this.getUIContext().getHostContext();
      if (host === undefined) {
        return;
      }
      const win: window.Window = await window.getLastWindow(host);
      if (gen !== this.statusBarGen) {
        return;
      }
      // @SuppressWarnings syscap
      await win.setSpecificSystemBarEnabled('status', show, true);
      this.statusBarShown = show;
      Logger.debug('ReaderPage', `status bar ${show ? 'shown' : 'hidden'} gen=${gen}`);
    } catch (e) {
      Logger.warn('ReaderPage', `setSpecificSystemBarEnabled failed: ${Logger.describe(e)}`);
    }
  }

  /**
   * 退出阅读器：先把状态栏恢复完成，再执行返回。
   * 否则详情页会先以 topAvoid=0 完成布局，转场结束后状态栏出现再触发一次高度变化，产生可见跳变。
   */
  private async exitReader(): Promise<void> {
    if (this.exitingReader) {
      return;
    }
    this.exitingReader = true;
    this.flushStripSave();
    await this.setStatusBarVisible(true);
    // 等一帧让 avoidAreaChange -> AppStorage(topAvoidHeight) 回写到被阅读器覆盖的详情页
    await new Promise<void>((resolve) => {
      setTimeout(resolve, 60);
    });
    NavUtil.back();
  }

  private prevPage(): void {
    if (this.currentIndex > 0) {
      this.navigateToIndex(this.currentIndex - this.pageStep());
      return;
    }
    // 首页：尝试上一章（翻页模式先进入过渡页，再点一次才切章）
    const prevOrder: number = this.prevChapterOrder();
    if (prevOrder > 0) {
      if (this.isStrip()) {
        this.loadChapter(prevOrder, true);
        return;
      }
      if (this.chapterEdgeHint === -1) {
        this.clearChapterEdgeHint();
        this.loadChapter(prevOrder, true);
      } else {
        this.showChapterEdgeHint(-1);
      }
    } else {
      ToastUtil.show(Translations.t('start_of_chapter'), 1200);
    }
  }

  private nextPage(): void {
    const total: number = this.stripTotalCount();
    if (this.currentIndex + this.pageStep() < total) {
      this.navigateToIndex(this.currentIndex + this.pageStep());
      return;
    }
    // 末页：尝试下一章
    const nextOrder: number = this.nextChapterOrder();
    if (nextOrder > 0) {
      if (this.isStrip()) {
        // 连续模式优先无缝拼接；预载未就绪时回退为直接切章
        void this.appendNextStripChapter().then((start: number) => {
          if (start >= 0) {
            this.navigateToIndex(start);
          } else {
            this.loadChapter(nextOrder, false);
          }
        });
        return;
      }
      if (this.autoPreloadNext && this.isNextChapterPreloaded()) {
        this.clearChapterEdgeHint();
        this.loadChapter(nextOrder, false);
        return;
      }
      if (this.chapterEdgeHint === 1) {
        this.clearChapterEdgeHint();
        this.loadChapter(nextOrder, false);
      } else {
        this.showChapterEdgeHint(1);
      }
    } else {
      ToastUtil.show(Translations.t('end_of_chapter'), 1200);
    }
  }

  private showChapterEdgeHint(direction: number): void {
    this.chapterEdgeHint = direction;
    if (this.chapterHintTimer >= 0) {
      clearTimeout(this.chapterHintTimer);
    }
    this.chapterHintTimer = setTimeout(() => {
      this.chapterEdgeHint = 0;
      this.chapterHintTimer = -1;
    }, 3000);
  }

  private clearChapterEdgeHint(): void {
    this.chapterEdgeHint = 0;
    if (this.chapterHintTimer >= 0) {
      clearTimeout(this.chapterHintTimer);
      this.chapterHintTimer = -1;
    }
  }

  /** 连续模式：顶/底继续上滑超过阈值后切上一章 / 下一章 */
  private loadPrevChapterFromEdge(): void {
    if (this.loadingChapter) {
      return;
    }
    const prevOrder: number = this.prevChapterOrder();
    if (prevOrder > 0) {
      this.loadChapter(prevOrder, true);
    } else {
      ToastUtil.show(Translations.t('start_of_chapter'), 1200);
    }
  }

  private loadNextChapterFromEdge(): void {
    if (this.loadingChapter) {
      return;
    }
    const nextOrder: number = this.nextChapterOrder();
    if (nextOrder > 0) {
      this.loadChapter(nextOrder, false);
    } else {
      ToastUtil.show(Translations.t('end_of_chapter'), 1200);
    }
  }

  /** 连续模式滚动条：滑动时显示，600ms 后自动隐藏 */
  private pulseStripScrollBar(): void {
    if (!this.stripScrollBarVisible && this.stripScrollBarShowTimer < 0) {
      this.stripScrollBarShowTimer = setTimeout(() => {
        this.stripScrollBarShowTimer = -1;
        if (this.alive) {
          this.stripScrollBarVisible = true;
        }
      }, 0);
    }
    if (this.stripScrollBarTimer >= 0) {
      clearTimeout(this.stripScrollBarTimer);
    }
    this.stripScrollBarTimer = setTimeout(() => {
      this.stripScrollBarVisible = false;
      this.stripScrollBarTimer = -1;
    }, SCROLL_BAR_HIDE_MS);
  }

  /** 滚动停止后更快隐藏滚动条 */
  private scheduleStripScrollBarHide(): void {
    if (this.stripScrollBarShowTimer >= 0) {
      clearTimeout(this.stripScrollBarShowTimer);
      this.stripScrollBarShowTimer = -1;
    }
    if (this.stripScrollBarTimer >= 0) {
      clearTimeout(this.stripScrollBarTimer);
    }
    this.stripScrollBarTimer = setTimeout(() => {
      this.stripScrollBarVisible = false;
      this.stripScrollBarTimer = -1;
    }, 300);
  }

  /** 连续模式边界拉动松手：达到阈值才切章；未达到则平滑回弹 */
  private settleStripEdgePull(): void {
    if (this.stripEdgePull <= 0 || this.stripEdgeSettling) {
      return;
    }
    const direction: number = this.stripEdgeDirection;
    const trigger: boolean = this.stripEdgeReady && this.stripEdgePull >= CHAPTER_EDGE_THRESHOLD;
    if (trigger) {
      this.stripEdgeSettling = true;
      // 触发切章也先播放回弹动画，再/同时开始加载
      this.getUIContext().animateTo({ duration: 180, curve: Curve.FastOutSlowIn }, () => {
        this.stripEdgePull = 0;
        this.stripEdgeDirection = 0;
        this.stripEdgeReady = false;
      });
      if (direction < 0) {
        this.loadPrevChapterFromEdge();
      } else if (direction > 0) {
        this.loadNextChapterFromEdge();
      }
      setTimeout(() => {
        this.stripEdgeSettling = false;
      }, 220);
    } else {
      this.cancelStripEdgePull();
    }
  }

  /** 未达到切章条件下的回弹（惯性滚动停止时也只回弹，不触发切章） */
  private cancelStripEdgePull(): void {
    if (this.stripEdgePull <= 0 || this.stripEdgeSettling) {
      return;
    }
    this.stripEdgeSettling = true;
    this.getUIContext().animateTo({ duration: 180, curve: Curve.FastOutSlowIn }, () => {
      this.stripEdgePull = 0;
      this.stripEdgeDirection = 0;
      this.stripEdgeReady = false;
    });
    setTimeout(() => {
      this.stripEdgeSettling = false;
    }, 200);
  }

  /** 增加边界拉动：达到阈值后带阻尼继续增长，允许继续拉动列表 */
  private addEdgePull(delta: number): void {
    const threshold: number = CHAPTER_EDGE_THRESHOLD;
    const maxPull: number = 320;
    const cur: number = this.stripEdgePull;
    let next: number = cur + delta;
    if (cur < threshold && next > threshold) {
      next = threshold + (next - threshold) * 0.4;
    } else if (cur >= threshold) {
      next = cur + delta * 0.4;
    }
    this.stripEdgePull = Math.min(maxPull, next);
    this.stripEdgeReady = this.stripEdgePull >= threshold;
  }

  /** 回拖：超过阈值部分同样带阻尼，回落到阈值以下后 1:1 跟随 */
  private reduceEdgePull(delta: number): void {
    const threshold: number = CHAPTER_EDGE_THRESHOLD;
    const cur: number = this.stripEdgePull;
    let next: number;
    if (cur > threshold) {
      next = cur - delta * 0.4;
    } else {
      next = cur - delta;
    }
    this.stripEdgePull = Math.max(0, next);
    this.stripEdgeReady = this.stripEdgePull >= threshold;
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

  /**
   * 切章/首章自取。silent=true（push-first 进入）：不弹切换 toast、不落盘进度
   * （进入时无「旧章」可存，落盘会把已存进度覆盖为第 0 页）、失败走内容层错误态。
   */
  private async loadChapter(order: number, startAtEnd: boolean, silent: boolean = false): Promise<void> {
    if (this.loadingChapter) {
      return;
    }
    this.loadingChapter = true;
    this.chapterError = false;
    this.clearChapterEdgeHint();
    // 立即关 sheet：关闭动画与内容大重建不叠在同一帧
    this.showSheet = false;
    this.updateVolumeKeySubscription();
    const t0: number = Date.now();
    try {
      // 按章节 order 找到章节 id（JM）
      let chapterId: string = this.comicId;
      for (let i = 0; i < this.chapters.length; i++) {
        if (this.chapters[i].order === order) {
          chapterId = this.chapters[i].id;
          break;
        }
      }
      let imgs: string[] = [];
      let netFailed: boolean = false;
      // 命中预载缓存：直接使用，避免切章网络等待
      let local: string[] = [];
      const cached: string[] | undefined = this.preloadPages.get(chapterId);
      if (cached !== undefined && cached.length > 0) {
        local = cached;
        this.preloadPages.delete(chapterId);
        const cacheIdx: number = this.preloadOrder.indexOf(chapterId);
        if (cacheIdx >= 0) {
          this.preloadOrder.splice(cacheIdx, 1);
        }
        Logger.info('ReaderPage', `chapter preload-hit: order=${order} count=${local.length}`);
      } else {
        // 本地优先：已下载章节直接读 pages.json 渲染。此前先走 getChapter，断网时要等
        // 请求超时+域名探测+重试 ≈100s 才回退本地，表现为切章/跳页后一直转圈。
        local = await DownloadManager.readChapterPages(chapterId);
      }
      if (local.length > 0) {
        imgs = local;
        Logger.info('ReaderPage', `chapter local-first: order=${order} count=${local.length}` +
          ` online=${await Network.isOnline()}`);
      } else if (!await Network.isOnline()) {
        // 离线且未下载：快速失败，不进 getChapter 白等网络超时
        netFailed = true;
        Logger.info('ReaderPage', `offline and no local pages: order=${order}`);
      } else {
        try {
          const ch: Chapter = await JmApi.getChapter(chapterId);
          imgs = ch.imageUrls;
          // 已下载章节在线取章成功后回填 pages.json（旧版本下载缺失时的离线兑底）
          DownloadManager.cacheChapterPages(chapterId, imgs);
        } catch (e) {
          // 联网失败回退本地（上面已查过一次，双保险）
          imgs = await DownloadManager.readChapterPages(chapterId);
          Logger.info('ReaderPage', `getChapter failed, local pages: order=${order} count=${imgs.length}` +
            ` err=${Logger.describe(e)}`);
          netFailed = imgs.length === 0;
        }
      }
      if (!this.alive) {
        return;
      }
      if (imgs.length > 0) {
        const tFetch: number = Date.now() - t0;
        // 诊断日志：切章后内容未变时用于确认接口是否返回了相同图片
        Logger.info('ReaderPage', `chapter switch: order=${this.currentChapterOrder}` +
          ` first=${this.images.length > 0 ? this.images[0] : ''} -> order=${order}` +
          ` chapterId=${chapterId} count=${imgs.length} first=${imgs[0]} fetchMs=${tFetch}`);
        // 切章前：落盘旧章进度（清防抖定时器）+ 世代号推进，旧章延迟定位/保存回调全部失效；
        // push-first 进入（pendingRestore）无旧章，跳过落盘防止覆盖已存进度
        if (!this.pendingRestore) {
          this.flushStripSave();
        }
        this.stripGeneration++;
        this.clearStripAnchorTimers();
        this.images = imgs;
        this.currentChapterOrder = order;
        if (this.isStrip()) {
          this.stripSegments = [new StripSegment(order, 0, imgs)];
          this.stripAppending = false;
        }
        this.currentIndex = startAtEnd ? imgs.length - 1 : 0;
        this.stripAtStartFlag = this.currentIndex <= 0;
        this.stripAtEndFlag = this.currentIndex >= imgs.length - 1;
        if (!this.stripEdgeSettling) {
          this.stripEdgePull = 0;
          this.stripEdgeDirection = 0;
          this.stripEdgeReady = false;
        }
        this.zoomScale = 1.0;
        this.resetStripZoom();
        this.refreshDataSources();
        if (this.isStrip()) {
          // 数据重建后再定位：START 对齐 + 80/400ms 双重校正（替换旧的 setTimeout(50)，带世代校验）
          this.stripAnchor(this.currentIndex);
        }
        this.preloadAround(this.currentIndex);
        Logger.info('ReaderPage', `chapter ready order=${order} totalMs=${Date.now() - t0}`);
        // 后台预载下一章（受「自动预载下一章」开关与预载章节数限制）
        void this.preloadNextChapters();
        if (this.pendingRestore) {
          this.pendingRestore = false;
          this.restoreProgress();
        }
        if (!silent) {
          this.saveProgress();
          ToastUtil.show(Translations.t('chapter_switched'), 1200);
        }
      } else if (silent) {
        this.chapterError = true;
      } else {
        ToastUtil.show(Translations.t(netFailed ? 'error' : 'no_images'), 1200);
      }
    } catch (e) {
      Logger.warn('ReaderPage', `loadChapter failed order=${order}: ${Logger.describe(e)}`);
      if (silent) {
        if (this.alive) {
          this.chapterError = true;
        }
      } else {
        ToastUtil.show(Translations.t('error'), 1200);
      }
    }
    this.loadingChapter = false;
    this.updateVolumeKeySubscription();
  }

  private onZoneTap(zone: number): void {
    if (this.showToolbar) {
      // 工具栏可见时任意点按关闭（对齐原版交互）
      this.showToolbar = false;
      this.showProgressPanel = false;
      this.updateVolumeKeySubscription();
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
  /** 注意：不要按 currentIndex 给 ReaderImage 传 active 门控。LazyForEach 的 item 构建器
   *  不会随父组件状态重跑，active 会停在创建时的值 → 第 4 页起创建时若不在窗口内就永远不加载
   *  （在线/离线表现一致）。挂载即加载，视口裁剪交给 Swiper cachedCount 与像素 LRU。 */
  @Builder
  pageImage(url: string, dual: boolean) {
    if (url.length > 0) {
      ReaderImage({ url: url, imageLayout: this.imageLayout, fill: true, dual: dual })
    } else {
      Column({ space: 8 }) {
        LoadingProgress().width(40).height(40).color($r('app.color.text_on_reader'))
      }
      .width('100%').height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.reader_bg'))
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    }
  }

  @Builder
  buildSingleSwiper() {
    Swiper() {
      LazyForEach(this.singleSource, (url: string, idx: number) => {
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
        .animation({ duration: this.multiTouch ? 0 : 200, curve: Curve.FastOutSlowIn })
      }, (url: string, idx: number) => `${idx}-${url}`)
    }
    .index(this.toDisplay(this.currentIndex))
    .vertical(this.isVerticalPaging())
    .cachedCount(2)
    .disableSwipe(this.zoomScale > ZOOM_RESET_THRESHOLD || this.multiTouch)
    .onTouch((event: TouchEvent) => {
      // 第二根手指落下即禁用 Swiper 滑动，避免双指放大被翻页手势抢占
      const multi: boolean = this.pinchZoom && event.touches.length > 1;
      if (this.multiTouch !== multi) {
        this.multiTouch = multi;
      }
    })
    .indicator(false)
    .loop(false)
    .duration(this.pageAnimation || this.sliderDragging ? 250 : 0)
    .onChange((index: number) => {
      this.zoomScale = 1.0;
      this.clearChapterEdgeHint();
      this.currentIndex = this.toReal(index);
      this.preloadAround(this.currentIndex);
    })
    .width('100%').height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
  };

  @Builder
  buildDualSwiper() {
    Swiper() {
      LazyForEach(this.dualSource, (p: number) => {
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
            }
          else {
              Stack() {
                this.pageImage(this.images[p], true)
              }
              .width('100%').height('100%').clip(true)
            }
          }
          else {
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
        .animation({ duration: this.multiTouch ? 0 : 200, curve: Curve.FastOutSlowIn })
      }, (p: number) => `${p}`)
    }
    .index(Math.floor(this.currentIndex / 2))
    .cachedCount(2)
    .disableSwipe(this.zoomScale > ZOOM_RESET_THRESHOLD || this.multiTouch)
    .onTouch((event: TouchEvent) => {
      const multi: boolean = this.pinchZoom && event.touches.length > 1;
      if (this.multiTouch !== multi) {
        this.multiTouch = multi;
      }
    })
    .indicator(false)
    .loop(false)
    .duration(this.pageAnimation || this.sliderDragging ? 250 : 0)
    .onChange((index: number) => {
      this.zoomScale = 1.0;
      this.clearChapterEdgeHint();
      this.currentIndex = Math.min(index * 2, this.images.length - 1);
      this.preloadAround(this.currentIndex);
    })
    .width('100%').height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
  };

  @Builder
  buildStripList() {
    // 连续模式：List 直接承担纵向翻页；缩放只作用于 List 的绘制变换，
    // 不再让外层 Scroll 接管纵向手势，避免放大后只能在同一页内上下移动。
    Stack() {
      List({ scroller: this.stripScroller, initialIndex: this.currentIndex }) {
        LazyForEach(this.stripSource, (url: string, idx: number) => {
          ListItem() {
            if (url.length > 0) {
              ReaderImage({
                url: url,
                imageLayout: this.imageLayout,
                fill: false
              }).expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
            } else {
              Column({ space: 8 }) {
                LoadingProgress().width(40).height(40).color($r('app.color.text_on_reader'))
              }
              .width('100%').height(400)
              .justifyContent(FlexAlign.Center)
              .backgroundColor($r('app.color.reader_bg'))
              .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
            }
          }
          .width('100%')
          // 官方示例7：item 到滚动祖先间所有直接节点整链 expandSafeArea，
          // 否则滚动后扩展失效（滚动容器内必须按嵌套关系成链配置）
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
          // 加载在 ReaderImage 挂载时自行发起（等价 onAppear ±10 预建窗口），此处仅做预热
          .onAppear(() => {
            this.preloadAround(idx);
          })
        }, (url: string, idx: number) => `${idx}-${url}`)
      }
      .width('100%').height('100%')
      // 官方示例7：内层滚动容器 expand + clip(false)（关闭裁剪，item 扩展绘制才不被滚动容器截断）
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      .clip(false)
      .listDirection(Axis.Vertical)
      .cachedCount(10)
      // 关闭 List 自带边缘弹性，边界拉动完全由 translate 控制，避免回弹抢帧
      .edgeEffect(EdgeEffect.None)
      // 上下滚动条：滑动时显示，600ms 后自动隐藏
      .scrollBar(this.stripScrollBarVisible ? BarState.On : BarState.Off)
      .scrollBarColor('#888888')
      .scrollBarWidth(4)
      .onScroll(() => { this.pulseStripScrollBar(); })
      .onScrollStart(() => {
        this.stripAtStartFlag = this.stripScroller.currentOffset().yOffset <= 0;
        this.stripEdgePull = 0;
        this.stripEdgeDirection = 0;
        this.stripEdgeReady = false;
      })
      .onReachStart(() => {
        this.stripAtStartFlag = true;
        this.stripAtEndFlag = false;
      })
      .onReachEnd(() => {
        this.stripAtEndFlag = true;
        this.stripAtStartFlag = false;
      })
      .onScrollStop(() => {
        this.scheduleStripScrollBarHide();
        // 惯性滑动停止时手指已不在屏上：只回弹，不触发切章
        if (!this.stripTouchActive && !this.stripEdgeSettling) {
          this.cancelStripEdgePull();
        }
      })
      // 边界拉动：只累计拉动距离并显示指示器，松手时在 settleStripEdgePull 中判断是否切章
      .onScrollFrameBegin((offset: number, state: ScrollState) => {
        if (this.stripEdgeSettling) {
          return new ScrollFrameOffset(0);
        }
        if (this.loadingChapter) {
          return new ScrollFrameOffset(offset);
        }
        // 惯性滑动（手指已松开）不再累计边界位移；已有拉动量则平滑回弹
        if (!this.stripTouchActive && this.stripEdgePull > 0 && !this.stripEdgeSettling) {
          this.cancelStripEdgePull();
          return new ScrollFrameOffset(0);
        }
        // 顶部继续下拉
        if (offset < 0 && this.stripAtStartFlag && this.stripScroller.currentOffset().yOffset <= 0) {
          if (!this.stripTouchActive) {
            return new ScrollFrameOffset(0);
          }
          this.stripEdgeDirection = -1;
          this.addEdgePull(-offset);
          this.pulseStripScrollBar();
          return new ScrollFrameOffset(0);
        }
        // 顶部回拖（未松手时慢慢放回）
        if (offset > 0 && this.stripAtStartFlag && this.stripEdgeDirection === -1 && this.stripEdgePull > 0) {
          this.reduceEdgePull(offset);
          if (this.stripEdgePull <= 0) {
            this.stripEdgeDirection = 0;
            this.stripAtStartFlag = false;
          }
          return new ScrollFrameOffset(0);
        }
        // 底部继续上拉
        if (offset > 0 && this.stripAtEndFlag) {
          // 下一章已经追加时不能继续按“边界拉动”处理，否则列表会被 translate 顶住、
          // 用户看到下方有内容却无法下滑。currentIndex 仍停在旧末尾，放行让 List 正常滚动。
          if (this.currentIndex < this.stripTotalCount() - 1) {
            this.stripAtEndFlag = false;
            this.stripEdgePull = 0;
            this.stripEdgeDirection = 0;
            this.stripEdgeReady = false;
            Logger.debug('ReaderPage', `strip scroll release: idx=${this.currentIndex} total=${this.stripTotalCount()}`);
            return new ScrollFrameOffset(offset);
          }
          if (!this.stripTouchActive) {
            return new ScrollFrameOffset(0);
          }
          this.stripEdgeDirection = 1;
          this.addEdgePull(offset);
          this.pulseStripScrollBar();
          return new ScrollFrameOffset(0);
        }
        // 底部回拖
        if (offset < 0 && this.stripAtEndFlag && this.stripEdgeDirection === 1 && this.stripEdgePull > 0) {
          this.reduceEdgePull(-offset);
          if (this.stripEdgePull <= 0) {
            this.stripEdgeDirection = 0;
            this.stripAtEndFlag = false;
          }
          return new ScrollFrameOffset(0);
        }
        if ((offset > 0 && this.stripAtStartFlag) || (offset < 0 && this.stripAtEndFlag)) {
          this.stripAtStartFlag = false;
          this.stripAtEndFlag = false;
          this.stripEdgePull = 0;
          this.stripEdgeDirection = 0;
          this.stripEdgeReady = false;
        }
        return new ScrollFrameOffset(offset);
      })
      .scale({ x: this.stripZoom, y: this.stripZoom })
      .animation({ duration: this.multiTouch ? 0 : 200, curve: Curve.FastOutSlowIn })
      .onScrollIndex((first: number, last: number) => {
        if (this.stripGuard) {
          // 定位重校期：忽略瞬时首项，防止污染 currentIndex/预热/进度（参考 restoreGuard）
          return;
        }
        if (first >= 0) {
          const seg: StripSegment | undefined = this.segmentAt(first);
          if (seg !== undefined && seg.order !== this.currentChapterOrder) {
            // 跨章：先落盘旧章进度，再切换当前章（images 用于章内页码/保存）
            this.saveProgress();
            this.currentChapterOrder = seg.order;
            this.images = seg.pages;
            this.clearChapterEdgeHint();
            void this.preloadNextChapters();
          }
          if (first !== this.currentIndex) {
            Logger.debug('ReaderPage', `strip first index -> ${first}`);
            this.currentIndex = first;
            this.preloadAround(first);
            this.scheduleStripSave();
          }
          // 接近已拼接列表末尾时提前追加下一章，实现无缝连续下滑
          if (this.autoPreloadNext && this.stripSource.totalCount() - last <= 3) {
            void this.appendNextStripChapter();
          }
        }
      })
    }
    .width('100%').height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .clip(false)
    // 边界拉动时整体位移整个漫画列表（类似下拉刷新），而不是只移动提示组件
    .translate({
      y: this.stripEdgeDirection < 0 ? this.stripEdgePull :
        (this.stripEdgeDirection > 0 ? -this.stripEdgePull : 0)
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
  tapZonesContent() {
    if (this.isVerticalZones()) {
      // 纵向（从上至下/连续）：上=上一页，中=工具栏，下=下一页
      Column({ space: 0 }) {
        this.tapZone('100%', '30%', 0)
        this.tapZone('100%', '55%', 1)
        this.tapZone('100%', '15%', 2)
      }
      .width('100%').height('100%')
      .hitTestBehavior(HitTestMode.Transparent)
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    } else {
      Row({ space: 0 }) {
        this.tapZone('30%', '100%', 0)
        this.tapZone('40%', '100%', 1)
        this.tapZone('30%', '100%', 2)
      }
      .width('100%').height('100%')
      .hitTestBehavior(HitTestMode.Transparent)
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    }
  }

  @Builder
  buildTapZones() {
    // 连续滚动模式：List 负责纵向翻页，缩放由点按层双指手势直接改 List.scale；
    // 翻页模式：双指手势改当前页 zoomScale，并临时禁用 Swiper 滑动。
    if (this.isStrip()) {
      Stack() {
        this.tapZonesContent()
      }
      .width('100%').height('100%')
      .hitTestBehavior(HitTestMode.Transparent)
      .onTouch((event: TouchEvent) => {
        const multi: boolean = this.pinchZoom && event.touches.length > 1;
        if (this.multiTouch !== multi) {
          this.multiTouch = multi;
        }
        if (event.type === TouchType.Down || event.type === TouchType.Move) {
          this.stripTouchActive = true;
          if (event.type === TouchType.Down) {
            this.stripEdgeSettling = false;
          }
        }
        if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          this.stripTouchActive = false;
          this.settleStripEdgePull();
        }
      })
      .priorityGesture(
        PinchGesture({ fingers: 2 })
          .onActionStart(() => {
            if (!this.pinchZoom) {
              return;
            }
            this.multiTouch = true;
            this.stripPinchBase = this.stripZoom;
          })
          .onActionUpdate((event: GestureEvent) => {
            if (!this.pinchZoom) {
              return;
            }
            this.stripZoom = Math.min(MAX_ZOOM, Math.max(1.0, this.stripPinchBase * event.scale));
            const zoomed: boolean = this.stripZoom > 1.0;
            if (this.stripZoomed !== zoomed) {
              this.stripZoomed = zoomed;
            }
          })
          .onActionEnd(() => {
            if (!this.pinchZoom) {
              return;
            }
            this.multiTouch = false;
            if (this.stripZoom < ZOOM_RESET_THRESHOLD) {
              this.resetStripZoom();
            } else if (this.stripZoom > 1.0 && !this.stripZoomed) {
              this.stripZoomed = true;
            }
          })
          .onActionCancel(() => {
            this.multiTouch = false;
          })
      )
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    } else {
      Stack() {
        this.tapZonesContent()
      }
      .width('100%').height('100%')
      .hitTestBehavior(HitTestMode.Transparent)
      // 双指开始触摸时禁用 Swiper 滑动，避免翻页手势抢占放大；缩放手势挂最上层点按层，
      // 保证 1x 状态也能识别双指放大（Swiper 内部手势无法优先于翻页）。
      .onTouch((event: TouchEvent) => {
        const multi: boolean = this.pinchZoom && event.touches.length > 1;
        if (this.multiTouch !== multi) {
          this.multiTouch = multi;
        }
      })
      .priorityGesture(
        PinchGesture({ fingers: 2 })
          .onActionStart(() => {
            if (!this.pinchZoom) {
              return;
            }
            this.multiTouch = true;
            this.pinchBaseScale = this.zoomScale;
          })
          .onActionUpdate((event: GestureEvent) => {
            if (!this.pinchZoom) {
              return;
            }
            this.zoomScale = Math.min(MAX_ZOOM, Math.max(1.0, this.pinchBaseScale * event.scale));
          })
          .onActionEnd(() => {
            if (!this.pinchZoom) {
              return;
            }
            this.multiTouch = false;
            if (this.zoomScale < ZOOM_RESET_THRESHOLD) {
              this.resetZoom();
            }
          })
          .onActionCancel(() => {
            this.multiTouch = false;
          })
      )
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    }
  }

  /** 连续模式边界拉动指示器（类似下拉刷新）：随拉动距离滑入，松手达标才切章 */
  @Builder
  stripEdgePullIndicator() {
    if (this.stripEdgePull > 0 && this.stripEdgeDirection !== 0) {
      Stack({ alignContent: this.stripEdgeDirection < 0 ? Alignment.Top : Alignment.Bottom }) {
        Row({ space: 8 }) {
          SymbolGlyph(this.stripEdgeDirection < 0 ? $r('sys.symbol.arrow_down') : $r('sys.symbol.arrow_up'))
            .fontSize(18)
            .fontColor([this.stripEdgeReady ? this.themeColor : $r('app.color.text_on_reader')])
          Text(Translations.t(this.stripEdgeDirection < 0
            ? (this.stripEdgeReady ? 'release_prev_hint' : 'pull_prev_hint')
            : (this.stripEdgeReady ? 'release_next_hint' : 'pull_next_hint')))
            .fontSize(13)
            .fontColor(this.stripEdgeReady ? this.themeColor : $r('app.color.text_on_reader'))
            .maxLines(1)
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor(this.stripEdgeReady ? $r('app.color.reader_overlay_button') : $r('app.color.reader_overlay'))
        .borderRadius(18)
        .margin({ top: this.stripEdgeDirection < 0 ? Math.max(this.topAvoid, 20) : 0,
          bottom: this.stripEdgeDirection > 0 ? Math.max(this.bottomAvoid, 20) : 0 })
        .opacity(Math.min(1, this.stripEdgePull / 40))
      }
      .width('100%').height('100%')
      .hitTestBehavior(HitTestMode.None)
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      .id('stripEdgePullIndicator')
    }
  }

  // ---------- 工具栏 ----------
  private pageLabel(): string {
    if (this.isStrip()) {
      return `${this.localPageIndex() + 1} / ${this.images.length}`;
    }
    return `${this.currentIndex + 1} / ${this.images.length}`;
  }

  /** 翻页模式到边界时的过渡页：再点一次对应翻页区才切章 */
  @Builder
  chapterEdgeHintOverlay() {
    if (this.chapterEdgeHint !== 0) {
      Column({ space: 12 }) {
        SymbolGlyph(this.chapterEdgeHint > 0 ? $r('sys.symbol.chevron_right') : $r('sys.symbol.chevron_left'))
          .fontSize(48)
          .fontColor([$r('app.color.text_on_reader')])
        Text(Translations.t(this.chapterEdgeHint > 0 ? 'next_chapter_hint' : 'prev_chapter_hint'))
          .fontSize(15)
          .fontColor($r('app.color.text_on_reader'))
          .textAlign(TextAlign.Center)
          .maxLines(3)
          .padding({ left: 36, right: 36 })
      }
      .width('100%').height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.reader_overlay'))
      .hitTestBehavior(HitTestMode.None)
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      .id('chapterEdgeHint')
    }
  }

  @Builder
  materialBackButton() {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      SymbolGlyph($r('sys.symbol.chevron_left'))
        .fontSize(24)
        .fontColor([$r('app.color.text_on_reader')])
    }
    .width(40).height(40)
    .backgroundColor($r('app.color.reader_overlay'))
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    }))
    .shadow({ radius: 10, color: '#66000000', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      void this.exitReader();
    })
  }

  @Builder
  bottomTabItem(index: number, icon: Resource, label: string) {
    Column({ space: 2 }) {
      SymbolGlyph(icon)
        .fontSize(22)
        .fontColor([index === 2 ? $r('app.color.text_tertiary') :
          (this.toolbarTab === index ? this.themeColor : $r('app.color.text_tertiary'))])
      Text(label)
        .fontSize(10)
        .fontColor(index === 2 ? $r('app.color.text_tertiary') :
          (this.toolbarTab === index ? this.themeColor : $r('app.color.text_tertiary')))
        .maxLines(1)
    }
    .width('100%').height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  progressPanel() {
    Column({ space: 6 }) {
      if (this.showPageInfo) {
        Text(this.pageLabel())
          .fontSize(13).fontColor($r('app.color.text_on_reader'))
          .width('100%').textAlign(TextAlign.Center)
      }
      Slider({
        value: this.currentIndex,
        min: 0,
        max: Math.max((this.isStrip() ? this.stripTotalCount() : this.images.length) - 1, 1),
        step: 1,
        style: SliderStyle.OutSet
      })
      .selectedColor(this.themeColor)
      .trackColor($r('app.color.reader_slider_track'))
      .width('100%')
      .onChange((value: number, mode: SliderChangeMode) => {
        if (mode === SliderChangeMode.Begin || mode === SliderChangeMode.Moving) {
          this.sliderDragging = true;
        }
        this.navigateToIndex(Math.floor(value), true);
        if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) {
          this.sliderDragging = false;
        }
      })
      // 进度条下方：上一章 / 下一章快捷切换
      Row({ space: 12 }) {
        Button(Translations.t('prev_chapter'))
          .layoutWeight(1)
          .height(36)
          .fontSize(13)
          .fontColor($r('app.color.text_on_reader'))
          .backgroundColor($r('app.color.reader_overlay_button'))
          .borderRadius(18)
          .enabled(this.prevChapterOrder() > 0 && !this.loadingChapter)
          .opacity(this.prevChapterOrder() > 0 && !this.loadingChapter ? 1 : 0.4)
          .onClick(() => {
            const order: number = this.prevChapterOrder();
            if (order > 0) {
              this.loadChapter(order, true);
            }
          })
          .id('progressPrevChapter')
        Button(Translations.t('next_chapter'))
          .layoutWeight(1)
          .height(36)
          .fontSize(13)
          .fontColor($r('app.color.text_on_reader'))
          .backgroundColor($r('app.color.reader_overlay_button'))
          .borderRadius(18)
          .enabled(this.nextChapterOrder() > 0 && !this.loadingChapter)
          .opacity(this.nextChapterOrder() > 0 && !this.loadingChapter ? 1 : 0.4)
          .onClick(() => {
            const order: number = this.nextChapterOrder();
            if (order > 0) {
              this.loadChapter(order, false);
            }
          })
          .id('progressNextChapter')
      }
      .width('100%')
      .margin({ top: 2 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 10, bottom: 10 })
    .backgroundColor(Color.Transparent)
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    }))
    .borderRadius(16)
  }

  @Builder
  buildToolbar() {
    Column({ space: 0 }) {
      // 顶部：渐变阴影 + 材质返回按钮 + 漫画/章节标题
      Stack({ alignContent: Alignment.Top }) {
        Column()
          .width('100%')
          .height(160)
          .linearGradient({
            angle: 180,
            colors: [['#D9000000', 0.0], ['#66000000', 0.55], ['#00000000', 1.0]]
          })
          .hitTestBehavior(HitTestMode.None)

        Row({ space: 8 }) {
          this.materialBackButton()
          Column({ space: 2 }) {
            Text(this.title)
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_on_reader'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
            if (this.chapters.length > 0 && this.currentChapterTitle().length > 0) {
              Text(this.currentChapterTitle())
                .fontSize(11)
                .fontColor($r('app.color.reader_text_secondary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        // 阅读器隐藏状态栏后 topAvoid 可能为 0，仍需给状态栏/摄像头区域留出安全距离
        .padding({ left: 12, right: 12, top: Math.max(this.topAvoid, 34) + 10 })
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .height(160)

      Blank().layoutWeight(1)
        .onClick(() => {
          this.showToolbar = false;
          this.showProgressPanel = false;
          this.updateVolumeKeySubscription();
        })

      if (this.showProgressPanel) {
        this.progressPanel()
      }

      // 底部系统 TabBar：自动翻页 / 章节 / 进度 / 设置
      Stack({ alignContent: Alignment.Bottom }) {
        HdsTabs({ controller: this.toolbarTabs, index: this.toolbarTab }) {
          TabContent() {
            Column()
          }.tabBar(this.bottomTabItem(0,
            this.autoPlay ? $r('sys.symbol.pause') : $r('sys.symbol.play_fill'),
            Translations.t('section_auto')))
          TabContent() {
            Column()
          }.tabBar(this.bottomTabItem(1, $r('sys.symbol.list_bullet'), Translations.t('chapters')))
          TabContent() {
            Column()
          }.tabBar(this.bottomTabItem(2, $r('sys.symbol.circle'), Translations.t('reader_progress')))
          TabContent() {
            Column()
          }.tabBar(this.bottomTabItem(3, $r('sys.symbol.gearshape'), Translations.t('tab_settings')))
        }
        .height(92)
        .margin({ bottom: this.bottomAvoid })
        .barPosition(BarPosition.End)
        .barOverlap(true)
        .vertical(false)
        .barFloatingStyle({
          barBottomMargin: 12,
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.IMMERSIVE,
            materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
          }
        })
        .backgroundColor(Color.Transparent)
        .onTabBarClick((index: number) => {
          this.onToolbarTab(index);
        })
      }
      .width('100%')
      .height(92)
    }
    .width('100%').height('100%')
    .clip(false)
    .id('toolbar')
  }

  // ---------- bindSheet：设置 / 章节 ----------
  private readModeLabels(): string[] {
    const keys: string[] = ['mode_ltr', 'mode_rtl', 'mode_ttb', 'mode_continuous', 'mode_dual', 'mode_dual_rtl'];
    const labels: string[] = [];
    for (let i = 0; i < keys.length; i++) {
      labels.push(Translations.t(keys[i]));
    }
    return labels;
  }

  private imageLayoutLabels(): string[] {
    const keys: string[] = ['layout_contain', 'layout_fill', 'layout_cover'];
    const labels: string[] = [];
    for (let i = 0; i < keys.length; i++) {
      labels.push(Translations.t(keys[i]));
    }
    return labels;
  }

  private imageQualityLabels(): string[] {
    return [
      Translations.t('quality_original'),
      Translations.t('quality_high'),
      Translations.t('quality_medium')
    ];
  }

  private preloadCountLabels(): string[] {
    return [Translations.t('preload_one'), Translations.t('preload_two')];
  }

  private autoPageTimeLabels(): string[] {
    const labels: string[] = [];
    for (let i = 0; i < AUTO_TIMES.length; i++) {
      labels.push(`${AUTO_TIMES[i]}${Translations.t('seconds_suffix')}`);
    }
    return labels;
  }


  /** 分组标题（bg_page 垫底，随列表滚动） */
  @Builder
  groupHeader(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor($r('app.color.text_secondary'))
      .width('100%')
      .padding({ left: 4, top: 16, bottom: 8 })
      .backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  settingsSheetContent() {
    Column({ space: 0 }) {
      // 分组间距 = List space 8 + groupHeader top padding 16 = 24vp（与设置页一致）
      List({ space: 8 }) {
        ListItemGroup({ header: this.groupHeader(Translations.t('section_turn_method')) }) {
          SettingSelect({
            corner: SettingCorner.ALL,
            icon: $r('sys.symbol.arrowshape_turn_up_left'),
            title: Translations.t('reading_mode'),
            options: this.readModeLabels(),
            selectedIndex: this.readMode,
            onSelect: (index: number) => {
              this.readMode = index;
              this.zoomScale = 1.0;
              this.resetStripZoom();
              this.refreshDataSources();
              if (this.isStrip()) {
                // 从翻页/双页切到连续模式时 stripSegments 可能为空；
                // 先用当前章补齐，否则 appendNextStripChapter 永远返回 -1（无法自动拼接下一章）。
                this.stripSegments = [new StripSegment(this.currentChapterOrder, 0, this.images)];
                this.stripAppending = false;
                // 切到连续模式：START 对齐 + 重校 + 屏蔽瞬时索引（新 List 挂载期间防污染）
                this.stripAnchor(this.currentIndex);
                void this.preloadNextChapters();
              }
              ReadingConfig.readMode = index;
              ReadingConfig.saveAll();
            }
          })
        }
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])

        ListItemGroup({ header: this.groupHeader(Translations.t('section_turn_control')) }) {
          SettingSwitch({
            corner: SettingCorner.FIRST,
            icon: $r('sys.symbol.hand_tap'),
            title: Translations.t('tap_turn_page'),
            isOn: this.tapTurnPage,
            onToggle: (v: boolean) => {
              this.tapTurnPage = v;
              ReadingConfig.tapTurnPage = v;
              ReadingConfig.saveAll();
            }
          })
          SettingSwitch({
            corner: SettingCorner.MIDDLE,
            icon: $r('sys.symbol.arrowshape_turn_up_left'),
            title: Translations.t('invert_tap'),
            isOn: this.invertTap,
            onToggle: (v: boolean) => {
              this.invertTap = v;
              ReadingConfig.invertTap = v;
              ReadingConfig.saveAll();
            }
          })
          SettingSwitch({
            corner: SettingCorner.LAST,
            icon: $r('sys.symbol.speaker_wave_2'),
            title: Translations.t('volume_key'),
            isOn: this.volumeKeyTurnPage,
            onToggle: (v: boolean) => {
              this.volumeKeyTurnPage = v;
              ReadingConfig.volumeKeyTurnPage = v;
              ReadingConfig.saveAll();
              this.updateVolumeKeySubscription();
            }
          })
        }
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider')})

        ListItemGroup({ header: this.groupHeader(Translations.t('section_display')) }) {
          SettingSwitch({
            corner: SettingCorner.FIRST,
            icon: $r('sys.symbol.brightness'),
            title: Translations.t('keep_screen_on'),
            isOn: this.keepScreenOn,
            onToggle: (v: boolean) => {
              this.keepScreenOn = v;
              ReadingConfig.keepScreenOn = v;
              ReadingConfig.saveAll();
              this.setKeepScreenOn(v);
            }
          })
          SettingSwitch({
            corner: SettingCorner.MIDDLE,
            icon: $r('sys.symbol.play'),
            title: Translations.t('page_animation'),
            isOn: this.pageAnimation,
            onToggle: (v: boolean) => {
              this.pageAnimation = v;
              ReadingConfig.pageAnimation = v;
              ReadingConfig.saveAll();
            }
          })
          SettingSwitch({
            corner: SettingCorner.LAST,
            icon: $r('sys.symbol.info_circle'),
            title: Translations.t('show_page_info'),
            isOn: this.showPageInfo,
            onToggle: (v: boolean) => {
              this.showPageInfo = v;
              ReadingConfig.showPageInfo = v;
              ReadingConfig.saveAll();
            }
          })
        }
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider')})

        ListItemGroup({ header: this.groupHeader(Translations.t('section_zoom')) }) {
          SettingSwitch({
            corner: SettingCorner.FIRST,
            icon: $r('sys.symbol.magnifyingglass'),
            title: Translations.t('double_tap_zoom'),
            isOn: this.doubleTapZoom,
            onToggle: (v: boolean) => {
              this.doubleTapZoom = v;
              ReadingConfig.doubleTapZoom = v;
              ReadingConfig.saveAll();
            }
          })
          SettingSwitch({
            corner: SettingCorner.LAST,
            icon: $r('sys.symbol.hand_raised_fingers_spread'),
            title: Translations.t('pinch_zoom'),
            isOn: this.pinchZoom,
            onToggle: (v: boolean) => {
              this.pinchZoom = v;
              ReadingConfig.pinchZoom = v;
              ReadingConfig.saveAll();
            }
          })
        }
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider')})

        ListItemGroup({ header: this.groupHeader(Translations.t('section_preload')) }) {
          SettingSwitch({
            corner: SettingCorner.FIRST,
            icon: $r('sys.symbol.rectangle_stack'),
            title: Translations.t('auto_preload_next'),
            isOn: this.autoPreloadNext,
            onToggle: (v: boolean) => {
              this.autoPreloadNext = v;
              ReadingConfig.autoPreloadNext = v;
              ReadingConfig.saveAll();
              void this.preloadNextChapters();
            }
          })
          SettingSelect({
            corner: SettingCorner.LAST,
            icon: $r('sys.symbol.list_number'),
            title: Translations.t('preload_chapter_count'),
            options: this.preloadCountLabels(),
            selectedIndex: this.preloadChapterCount - 1,
            onSelect: (index: number) => {
              this.preloadChapterCount = index + 1;
              ReadingConfig.preloadChapterCount = this.preloadChapterCount;
              ReadingConfig.saveAll();
              this.evictPreloadCache();
              void this.preloadNextChapters();
            }
          })
        }
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider')})

        ListItemGroup({ header: this.groupHeader(Translations.t('section_image')) }) {
          SettingSelect({
            corner: SettingCorner.FIRST,
            icon: $r('sys.symbol.camera'),
            title: Translations.t('image_quality'),
            options: this.imageQualityLabels(),
            selectedIndex: this.imageQuality,
            onSelect: (index: number) => {
              this.imageQuality = index;
              ReadingConfig.imageQuality = index;
              ReadingConfig.saveAll();  // 触发 AppStorage 同步 → ReaderImage 重载
            }
          })
          SettingSelect({
            corner: SettingCorner.LAST,
            icon: $r('sys.symbol.square_grid_2x2'),
            title: Translations.t('image_layout'),
            options: this.imageLayoutLabels(),
            selectedIndex: this.imageLayout,
            onSelect: (index: number) => {
              this.imageLayout = index;
              ReadingConfig.imageLayout = index;
              ReadingConfig.saveAll();
            }
          })
        }
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider')})

        ListItemGroup({ header: this.groupHeader(Translations.t('section_auto')) }) {
          SettingSelect({
            corner: SettingCorner.ALL,
            icon: $r('sys.symbol.timer'),
            title: Translations.t('auto_page_interval'),
            options: this.autoPageTimeLabels(),
            selectedIndex: AUTO_TIMES.indexOf(this.autoPageTime),
            onSelect: (index: number) => {
              this.autoPageTime = AUTO_TIMES[index];
              ReadingConfig.autoPageTime = this.autoPageTime;
              ReadingConfig.saveAll();
              this.restartAutoPlayIfOn();
            }
          })
        }
        .padding({bottom: 24})
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16})
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
    }
    .width('100%')
    .height('100%')
    .id('settingsSheet')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
  }

  @Builder
  chaptersSheetContent() {
      Column({ space: 0 }) {
      if (this.loadingChapter) {
        Column({ space: 8 }) {
          LoadingProgress().width(36).height(36)
        }
        .width('100%').height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        Grid() {
          ForEach(this.chapters, (chapter: Chapter) => {
            GridItem() {
              Text(chapter.title.length > 0 ? chapter.title : `${chapter.order}`)
                .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
                .fontSize(13)
                .fontColor(chapter.order === this.currentChapterOrder ? this.themeColor : $r('app.color.text_primary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width('100%')
                .height(44)
                .textAlign(TextAlign.Center)
                .backgroundColor(chapter.order === this.currentChapterOrder ? $r('app.color.bg_fill') : $r('app.color.bg_surface'))
                .borderRadius(22)
                .onClick(() => {
                  if (chapter.order !== this.currentChapterOrder) {
                    this.loadChapter(chapter.order, false);
                  } else {
                    this.showSheet = false;
                    this.updateVolumeKeySubscription();
                  }
                })
            }
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
            .id('chapterItem' + chapter.id)
          }, (chapter: Chapter) => `${chapter.id}-${chapter.order}`)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(8)
        .rowsGap(8)
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
        .padding({ left: 16, right: 16, bottom: 24 })
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
        if (this.isStrip()) {
          this.stripEdgePullIndicator()
        }
        this.buildContent()
        this.buildTapZones()
        if (!this.isStrip()) {
          this.chapterEdgeHintOverlay()
        }
        if (this.images.length === 0 && this.chapterError) {
          // 首章自取失败：内容层错误态（盖住点按区，点击重试）
          Column({ space: 10 }) {
            Text(Translations.t('error'))
              .fontSize(15)
              .fontColor($r('app.color.text_on_reader'))
            Text(Translations.t('retry'))
              .fontSize(12)
              .fontColor($r('app.color.reader_text_secondary'))
          }
          .width('100%').height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor($r('app.color.reader_bg'))
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
          .onClick(() => {
            const order: number = this.currentChapterOrder > 0 ? this.currentChapterOrder :
              (this.chapters.length > 0 ? this.chapters[0].order : 0);
            if (order > 0) {
              this.chapterError = false;
              void this.loadChapter(order, false, true);
            }
          })
        } else if (this.loadingChapter) {
          // 切章/首章自取期间：半透明遮罩 + 转圈（旧章仍可见，盖住点按区防误触，工具栏在其上可操作）
          Column() {
            LoadingProgress().width(48).height(48).color($r('app.color.text_on_reader'))
          }
          .width('100%').height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor($r('app.color.reader_overlay'))
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
        }
        if (this.showToolbar) {
          // 底部阴影层独立于工具栏布局，铺到屏幕最底部（含导航条区域）。
          // 注意：expandSafeArea 要求组件不要设置固定宽高，固定高度只能向上扩展；
          // 这里用百分比高度铺满全屏，通过渐变色停靠点只在底部形成阴影，并让整条父链一起 expand。
          Stack({ alignContent: Alignment.Bottom }) {
            Column()
              .width('100%')
              .height('100%')
              .linearGradient({
                angle: 180,
                colors: [['#00000000', 0.62], ['#99000000', 0.82], ['#F2000000', 1.0]]
              })
              .hitTestBehavior(HitTestMode.None)
              .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
              .clip(false)
          }
          .width('100%').height('100%')
          .hitTestBehavior(HitTestMode.None)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
          .clip(false)
          this.buildToolbar()
        }
      }
      .width('100%').height('100%')
      .backgroundColor($r('app.color.reader_bg'))
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      .clip(false)
      .bindSheet($$this.showSheet, this.sheetContent(), {
        // 平板横屏窗口宽 ≥840vp 时默认非底部样式，detents 不生效 → 显式底部样式（与详情页一致）
        preferType: SheetType.BOTTOM,
        detents: [SheetSize.MEDIUM, SheetSize.LARGE],
        blurStyle: BlurStyle.COMPONENT_THICK,
        showClose: true,
        title:{title: this.sheetMode === 'chapters' ? Translations.t('select_chapter') : Translations.t('reading_settings'),},
        dragBar: true,
        scrollSizeMode: ScrollSizeMode.CONTINUOUS,
        shouldDismiss: () => {
          this.showSheet = false;
          this.updateVolumeKeySubscription();
        },
        onDisappear: () => {
          this.showSheet = false;
          this.updateVolumeKeySubscription();
        },
        systemMaterial: new uiMaterial.ImmersiveMaterial({
          style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
        })
      })
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .clip(false)
    .hideTitleBar(true)
    .backgroundColor($r('app.color.reader_bg'))
    .onBackPressed(() => {
      // 接管返回：等状态栏恢复后再 pop，避免详情页转场后从无状态栏跳到有状态栏
      void this.exitReader();
      return true;
    })
  }
}
