// components/ReaderImage.ets - 阅读器图片（JM 分片重组 + LRU 像素缓存 + 宽高比缓存 + 三态布局）
import { image } from '@kit.ImageKit';
import { Network } from '../common/Network';
import { JmImage } from '../common/JmImage';
import { Logger } from '../common/Logger';

const TAG = 'ReaderImage';
/** 尺寸缓存未命中时的默认宽高比（典型漫画页 ≈ 0.7），用于占位高度预估 */
const PLACEHOLDER_RATIO: number = 0.7;

export class ReaderImageCache {
  private static maps: Map<string, image.PixelMap> = new Map();
  private static order: string[] = [];
  private static readonly CAP: number = 12;
  /** URL → 宽高比(w/h)：像素被淘汰后占位仍按真实比例预留高度，消除连续滚动回读跳变 */
  private static ratios: Map<string, number> = new Map();
  private static ratioOrder: string[] = [];
  private static readonly RATIO_CAP: number = 1200;
  /** 进行中的加载（同一 URL 同一质量只下载解码一次） */
  private static inflight: Map<string, Promise<image.PixelMap | null>> = new Map();
  /** 像素缓存对应的质量档位，切换质量后整体失效 */
  private static pixelQuality: number = -1;

  static get(url: string): image.PixelMap | undefined {
    const pm: image.PixelMap | undefined = ReaderImageCache.maps.get(url);
    if (pm !== undefined) {
      const idx: number = ReaderImageCache.order.indexOf(url);
      if (idx >= 0) {
        ReaderImageCache.order.splice(idx, 1);
      }
      ReaderImageCache.order.push(url);
    }
    return pm;
  }

  static put(url: string, pm: image.PixelMap): void {
    if (ReaderImageCache.maps.has(url)) {
      const idx: number = ReaderImageCache.order.indexOf(url);
      if (idx >= 0) {
        ReaderImageCache.order.splice(idx, 1);
      }
    }
    ReaderImageCache.maps.set(url, pm);
    ReaderImageCache.order.push(url);
    while (ReaderImageCache.order.length > ReaderImageCache.CAP) {
      const evict: string = ReaderImageCache.order[0];
      ReaderImageCache.order.splice(0, 1);
      ReaderImageCache.maps.delete(evict);
    }
  }

  static ratioOf(url: string): number {
    const r: number | undefined = ReaderImageCache.ratios.get(url);
    return r !== undefined && r > 0 ? r : 0;
  }

  static setRatio(url: string, ratio: number): void {
    if (!(ratio > 0)) {
      return;
    }
    if (ReaderImageCache.ratios.has(url)) {
      const idx: number = ReaderImageCache.ratioOrder.indexOf(url);
      if (idx >= 0) {
        ReaderImageCache.ratioOrder.splice(idx, 1);
      }
    }
    ReaderImageCache.ratios.set(url, ratio);
    ReaderImageCache.ratioOrder.push(url);
    while (ReaderImageCache.ratioOrder.length > ReaderImageCache.RATIO_CAP) {
      const evict: string = ReaderImageCache.ratioOrder[0];
      ReaderImageCache.ratioOrder.splice(0, 1);
      ReaderImageCache.ratios.delete(evict);
    }
  }

  /** 质量档位变化时清空像素缓存（宽高比与质量无关，保留） */
  static ensureQuality(quality: number): void {
    if (ReaderImageCache.pixelQuality !== quality) {
      ReaderImageCache.pixelQuality = quality;
      ReaderImageCache.maps.clear();
      ReaderImageCache.order = [];
    }
  }

  /** 先按质量失效像素缓存，再取缓存像素（质量变化时旧像素整体清空） */
  static getWithQuality(url: string, quality: number): image.PixelMap | undefined {
    ReaderImageCache.ensureQuality(quality);
    return ReaderImageCache.get(url);
  }

  /** 共享加载：下载 + 按质量降采样解码 + 反打乱重组 + 写缓存；失败返回 null（永不 reject） */
  static loadPixelMap(url: string, quality: number, ui: UIContext): Promise<image.PixelMap | null> {
    const key: string = `${quality}_${url}`;
    const exist: Promise<image.PixelMap | null> | undefined = ReaderImageCache.inflight.get(key);
    if (exist !== undefined) {
      return exist;
    }
    const task: Promise<image.PixelMap | null> = ReaderImageCache.doLoad(url, quality, ui)
      .then((pm: image.PixelMap | null) => {
        ReaderImageCache.inflight.delete(key);
        return pm;
      })
      .catch((e: Error) => {
        ReaderImageCache.inflight.delete(key);
        Logger.warn(TAG, `load failed: ${url} ${String(e)}`);
        return null;
      });
    ReaderImageCache.inflight.set(key, task);
    return task;
  }

  /** 预取相邻页（去重由 inflight/像素缓存保证） */
  static preload(urls: string[], quality: number, ui: UIContext): void {
    ReaderImageCache.ensureQuality(quality);
    for (let i = 0; i < urls.length; i++) {
      const u: string = urls[i];
      if (u.length === 0 || JmImage.isGif(u)) {
        continue;
      }
      if (ReaderImageCache.maps.has(u)) {
        continue;
      }
      ReaderImageCache.loadPixelMap(u, quality, ui);
    }
  }

  private static async doLoad(url: string, quality: number, ui: UIContext): Promise<image.PixelMap | null> {
    const cached: image.PixelMap | undefined = ReaderImageCache.get(url);
    if (cached !== undefined) {
      return cached;
    }
    const headers: Record<string, string> = JmImage.imgHeaders();
    let bytes: Uint8Array | null = await Network.getBytes(url, headers);
    if (bytes !== null && bytes.length > 0 && !JmImage.looksLikeImage(bytes)) {
      Logger.warn(TAG, `non-image bytes via http stack: len=${bytes.length} head=${JmImage.headHex(bytes)}`);
      bytes = null;
    }
    if (bytes === null || bytes.length === 0) {
      try {
        const ctx = ui.getHostContext();
        if (ctx !== undefined) {
          bytes = await Network.getBytesViaDownload(url, headers, ctx);
        }
      } catch (e) {
        Logger.warn(TAG, `fallback download unavailable: ${String(e)}`);
      }
      if (bytes !== null && bytes.length > 0 && !JmImage.looksLikeImage(bytes)) {
        Logger.warn(TAG, `non-image bytes via download stack: len=${bytes.length} head=${JmImage.headHex(bytes)}`);
        bytes = null;
      }
    }
    if (bytes === null || bytes.length === 0) {
      Logger.warn(TAG, `download failed (both stacks): ${url}`);
      return null;
    }
    const pm: image.PixelMap = await JmImage.decode(bytes, JmImage.maxEdgeForQuality(quality));
    const combined: image.PixelMap = await JmImage.recombine(pm, url);
    try {
      const info: image.ImageInfo = await combined.getImageInfo();
      if (info.size.width > 0 && info.size.height > 0) {
        ReaderImageCache.setRatio(url, info.size.width / info.size.height);
      }
    } catch (e) {
      Logger.warn(TAG, `getImageInfo failed: ${String(e)}`);
    }
    // 质量切换竞态防护：解码期间档位已变则丢弃本次结果
    if (ReaderImageCache.pixelQuality === quality) {
      ReaderImageCache.put(url, combined);
      return combined;
    }
    combined.release();
    return null;
  }
}

@Component
export struct ReaderImage {
  @Prop url: string = '';
  @Prop imageLayout: number = 0;
  @Prop fill: boolean = true;
  /** 双页模式：布局贴中线（布局0/1 按宽度适配铺满半屏，布局2 按高度适配靠内边对齐） */
  @Prop dual: boolean = false;
  @StorageProp('imageQuality') @Watch('onQualityChange') imgQuality: number = 0;
  @State pixelMap: image.PixelMap | undefined = undefined;
  @State useRaw: boolean = false;
  @State loadFailed: boolean = false;
  private loadedQuality: number = -1;

  aboutToAppear(): void {
    this.loadedQuality = this.imgQuality;
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

  private async load(): Promise<void> {
    const url: string = this.url;
    if (url.length === 0) {
      return;
    }
    if (JmImage.isGif(url)) {
      this.useRaw = true;
      return;
    }
    const cached: image.PixelMap | undefined = ReaderImageCache.getWithQuality(url, this.imgQuality);
    if (cached !== undefined) {
      this.pixelMap = cached;
      return;
    }
    const quality: number = this.imgQuality;
    const pm: image.PixelMap | null = await ReaderImageCache.loadPixelMap(url, quality, this.getUIContext());
    if (this.url !== url || this.loadedQuality !== quality) {
      return;
    }
    if (pm === null) {
      this.loadFailed = true;
      return;
    }
    this.pixelMap = pm;
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
        .backgroundColor('#000000')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
    } else if (this.fill && this.imageLayout === 2) {
      Image(source)
        .height('100%')
        .width('auto')
        .objectFit(ImageFit.Contain)
        .draggable(false)
        .backgroundColor('#000000')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
    } else {
      Image(source)
        .width('100%')
        .height('auto')
        .objectFit(ImageFit.Contain)
        .draggable(false)
        .backgroundColor('#000000')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
    }
  }

  build() {
    if (this.pixelMap !== undefined) {
      this.layoutImage(this.pixelMap)
    } else if (this.useRaw) {
      this.layoutImage(this.url)
    } else if (this.loadFailed) {
      if (this.fill) {
        Column({ space: 12 }) {
          Text('图片加载失败')
            .fontSize(14)
            .fontColor('#B3FFFFFF')
            .maxLines(1)
          Text('点击重试')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .maxLines(1)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#000000')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
        .onClick(() => {
          this.retry();
        })
      } else {
        Column({ space: 12 }) {
          Text('图片加载失败')
            .fontSize(14)
            .fontColor('#B3FFFFFF')
            .maxLines(1)
          Text('点击重试')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .maxLines(1)
        }
        .width('100%')
        .aspectRatio(this.placeRatio())
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#000000')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
        .onClick(() => {
          this.retry();
        })
      }
    } else if (this.fill) {
      Column({ space: 8 }) {
        LoadingProgress().width(40).height(40).color('#FFFFFF')
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#000000')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
    } else {
      Column({ space: 8 }) {
        LoadingProgress().width(40).height(40).color('#FFFFFF')
      }
      .width('100%')
      .aspectRatio(this.placeRatio())
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#000000')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM, SafeAreaEdge.TOP])
    }
  }
}
