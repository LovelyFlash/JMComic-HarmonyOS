// components/ReaderImage.ets - 阅读器图片（JM 分片重组 + LRU 像素缓存）
import { image } from '@kit.ImageKit';
import { Network } from '../common/Network';
import { JmImage } from '../common/JmImage';
import { Logger } from '../common/Logger';

const TAG = 'ReaderImage';

class ReaderImageCache {
  private static maps: Map<string, image.PixelMap> = new Map();
  private static order: string[] = [];
  private static readonly CAP: number = 12;

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
}

@Component
export struct ReaderImage {
  @Prop url: string = '';
  @Prop imageLayout: number = 0;
  @Prop fill: boolean = true;
  @State pixelMap: image.PixelMap | undefined = undefined;
  @State useRaw: boolean = false;
  @State loadFailed: boolean = false;

  aboutToAppear(): void {
    this.load();
  }

  private fit(): ImageFit {
    if (!this.fill) {
      return ImageFit.Contain;
    }
    if (this.imageLayout === 1) {
      return ImageFit.Fill;
    }
    if (this.imageLayout === 2) {
      return ImageFit.Cover;
    }
    return ImageFit.Contain;
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
    const cached: image.PixelMap | undefined = ReaderImageCache.get(url);
    if (cached !== undefined) {
      this.pixelMap = cached;
      return;
    }
    const headers: Record<string, string> = JmImage.imgHeaders();
    let bytes: Uint8Array | null = await Network.getBytes(url, headers);
    if (bytes !== null && bytes.length > 0 && !JmImage.looksLikeImage(bytes)) {
      Logger.warn(TAG, `non-image bytes via http stack: len=${bytes.length} head=${JmImage.headHex(bytes)}`);
      bytes = null;
    }
    if (bytes === null || bytes.length === 0) {
      try {
        const ctx = this.getUIContext().getHostContext();
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
    if (this.url !== url) {
      return;
    }
    if (bytes === null || bytes.length === 0) {
      Logger.warn(TAG, `download failed (both stacks): ${url}`);
      this.loadFailed = true;
      return;
    }
    try {
      const pm: image.PixelMap = await JmImage.decode(bytes);
      const combined: image.PixelMap = await JmImage.recombine(pm, url);
      if (this.url !== url) {
        return;
      }
      ReaderImageCache.put(url, combined);
      this.pixelMap = combined;
    } catch (e) {
      Logger.warn(TAG, `load failed: ${String(e)}`);
      this.loadFailed = true;
    }
  }

  private retry(): void {
    this.loadFailed = false;
    this.pixelMap = undefined;
    this.load();
  }

  build() {
    if (this.pixelMap !== undefined) {
      Image(this.pixelMap)
        .width('100%')
        .height(this.fill ? '100%' : 'auto')
        .objectFit(this.fit())
        .draggable(false)
        .backgroundColor('#000000')
    } else if (this.useRaw) {
      Image(this.url)
        .width('100%')
        .height(this.fill ? '100%' : 'auto')
        .objectFit(this.fit())
        .backgroundColor('#000000')
        .draggable(false)
    } else if (this.loadFailed) {
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
      .height(this.fill ? '100%' : 400)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#000000')
      .onClick(() => {
        this.retry();
      })
    } else {
      Column({ space: 8 }) {
        LoadingProgress().width(40).height(40).color('#FFFFFF')
      }
      .width('100%')
      .height(this.fill ? '100%' : 400)
      .justifyContent(FlexAlign.Center)
      .backgroundColor('#000000')
    }
  }
}
