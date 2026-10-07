// pages/reader/ReaderPage.ets - 阅读器（6 阅读模式 + 手势缩放 + bindSheet 设置/章节 + 续读 + 进度保存）- NavDestination
import { window } from '@kit.ArkUI';
import { uiMaterial } from '@kit.ArkUI';
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
import { ArrayDataSource } from '../../common/ArrayDataSource';
import { ReaderImage, ReaderImageCache } from '../../components/ReaderImage';
import { SettingSwitch } from '../../components/SettingSwitch';
import { SettingSelect } from '../../components/SettingSelect';
import { SettingCorner } from '../../components/SettingCommon';
import { DEFAULT_THEME_COLOR } from '../../common/Constants';

const MAX_ZOOM = 4.0;
const DOUBLE_TAP_ZOOM = 2.5;
const ZOOM_RESET_THRESHOLD = 1.05;
/** 侧边页码条：轨道与滑块尺寸（vp） */
const SIDE_TRACK: number = 280;
const SIDE_THUMB: number = 36;
/** 自动翻页可选间隔（秒） */
const AUTO_TIMES: number[] = [3, 5, 8, 10, 15];
/** 视口懒加载窗口：仅加载距当前页 N 页内的图片（离窗丢像素、保留比例占位） */
const ACTIVE_WINDOW_SINGLE: number = 2;
const ACTIVE_WINDOW_DUAL: number = 2;
/** 进入阅读器后隐藏状态栏的延时（ms，跨过 push 转场再切换避让） */
const ENTRY_BAR_HIDE_DELAY: number = 400;

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
  @State longPressZoom: boolean = true;
  @State volumeKeyTurnPage: boolean = true;
  @State sidePageTurn: boolean = false;
  @State imageQuality: number = 0;
  @State autoPageTime: number = 5;
  @State autoPlay: boolean = false;
  // 缩放
  @State zoomScale: number = 1.0;
  private pinchBaseScale: number = 1.0;
  // 三模式页数据源（章节/模式切换时 replaceAll 全量重建）：单页/双页 Swiper 与连续模式 List
  // 均走 LazyForEach 惰性构建——进入/切章只创建 visible+cachedCount 节点，避免整章 N 页一帧 eager 重建掉帧
  private singleSource: ArrayDataSource<string> = new ArrayDataSource<string>();
  private dualSource: ArrayDataSource<number> = new ArrayDataSource<number>();
  private stripScroller: Scroller = new Scroller();
  /** 连续模式外层缩放 Scroll（参考项目 scroll 模式：外层 pinch 缩放 + 缩放态平移，内层 List 纵向滚动） */
  private stripOuterScroller: Scroller = new Scroller();
  /** 连续模式缩放值。参考项目 zoomScale 用普通字段：onDidZoom 每帧写入不触发重渲（避免
   *  pinch/滚动期间整棵内容树按帧重渲导致卡顿不跟手），仅越过阈值时翻 stripZoomed 重渲一次 */
  private stripZoom: number = 1.0;
  /** 连续模式是否处于缩放态（驱动 scrollable/scrollBar 切换，参考项目 isZoomed） */
  @State stripZoomed: boolean = false;
  /** 连续模式数据源（LazyForEach：replaceAll→onDataReloaded 切章刷新，List cachedCount 预建屏外节点） */
  private stripSource: ArrayDataSource<string> = new ArrayDataSource<string>();
  /** 连续模式定位重校期：期间忽略 onScrollIndex 上报（防瞬时索引污染窗口/预热/进度，参考 restoreGuard） */
  private stripGuard: boolean = false;
  /** 连续模式章节世代号：切章 ++，延迟回调校验后丢弃旧章结果（参考 chapterGeneration） */
  private stripGeneration: number = 0;
  /** 定位重校定时器集合 */
  private stripAnchorTimers: number[] = [];
  /** 进度防抖保存定时器 */
  private stripSaveTimer: number = -1;
  /** push-first 进入：首章自取完成后触发一次续读检查（期间禁止落盘，防止把已存进度覆盖为 0） */
  private pendingRestore: boolean = false;
  /** 组件存活标记：异步回调（取章/续读）返回时若已退出则丢弃状态写入 */
  private alive: boolean = true;
  /** 状态栏切换世代号（并发切换仅末次生效，防止隐藏/恢复乱序） */
  private statusBarGen: number = 0;
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
    this.refreshDataSources();
    this.loadConfig().then(() => {
      // 等配置加载完再预取，保证按正确质量档解码
      this.preloadAround(this.currentIndex);
      if (this.images.length > 0) {
        this.restoreProgress();
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
    setTimeout(() => {
      void this.setStatusBarVisible(false);
    }, ENTRY_BAR_HIDE_DELAY);
  }

  aboutToDisappear(): void {
    this.alive = false;
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
        Logger.warn('ReaderPage', `volume key subscribe failed: ${Logger.describe(e)}`);
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
            if (this.isStrip()) {
              // 连续模式：START 对齐 + 80/400ms 重校（解码前后高度变化需重复校正落点）
              this.stripAnchor(page);
            }
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
    if (this.images.length === 0) {
      return;
    }
    const forward: number = this.isStrip() ? 10 : 6;
    const backward: number = this.isStrip() ? 10 : 2;
    const targets: string[] = [];
    for (let d = 1; d <= forward; d++) {
      const after: number = idx + d;
      if (after < this.images.length) {
        targets.push(this.images[after]);
      }
    }
    for (let d = 1; d <= backward; d++) {
      const before: number = idx - d;
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
    this.resetStripZoom();
    this.currentIndex = idx;
    if (this.isStrip()) {
      this.stripScrollTo(idx);
    }
    this.preloadAround(idx);
  }

  /** 连续模式滚动到指定页（START 顶部对齐：默认 AUTO 在图片矮于视口时贴底，导致首可见项退 1 页，参考项目踩坑注释） */
  private stripScrollTo(idx: number): void {
    try {
      this.stripScroller.scrollToIndex(idx, false, ScrollAlign.START);
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
    this.stripZoom = 1.0;
    this.stripZoomed = false;
  }

  private resetZoom(): void {
    this.resetStripZoom();
    this.getUIContext().animateTo({ duration: 150, curve: Curve.FastOutSlowIn }, () => {
      this.zoomScale = 1.0;
    });
  }

  private handleDoubleTap(): void {
    if (!this.doubleTapZoom) {
      return;
    }
    if (this.isStrip()) {
      // 连续模式：双击切换外层 Scroll 缩放（参考项目无双击缩放，字段模式同 pinch 路径）
      if (this.stripZoom > 1.0) {
        this.resetStripZoom();
      } else {
        this.stripZoom = DOUBLE_TAP_ZOOM;
        this.stripZoomed = true;
      }
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
    if (this.showToolbar) {
      // 先撤浮层；阅读器内状态栏本就隐藏，内容容器不读避让高度 → 高度不变
      this.showToolbar = false;
      return;
    }
    this.showToolbar = true;
  }

  /**
   * Q2 状态栏可见性：阅读器内全程隐藏（内容层/工具栏/半模态均为顶层），
   * 仅退出阅读器时恢复。开菜单不再切换状态栏 → 无避让区回写 → 无整树重渲染错位。
   * 世代号防乱序（进入隐藏/退出恢复并发时仅末次生效）。
   */
  private async setStatusBarVisible(show: boolean): Promise<void> {
    const gen: number = ++this.statusBarGen;
    try {
      const win: window.Window = await window.getLastWindow(getContext(this));
      if (gen !== this.statusBarGen) {
        return;
      }
      await win.setSpecificSystemBarEnabled('status', show, true);
      Logger.debug('ReaderPage', `status bar ${show ? 'shown' : 'hidden'} gen=${gen}`);
    } catch (e) {
      Logger.warn('ReaderPage', `setSpecificSystemBarEnabled failed: ${Logger.describe(e)}`);
    }
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
    // 立即关 sheet：关闭动画与内容大重建不叠在同一帧
    this.showSheet = false;
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
      const ch: Chapter = await JmApi.getChapter(chapterId);
      if (!this.alive) {
        return;
      }
      const imgs: string[] = ch.imageUrls;
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
        this.currentIndex = startAtEnd ? imgs.length - 1 : 0;
        this.zoomScale = 1.0;
        this.resetStripZoom();
        this.refreshDataSources();
        if (this.isStrip()) {
          // 数据重建后再定位：START 对齐 + 80/400ms 双重校正（替换旧的 setTimeout(50)，带世代校验）
          this.stripAnchor(this.currentIndex);
        }
        this.preloadAround(this.currentIndex);
        Logger.info('ReaderPage', `chapter ready order=${order} totalMs=${Date.now() - t0}`);
        if (this.pendingRestore) {
          this.pendingRestore = false;
          this.restoreProgress();
        }
        if (!silent) {
          this.saveProgress();
          promptAction.showToast({ message: Translations.t('chapter_switched'), duration: 1200 });
        }
      } else if (silent) {
        this.chapterError = true;
      } else {
        promptAction.showToast({ message: Translations.t('no_images'), duration: 1200 });
      }
    } catch (e) {
      Logger.warn('ReaderPage', `loadChapter failed order=${order}: ${Logger.describe(e)}`);
      if (silent) {
        if (this.alive) {
          this.chapterError = true;
        }
      } else {
        promptAction.showToast({ message: Translations.t('error'), duration: 1200 });
      }
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

  private singleActive(idx: number): boolean {
    return Math.abs(idx - this.toDisplay(this.currentIndex)) <= ACTIVE_WINDOW_SINGLE;
  }

  private dualActive(p: number): boolean {
    return Math.abs(p - Math.floor(this.currentIndex / 2)) <= ACTIVE_WINDOW_DUAL;
  }

  // ---------- 内容区 ----------
  @Builder
  pageImage(url: string, dual: boolean, active: boolean) {
    if (url.length > 0) {
      ReaderImage({ url: url, imageLayout: this.imageLayout, fill: true, dual: dual, active: active })
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
          this.pageImage(url, false, this.singleActive(idx))
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
      }, (url: string, idx: number) => `${idx}-${url}`)
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
                this.pageImage(this.images[p + 1], true, this.dualActive(p))
              }
              .width('50%').height('100%').clip(true)
              Stack({ alignContent: Alignment.Start }) {
                this.pageImage(this.images[p], true, this.dualActive(p))
              }
              .width('50%').height('100%').clip(true)
            }
          else {
              Stack() {
                this.pageImage(this.images[p], true, this.dualActive(p))
              }
              .width('100%').height('100%').clip(true)
            }
          }
          else {
            Stack({ alignContent: Alignment.End }) {
              this.pageImage(this.images[p], true, this.dualActive(p))
            }
            .width('50%').height('100%').clip(true)
            if (p + 1 < this.images.length) {
              Stack({ alignContent: Alignment.Start }) {
                this.pageImage(this.images[p + 1], true, this.dualActive(p))
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
      }, (p: number) => `${p}`)
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
  };

  @Builder
  buildStripList() {
    // 外层 Scroll 负责 pinch 缩放/缩放态平移，内层 List 负责纵向滚动（参考项目 scroll 模式逐属性对齐）
    Scroll(this.stripOuterScroller) {
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
      .scrollBar(BarState.Off)
      .nestedScroll({
        scrollForward: NestedScrollMode.PARENT_FIRST,
        scrollBackward: NestedScrollMode.PARENT_FIRST
      })
      .onScrollIndex((first: number) => {
        if (this.stripGuard) {
          // 定位重校期：忽略瞬时首项，防止污染 currentIndex/预热/进度（参考 restoreGuard）
          return;
        }
        if (first >= 0 && first !== this.currentIndex) {
          Logger.debug('ReaderPage', `strip first index -> ${first}`);
          this.currentIndex = first;
          this.preloadAround(first);
          this.scheduleStripSave();
        }
      })
    }
    .width('100%').height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    // 官方示例7：外层滚动容器 clip(false)（内容绘制可越过滚动容器边界进入避让区）
    .clip(false)
    // 未缩放时纵向滚动交给内层 List（外层禁滚），放大后交给外层 Scroll 平移（参考项目）
    .scrollable(this.stripZoomed ? ScrollDirection.FREE : ScrollDirection.None)
    .maxZoomScale(MAX_ZOOM)
    .minZoomScale(1.0)
    .zoomScale(this.stripZoom)
    .enableBouncesZoom(true)
    .edgeEffect(EdgeEffect.None)
    // 放大后由外层 Scroll 接管（PARENT_FIRST），滑条常显便于横向平移定位；未缩放隐藏
    .scrollBar(this.stripZoomed ? BarState.On : BarState.Off)
    .scrollBarColor('#BBBBBB')
    .scrollBarWidth(6)
    .onDidZoom((scale: number) => {
      // 普通字段逐帧记录（不重渲）；仅越 1.0 阈值翻 stripZoomed 触发一次属性切换（参考 onDidZoom→isZoomed）
      this.stripZoom = scale;
      const zoomed: boolean = scale > 1.0;
      if (this.stripZoomed !== zoomed) {
        this.stripZoomed = zoomed;
      }
    })
    .onZoomStop(() => {
      if (this.stripZoom < ZOOM_RESET_THRESHOLD) {
        this.resetStripZoom();
      }
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
          .fontColor($r('app.color.text_on_reader'))
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor($r('app.color.reader_overlay'))
          .borderRadius(8)
      }
      Stack({ alignContent: Alignment.Top }) {
        Column()
          .width(4)
          .height(SIDE_TRACK)
          .borderRadius(2)
          .backgroundColor($r('app.color.reader_sidebar_track'))
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
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
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
            .fontColor([$r('app.color.text_on_reader')])
        }
        .width(36).height(36)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.flushStripSave();
          NavUtil.back();
        })
        Column({ space: 2 }) {
          Text(this.title)
            .fontSize(14).fontColor($r('app.color.text_on_reader'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.chapters.length > 0 && this.currentChapterTitle().length > 0) {
            Text(this.currentChapterTitle())
              .fontSize(11).fontColor($r('app.color.reader_text_secondary'))
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph(this.autoPlay ? $r('sys.symbol.pause') : $r('sys.symbol.play_fill'))
            .fontSize(20)
            .fontColor([$r('app.color.text_on_reader')])
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
              .fontColor([$r('app.color.text_on_reader')])
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
            .fontColor([$r('app.color.text_on_reader')])
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
      .padding({ left: 12, right: 12, top: this.topAvoid + 30, bottom: 6 })
      .backgroundColor($r('app.color.reader_overlay'))
      .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
      .alignItems(VerticalAlign.Center)
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])

      Blank().layoutWeight(1)
        .onClick(() => {
          this.showToolbar = false;
        })

      Column({ space: 6 }) {
        if (this.showPageInfo) {
          Text(this.pageLabel())
            .fontSize(13).fontColor($r('app.color.text_on_reader'))
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
        .trackColor($r('app.color.reader_slider_track'))
        .width('92%')
        .onChange((value: number) => {
          this.navigateToIndex(Math.floor(value));
        })
        if (this.chapters.length > 0) {
          Row({ space: 12 }) {
            Text(Translations.t('prev_chapter'))
              .fontSize(13).fontColor($r('app.color.text_on_reader'))
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .backgroundColor($r('app.color.reader_overlay_button'))
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
              .fontSize(13).fontColor($r('app.color.text_on_reader'))
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .backgroundColor($r('app.color.reader_overlay_button'))
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
      .backgroundColor($r('app.color.reader_overlay'))
      .backgroundBlurStyle(BlurStyle.COMPONENT_THICK)
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
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
    return ['Original', 'High', 'Medium'];
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
      List({ space: 24 }) {
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
                // 切到连续模式：START 对齐 + 重校 + 屏蔽瞬时索引（新 List 挂载期间防污染）
                this.stripAnchor(this.currentIndex);
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
            corner: SettingCorner.MIDDLE,
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
          SettingSwitch({
            corner: SettingCorner.LAST,
            icon: $r('sys.symbol.rectangle_3_group'),
            title: Translations.t('side_page_turn'),
            isOn: this.sidePageTurn,
            onToggle: (v: boolean) => {
              this.sidePageTurn = v;
              ReadingConfig.sidePageTurn = v;
              ReadingConfig.saveAll();
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
            icon: $r('sys.symbol.hand_tap'),
            title: Translations.t('long_press_zoom'),
            isOn: this.longPressZoom,
            onToggle: (v: boolean) => {
              this.longPressZoom = v;
              ReadingConfig.longPressZoom = v;
              ReadingConfig.saveAll();
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
        this.buildContent()
        this.buildTapZones()
        if (this.sidePageTurn && !this.showToolbar && !this.showSheet && this.images.length > 1) {
          this.buildSidePageBarLayer()
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
          this.buildToolbar()
        }
      }
      .width('100%').height('100%')
      .backgroundColor($r('app.color.reader_bg'))
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      .bindSheet($$this.showSheet, this.sheetContent(), {
        detents: [SheetSize.MEDIUM, SheetSize.LARGE],
        blurStyle: BlurStyle.COMPONENT_THICK,
        showClose: true,
        title:{title: this.sheetMode === 'chapters' ? Translations.t('select_chapter') : Translations.t('reading_settings')},
        dragBar: true,
        shouldDismiss: () => {
          this.showSheet = false;
        },
        systemMaterial: new uiMaterial.ImmersiveMaterial({
          style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
        })
      })
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .hideTitleBar(true)
    .backgroundColor($r('app.color.reader_bg'))
    .onBackPressed(() => {
      this.flushStripSave();
      return false;
    })
  }
}
