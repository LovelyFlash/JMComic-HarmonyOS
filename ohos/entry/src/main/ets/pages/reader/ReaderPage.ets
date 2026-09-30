// pages/reader/ReaderPage.ets - 阅读器（6 阅读模式 + 手势缩放 + bindSheet 设置/章节 + 续读 + 进度保存）- NavDestination
import { window } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { Translations } from '../../common/Translations';
import { NavUtil } from '../../common/NavUtil';
import { ReadingConfig } from '../../common/ReadingConfig';
import { Database, ReadingProgress } from '../../data/database/Database';
import { ReaderParam } from '../../data/model/ReaderParam';
import { Chapter } from '../../data/model/Chapter';
import { JmApi } from '../../data/api/JmApi';
import { Logger } from '../../common/Logger';
import { ReaderImage } from '../../components/ReaderImage';

const MAX_ZOOM = 4.0;
const DOUBLE_TAP_ZOOM = 2.5;
const ZOOM_RESET_THRESHOLD = 1.05;

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
  // 缩放
  @State zoomScale: number = 1.0;
  private pinchBaseScale: number = 1.0;
  
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
    this.loadConfig();
    this.restoreProgress();
  }

  aboutToDisappear(): void {
    this.saveProgress();
    this.setKeepScreenOn(false);
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
    this.setKeepScreenOn(this.keepScreenOn);
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
            this.currentIndex = 0;
            this.saveProgress();
          }
        },
        secondaryButton: {
          value: Translations.t('resume_reading'),
          fontColor: this.themeColor,
          action: () => {
            this.currentIndex = page;
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

  private isStrip(): boolean {
    return this.readMode === 2 || this.readMode === 3;
  }

  /** RTL：显示数据反转 */
  private displayImages(): string[] {
    if (!this.isRtl()) {
      return this.images;
    }
    const arr: string[] = [];
    for (let i = this.images.length - 1; i >= 0; i--) {
      arr.push(this.images[i]);
    }
    return arr;
  }

  private toDisplay(real: number): number {
    return this.isRtl() ? this.images.length - 1 - real : real;
  }

  private toReal(display: number): number {
    return this.isRtl() ? this.images.length - 1 - display : display;
  }

  /** 双页模式的起始页索引序列 [0,2,4...] */
  private dualPageIndices(): number[] {
    const arr: number[] = [];
    for (let i = 0; i < this.images.length; i += 2) {
      arr.push(i);
    }
    return arr;
  }

  // ---------- 交互 ----------
  private resetZoom(): void {
    this.getUIContext().animateTo({ duration: 150, curve: Curve.FastOutSlowIn }, () => {
      this.zoomScale = 1.0;
    });
  }

  private handleDoubleTap(): void {
    if (!this.doubleTapZoom || this.isStrip()) {
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
      this.zoomScale = 1.0;
      this.currentIndex = this.currentIndex - 1;
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
    if (this.currentIndex < this.images.length - 1) {
      this.zoomScale = 1.0;
      this.currentIndex = this.currentIndex + 1;
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
  pageImage(url: string) {
    if (url.length > 0) {
      ReaderImage({ url: url, imageLayout: this.imageLayout, fill: true })
    } else {
      Column({ space: 8 }) {
        LoadingProgress().width(40).height(40).color('#FFFFFF')
      }
      .width('100%').height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#000000')
    }
  }

  @Builder
  buildSingleSwiper() {
    Swiper() {
      ForEach(this.displayImages(), (url: string, idx: number) => {
        Stack() {
          this.pageImage(url)
        }
        .width('100%').height('100%')
        .scale({ x: this.zoomScale, y: this.zoomScale })
        .gesture(
          GestureGroup(GestureMode.Parallel,
            PinchGesture({ fingers: 2 })
              .onActionStart(() => {
                this.pinchBaseScale = this.zoomScale;
              })
              .onActionUpdate((event: GestureEvent) => {
                this.zoomScale = Math.min(MAX_ZOOM, Math.max(1.0, this.pinchBaseScale * event.scale));
              })
              .onActionEnd(() => {
                if (this.zoomScale < ZOOM_RESET_THRESHOLD) {
                  this.resetZoom();
                }
              }),
            LongPressGesture({ repeat: false })
              .onAction(() => {
                if (this.longPressZoom) {
                  this.zoomScale = DOUBLE_TAP_ZOOM;
                }
              })
              .onActionEnd(() => {
                this.resetZoom();
              })
          )
        )
      }, (url: string, idx: number) => `${idx}-${this.readMode}-${url}`)
    }
    .index(this.toDisplay(this.currentIndex))
    .indicator(false)
    .loop(false)
    .duration(this.pageAnimation ? 250 : 0)
    .onChange((index: number) => {
      this.zoomScale = 1.0;
      this.currentIndex = this.toReal(index);
    })
    .width('100%').height('100%')
  }

  @Builder
  buildDualSwiper() {
    Swiper() {
      ForEach(this.dualPageIndices(), (p: number) => {
        Row({ space: 0 }) {
          if (this.readMode === 5) {
            // 双页反向：右页在前
            if (p + 1 < this.images.length) {
              Column() {
                this.pageImage(this.images[p + 1])
              }
              .width('50%').height('100%')
              Column() {
                this.pageImage(this.images[p])
              }
              .width('50%').height('100%')
            } else {
              Column() {
                this.pageImage(this.images[p])
              }
              .width('100%').height('100%')
            }
          } else {
            Column() {
              this.pageImage(this.images[p])
            }
            .width('50%').height('100%')
            if (p + 1 < this.images.length) {
              Column() {
                this.pageImage(this.images[p + 1])
              }
              .width('50%').height('100%')
            }
          }
        }
        .width('100%').height('100%')
        .scale({ x: this.zoomScale, y: this.zoomScale })
        .gesture(
          GestureGroup(GestureMode.Parallel,
            PinchGesture({ fingers: 2 })
              .onActionStart(() => {
                this.pinchBaseScale = this.zoomScale;
              })
              .onActionUpdate((event: GestureEvent) => {
                this.zoomScale = Math.min(MAX_ZOOM, Math.max(1.0, this.pinchBaseScale * event.scale));
              })
              .onActionEnd(() => {
                if (this.zoomScale < ZOOM_RESET_THRESHOLD) {
                  this.resetZoom();
                }
              }),
            LongPressGesture({ repeat: false })
              .onAction(() => {
                if (this.longPressZoom) {
                  this.zoomScale = DOUBLE_TAP_ZOOM;
                }
              })
              .onActionEnd(() => {
                this.resetZoom();
              })
          )
        )
      }, (p: number) => `${p}-${this.readMode}`)
    }
    .index(Math.floor(this.currentIndex / 2))
    .indicator(false)
    .loop(false)
    .duration(this.pageAnimation ? 250 : 0)
    .onChange((index: number) => {
      this.zoomScale = 1.0;
      this.currentIndex = Math.min(index * 2, this.images.length - 1);
    })
    .width('100%').height('100%')
  }

  @Builder
  buildStripList() {
    List({ initialIndex: this.currentIndex }) {
      ForEach(this.images, (url: string, idx: number) => {
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
      }, (url: string, idx: number) => `${idx}-${url}`)
    }
    .width('100%').height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .onScrollIndex((first: number) => {
      this.currentIndex = first;
    })
  }

  @Builder
  buildContent() {
    if (this.readMode === 0 || this.readMode === 1) {
      this.buildSingleSwiper()
    } else if (this.isStrip()) {
      this.buildStripList()
    } else {
      this.buildDualSwiper()
    }
  }

  // ---------- 点按区（双击缩放 + 单击分区） ----------
  @Builder
  tapZone(width: string, zone: number) {
    Column()
      .width(width).height('100%')
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
    Row({ space: 0 }) {
      this.tapZone('30%', 0)
      this.tapZone('40%', 1)
      this.tapZone('30%', 2)
    }
    .width('100%').height('100%')
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
          this.zoomScale = 1.0;
          this.currentIndex = Math.floor(value);
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
        }
        .width('100%')
      }
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
        if (this.showToolbar) {
          this.buildToolbar()
        }
      }
      .width('100%').height('100%')
      .backgroundColor('#000000')
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
    .hideTitleBar(true)
    .backgroundColor('#000000')
    .onBackPressed(() => {
      this.saveProgress();
      return false;
    })
  }
}
