// components/ReaderImage.ets - 阅读器图片组件（本地优先 + 反打乱 + 宽高比占位 + 三态布局）
import { image } from '@kit.ImageKit';
import { fileUri } from '@kit.CoreFileKit';
import { JmImage } from '../common/JmImage';
import { DownloadManager } from '../data/download/DownloadManager';
import { Logger } from '../common/Logger';
import { Translations } from '../common/Translations';
import { ReaderImageCache } from './ReaderImageCache';

const TAG = 'ReaderImage';
/** 尺寸缓存未命中时的默认宽高比（典型漫画页 ≈ 0.7），用于占位高度预估 */
const PLACEHOLDER_RATIO: number = 0.7;

@Component
export struct ReaderImage {
  @Prop url: string = '';
  @Prop imageLayout: number = 0;
  @Prop fill: boolean = true;
  /** 双页模式：布局贴中线（布局0/1 按宽度适配铺满半屏，布局2 按高度适配靠内边对齐） */
  @Prop dual: boolean = false;
  /** 绘制扩展至安全区（沉浸式铺满状态栏/导航条）。连续滚动模式同样传 true：
   *  官方示例7 要求 item 到滚动祖先整链 expandSafeArea + 滚动容器 clip(false)，成链配置滚动后不失效 */
  @Prop expandArea: boolean = true;
  @StorageProp('imageQuality') @Watch('onQualityChange') imgQuality: number = 0;
  @State pixelMap: image.PixelMap | undefined = undefined;
  @State useRaw: boolean = false;
  /** GIF 原图来源：本地已下载文件优先，未下载回退网络 URL */
  @State rawUrl: string = '';
  @State loadFailed: boolean = false;
  private loadedQuality: number = -1;

  aboutToAppear(): void {
    this.loadedQuality = this.imgQuality;
    // 组件挂载即加载：单页/双页 Swiper 与连续 List 都由 LazyForEach 按 cachedCount 惰性创建，
    // 天然只构建当前/邻近页。不要再按父组件 currentIndex 传 active 门控——LazyForEach 的 item
    // 构建器不会随父状态重跑，active 会永远停留在创建时的值，导致第 4 页起永久不加载。
    this.load();
  }

  private onQualityChange(): void {
    if (this.loadedQuality === this.imgQuality) {
      return;
    }
    this.loadedQuality = this.imgQuality;
    if (JmImage.isGif(this.url)) {
      return;
    }
    this.useRaw = false;
    this.loadFailed = false;
    this.pixelMap = undefined;
    this.load();
  }

  private placeRatio(): number {
    const r: number = ReaderImageCache.ratioOf(this.url);
    return r > 0 ? r : PLACEHOLDER_RATIO;
  }

  /** expandSafeArea 收敛：expandArea=false 时传空数组（官方语义：([],[]) 属性设置无效） */
  private saTypes(): Array<SafeAreaType> {
    return this.expandArea ? [SafeAreaType.SYSTEM] : [];
  }

  private saEdges(): Array<SafeAreaEdge> {
    return this.expandArea ? [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP] : [];
  }

  private async load(): Promise<void> {
    const t0: number = Date.now();
    const url: string = this.url;
    if (url.length === 0) {
      return;
    }
    if (JmImage.isGif(url)) {
      const hit: string = DownloadManager.localHit(url);
      this.rawUrl = hit.length > 0 ? fileUri.getUriFromPath(hit) : url;
      this.useRaw = true;
      return;
    }
    const cached: image.PixelMap | undefined = ReaderImageCache.getWithQuality(url, this.imgQuality);
    if (cached !== undefined) {
      this.pixelMap = cached;
      return;
    }
    const quality: number = this.imgQuality;
    const pm: image.PixelMap | null = await ReaderImageCache.loadPixelMap(url, quality, this.getUIContext(), true);
    if (this.url !== url || this.loadedQuality !== quality) {
      Logger.debug(TAG, `discard after await (prop changed) url=${this.url === url ? 'same' : 'diff'}` +
        ` q=${this.loadedQuality}/${quality}: ${url}`);
      return;
    }
    if (pm === null) {
      this.loadFailed = true;
      return;
    }
    this.pixelMap = pm;
    Logger.debug(TAG, `set pixelMap cost~${Date.now() - t0}ms: ${url}`);
  }

  private retry(): void {
    this.loadFailed = false;
    this.pixelMap = undefined;
    this.load();
  }

  /** 三态布局：布局0 非双页=Contain 全屏；布局2=高度适配；其余=宽度适配（含 strip/双页布局0） */
  @Builder
  layoutImage(source: image.PixelMap | string) {
    if (this.fill && this.imageLayout === 0 && !this.dual) {
      Image(source)
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain)
        .draggable(false)
        .backgroundColor($r('app.color.reader_bg'))
        .expandSafeArea(this.saTypes(), this.saEdges())
    } else if (this.fill && this.imageLayout === 2) {
      Image(source)
        .height('100%')
        .width('auto')
        .objectFit(ImageFit.Contain)
        .draggable(false)
        .backgroundColor($r('app.color.reader_bg'))
        .expandSafeArea(this.saTypes(), this.saEdges())
    } else {
      Image(source)
        .width('100%')
        .height('auto')
        .objectFit(ImageFit.Contain)
        .draggable(false)
        .backgroundColor($r('app.color.reader_bg'))
        .expandSafeArea(this.saTypes(), this.saEdges())
    }
  }

  build() {
    if (this.pixelMap !== undefined) {
      this.layoutImage(this.pixelMap)
    } else if (this.useRaw) {
      this.layoutImage(this.rawUrl)
    } else if (this.loadFailed) {
      if (this.fill) {
        Column({ space: 12 }) {
          Text(Translations.t('image_load_failed'))
            .fontSize(14)
            .fontColor($r('app.color.reader_text_secondary'))
            .maxLines(1)
          Text(Translations.t('tap_retry'))
            .fontSize(12)
            .fontColor($r('app.color.text_on_reader'))
            .maxLines(1)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.reader_bg'))
        .expandSafeArea(this.saTypes(), this.saEdges())
        .onClick(() => {
          this.retry();
        })
      } else {
        Column({ space: 12 }) {
          Text(Translations.t('image_load_failed'))
            .fontSize(14)
            .fontColor($r('app.color.reader_text_secondary'))
            .maxLines(1)
          Text(Translations.t('tap_retry'))
            .fontSize(12)
            .fontColor($r('app.color.text_on_reader'))
            .maxLines(1)
        }
        .width('100%')
        .aspectRatio(this.placeRatio())
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.reader_bg'))
        .expandSafeArea(this.saTypes(), this.saEdges())
        .onClick(() => {
          this.retry();
        })
      }
    } else if (this.fill) {
      Column({ space: 8 }) {
        LoadingProgress().width(40).height(40).color($r('app.color.text_on_reader'))
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.reader_bg'))
      .expandSafeArea(this.saTypes(), this.saEdges())
    } else {
      Column({ space: 8 }) {
        LoadingProgress().width(40).height(40).color($r('app.color.text_on_reader'))
      }
      .width('100%')
      .aspectRatio(this.placeRatio())
      .justifyContent(FlexAlign.Center)
      .backgroundColor($r('app.color.reader_bg'))
      .expandSafeArea(this.saTypes(), this.saEdges())
    }
  }
}
