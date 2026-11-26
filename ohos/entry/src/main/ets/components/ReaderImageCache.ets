// components/ReaderImageCache.ets - 阅读器图片缓存、加载队列与 LRU（从 ReaderImage 拆出）
import { image } from '@kit.ImageKit';
import { Network } from '../common/Network';
import { JmImage } from '../common/JmImage';
import { ImgLineSpeedTest } from '../data/api/ImgLineSpeedTest';
import { DownloadManager } from '../data/download/DownloadManager';
import { ImageCache, ImageCacheKind } from '../data/cache/ImageCache';
import { Logger } from '../common/Logger';

const TAG = 'ReaderImage';

export class ReaderImageCache {
  private static maps: Map<string, image.PixelMap> = new Map();
  private static order: string[] = [];
  private static readonly CAP: number = 12;
  /** 单张页面像素字节数：用于字节预算淘汰，避免长图 × 12 张把内存打爆 */
  private static sizes: Map<string, number> = new Map();
  private static totalBytes: number = 0;
  /** 阅读器像素缓存总预算（RGBA，含长图；按最近使用从旧到新淘汰） */
  private static readonly BYTE_CAP: number = 96 * 1024 * 1024;
  /** URL → 宽高比(w/h)：像素被淘汰后占位仍按真实比例预留高度，消除连续滚动回读跳变 */
  private static ratios: Map<string, number> = new Map();
  private static ratioOrder: string[] = [];
  private static readonly RATIO_CAP: number = 1200;
  /** 进行中的加载（同一 URL 同一质量只下载解码一次） */
  private static inflight: Map<string, Promise<image.PixelMap | null>> = new Map();
  /** 并发限流：最多同时跑 MAX_CONCURRENT 个；后台预取最多占 MAX_BG_CONCURRENT 个，始终留 ≥1 槽给可见页 */
  private static readonly MAX_CONCURRENT: number = 3;
  private static readonly MAX_BG_CONCURRENT: number = 2;
  /** 单任务看门狗（兜底）：超时按失败收尾，保证槽位与 inflight 必被释放，队列永不永久卡死 */
  private static readonly TASK_TIMEOUT: number = 120 * 1000;
  private static running: number = 0;
  private static runningBg: number = 0;
  /** 后台预取队列（FIFO，仅在可见页队列为空时消费） */
  private static pending: Array<() => void> = [];
  /** 可见页队列（优先消费，防止预取/网络挂起堵死当前页） */
  private static pendingPriority: Array<() => void> = [];
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

  static put(url: string, pm: image.PixelMap, bytes: number = 0): void {
    if (ReaderImageCache.maps.has(url)) {
      const idx: number = ReaderImageCache.order.indexOf(url);
      if (idx >= 0) {
        ReaderImageCache.order.splice(idx, 1);
      }
      const oldBytes: number | undefined = ReaderImageCache.sizes.get(url);
      if (oldBytes !== undefined) {
        ReaderImageCache.totalBytes -= oldBytes;
      }
    }
    const pixelBytes: number = bytes > 0 ? bytes : 0;
    ReaderImageCache.maps.set(url, pm);
    ReaderImageCache.sizes.set(url, pixelBytes);
    ReaderImageCache.totalBytes += pixelBytes;
    ReaderImageCache.order.push(url);
    while (ReaderImageCache.order.length > ReaderImageCache.CAP ||
      ReaderImageCache.totalBytes > ReaderImageCache.BYTE_CAP) {
      const evict: string = ReaderImageCache.order[0];
      ReaderImageCache.order.splice(0, 1);
      ReaderImageCache.maps.delete(evict);
      const evictBytes: number | undefined = ReaderImageCache.sizes.get(evict);
      if (evictBytes !== undefined) {
        ReaderImageCache.totalBytes -= evictBytes;
        ReaderImageCache.sizes.delete(evict);
      }
      if (ReaderImageCache.order.length === 0) {
        break;
      }
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
      ReaderImageCache.sizes.clear();
      ReaderImageCache.totalBytes = 0;
    }
  }

  /** 手动清理阅读器缓存：仅清缓存引用，不 release 仍在显示的 PixelMap（由 GC 回收）；比例与在途加载保留 */
  static clearAll(): void {
    ReaderImageCache.maps.clear();
    ReaderImageCache.order = [];
    ReaderImageCache.sizes.clear();
    ReaderImageCache.totalBytes = 0;
  }

  /** 先按质量失效像素缓存，再取缓存像素（质量变化时旧像素整体清空） */
  static getWithQuality(url: string, quality: number): image.PixelMap | undefined {
    ReaderImageCache.ensureQuality(quality);
    return ReaderImageCache.get(url);
  }

  /**
   * 共享加载：下载 + 按质量降采样解码 + 反打乱重组 + 写缓存；失败返回 null（永不 reject）。
   * 双队列限流：可见页（priority）优先消费，预取最多占 MAX_BG_CONCURRENT 槽（留 ≥1 槽给可见页）；
   * 每任务带看门狗超时，任何挂起都以失败收尾 → 槽位/inflight 必被释放，队列永不永久卡死。
   */
  static loadPixelMap(url: string, quality: number, ui: UIContext, priority: boolean = false):
    Promise<image.PixelMap | null> {
    const key: string = `${quality}_${url}`;
    const exist: Promise<image.PixelMap | null> | undefined = ReaderImageCache.inflight.get(key);
    if (exist !== undefined) {
      Logger.debug(TAG, `join inflight: ${key}`);
      return exist;
    }
    let settle: (pm: image.PixelMap | null) => void = (_pm: image.PixelMap | null) => {
    };
    const task: Promise<image.PixelMap | null> = new Promise<image.PixelMap | null>((resolve) => {
      settle = resolve;
    });
    ReaderImageCache.inflight.set(key, task);
    const isBg: boolean = !priority;
    const enqueuedAt: number = Date.now();
    Logger.debug(TAG, `enqueue ${isBg ? 'B' : 'P'} run=${ReaderImageCache.running}` +
      `/bg=${ReaderImageCache.runningBg} q=${ReaderImageCache.pendingPriority.length}` +
      `/${ReaderImageCache.pending.length} ${key}`);
    const start = (): void => {
      ReaderImageCache.running++;
      if (isBg) {
        ReaderImageCache.runningBg++;
      }
      const waitMs: number = Date.now() - enqueuedAt;
      if (waitMs > 3000) {
        Logger.warn(TAG, `slow queue wait ${waitMs}ms: ${key}`);
      }
      Logger.debug(TAG, `start ${isBg ? 'B' : 'P'} wait=${waitMs}ms run=${ReaderImageCache.running}` +
        `/bg=${ReaderImageCache.runningBg} ${key}`);
      let finished: boolean = false;
      let timedOut: boolean = false;
      let timer: number = -1;
      const done = (pm: image.PixelMap | null): void => {
        if (finished) {
          return;
        }
        finished = true;
        if (timer >= 0) {
          clearTimeout(timer);
        }
        ReaderImageCache.running--;
        if (isBg) {
          ReaderImageCache.runningBg--;
        }
        ReaderImageCache.inflight.delete(key);
        Logger.debug(TAG, `done ${isBg ? 'B' : 'P'} ${pm !== null ? 'ok' : 'null'} cost=${Date.now() - enqueuedAt}ms` +
          ` run=${ReaderImageCache.running}/bg=${ReaderImageCache.runningBg}` +
          ` q=${ReaderImageCache.pendingPriority.length}/${ReaderImageCache.pending.length} ${key}`);
        ReaderImageCache.runNext();
        settle(pm);
      };
      timer = setTimeout(() => {
        Logger.warn(TAG, `load watchdog timeout (${ReaderImageCache.TASK_TIMEOUT}ms): ${url}`);
        timedOut = true;
        done(null);
      }, ReaderImageCache.TASK_TIMEOUT);
      ReaderImageCache.doLoad(url, quality, ui).then(
        (pm: image.PixelMap | null) => {
          // 看门狗已失败收尾：底层迟到的 PixelMap 不再有调用方，必须主动释放
          if (timedOut && pm !== null) {
            pm.release();
          }
          done(pm);
        },
        (e: Object) => {
          Logger.warn(TAG, `load failed: ${url} ${Logger.describe(e)}`);
          done(null);
        }
      );
    };
    if (priority) {
      ReaderImageCache.pendingPriority.unshift(start);
    } else {
      ReaderImageCache.pending.push(start);
    }
    ReaderImageCache.runNext();
    return task;
  }

  /** 队列调度：可见页队列优先；预取仅在可见页排队为空且其并发未超限时消费 */
  private static runNext(): void {
    while (ReaderImageCache.running < ReaderImageCache.MAX_CONCURRENT) {
      if (ReaderImageCache.pendingPriority.length > 0) {
        const nextPriority: (() => void) | undefined = ReaderImageCache.pendingPriority.shift();
        if (nextPriority !== undefined) {
          nextPriority();
          continue;
        }
      }
      if (ReaderImageCache.pendingPriority.length === 0 &&
        ReaderImageCache.runningBg < ReaderImageCache.MAX_BG_CONCURRENT &&
        ReaderImageCache.pending.length > 0) {
        const nextBg: (() => void) | undefined = ReaderImageCache.pending.shift();
        if (nextBg !== undefined) {
          nextBg();
          continue;
        }
      }
      break;
    }
  }

  /** 预取相邻页（去重由 inflight/像素缓存保证，入队尾被可见页插队） */
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
    const t0: number = Date.now();
    const cached: image.PixelMap | undefined = ReaderImageCache.get(url);
    if (cached !== undefined) {
      Logger.debug(TAG, `hit pixel cache: ${url}`);
      return cached;
    }
    // 离线优先：已下载页面直读本地文件（下载时已反打乱并落盘，无需重组）；解码失败则回退网络
    // localHit 含旧沙箱根回退（公共目录迁移窗口期同名文件仍可读）
    const localPath: string = await DownloadManager.localHit(url);
    if (localPath.length > 0) {
      const localBytes: Uint8Array | null = await DownloadManager.readLocal(localPath);
      if (localBytes !== null && localBytes.length > 0) {
        try {
          const pm: image.PixelMap = await JmImage.decode(localBytes, JmImage.maxEdgeForQuality(quality));
          Logger.debug(TAG, `local ok ${Date.now() - t0}ms ${localPath}`);
          return await ReaderImageCache.settle(url, quality, pm);
        } catch (e) {
          Logger.warn(TAG, `local decode failed, fallback to network: ${Logger.describe(e)}`);
        }
      } else {
        Logger.warn(TAG, `local read empty: ${localPath}`);
      }
    } else {
      Logger.debug(TAG, `local miss: ${url}`);
    }
    // 持久缓存：上次读过的原图字节（仍为打乱态），解码+重组后复用，省一次网络往返
    const diskBytes: Uint8Array | null = await ImageCache.get(url);
    if (diskBytes !== null && diskBytes.length > 0 && JmImage.looksLikeImage(diskBytes)) {
      try {
        const dpm: image.PixelMap = await JmImage.decode(diskBytes, JmImage.maxEdgeForQuality(quality));
        const dcombined: image.PixelMap = await JmImage.recombine(dpm, url);
        Logger.debug(TAG, `disk ok ${Date.now() - t0}ms: ${url}`);
        return await ReaderImageCache.settle(url, quality, dcombined);
      } catch (e) {
        Logger.warn(TAG, `disk cache decode failed, fallback to network: ${Logger.describe(e)}`);
      }
    }
    // 本地与缓存都未命中：离线快速失败（此前会走双网络栈各等一次超时+测速，弱网长时间转圈）
    if (!await Network.isOnline()) {
      Logger.info(TAG, `offline, skip network fetch: ${url}`);
      return null;
    }
    const headers: Record<string, string> = JmImage.imgHeaders();
    Logger.debug(TAG, `net fetch start ${Date.now() - t0}ms: ${url}`);
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
        Logger.warn(TAG, `fallback download unavailable: ${Logger.describe(e)}`);
      }
      if (bytes !== null && bytes.length > 0 && !JmImage.looksLikeImage(bytes)) {
        Logger.warn(TAG, `non-image bytes via download stack: len=${bytes.length} head=${JmImage.headHex(bytes)}`);
        bytes = null;
      }
    }
    if (bytes === null || bytes.length === 0) {
      Logger.warn(TAG, `download failed (both stacks): ${url}`);
      // 图片源兜底：双栈失败且开关开 + 1h 冷却时后台测速切最快线路（内部容错，不阻断加载）
      ImgLineSpeedTest.respeedIfNeeded().catch((e: Object) => {
        Logger.warn(TAG, `respeedIfNeeded failed: ${Logger.describe(e)}`);
      });
      return null;
    }
    // 写穿持久缓存（打乱态原图字节 + 阅读中漫画归因，淘汰时受 pin 保护）
    ImageCache.put(url, bytes, ImageCacheKind.PAGE, ImageCache.readingComicId).catch((e: Object) => {
      Logger.warn(TAG, `ImageCache.put failed: ${Logger.describe(e)}`);
    });
    const pm: image.PixelMap = await JmImage.decode(bytes, JmImage.maxEdgeForQuality(quality));
    const combined: image.PixelMap = await JmImage.recombine(pm, url);
    Logger.debug(TAG, `net ok len=${bytes.length} ${Date.now() - t0}ms: ${url}`);
    return await ReaderImageCache.settle(url, quality, combined);
  }

  /** 收尾：记宽高比 + 质量竞态检查 + 入像素缓存（失败/竞态丢弃并释放像素） */
  private static async settle(url: string, quality: number, pm: image.PixelMap): Promise<image.PixelMap | null> {
    let pixelBytes: number = 0;
    try {
      const info: image.ImageInfo = await pm.getImageInfo();
      if (info.size.width > 0 && info.size.height > 0) {
        ReaderImageCache.setRatio(url, info.size.width / info.size.height);
        pixelBytes = info.size.width * info.size.height * 4;
      }
    } catch (e) {
      Logger.warn(TAG, `getImageInfo failed: ${Logger.describe(e)}`);
    }
    if (ReaderImageCache.pixelQuality === quality) {
      ReaderImageCache.put(url, pm, pixelBytes);
      return pm;
    }
    pm.release();
    return null;
  }
}
