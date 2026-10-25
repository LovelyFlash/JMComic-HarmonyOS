// data/cache/ImageCache.ets - 图片持久磁盘缓存（URL→字节，先缓存后网络；仅超容量上限时按时间淘汰）
// 规则：缓存常驻，不主动销毁；淘汰只在总量超挡位上限时触发，顺序=阅读页图→缩略图（缩略图最后淘汰），
// 同类型按最近使用时间从旧到新；阅读中漫画（pin）的资源永不淘汰。文件在 filesDir/img_cache/<md5(url)>.img，
// 元数据在 image_cache 表。封面/缩略图走 getCoverPixelMap（内存像素→已下载封面文件→磁盘缓存→网络写穿）。
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import { image } from '@kit.ImageKit';
import { ImageCacheRow, Database } from '../database/Database';
import { Network } from '../../common/Network';
import { JmImage } from '../../common/JmImage';
import { JmApi } from '../api/JmApi';
import { Settings } from '../preferences/Settings';
import { CACHE_GEAR_CAPS, SettingsKeys } from '../../common/Constants';
import { DetailCache } from './DetailCache';
import { Logger } from '../../common/Logger';

const TAG = 'ImageCache';

/** 缓存条目类型：0=阅读页图（最先淘汰） 1=缩略图/预览/封面（最后淘汰） */
export enum ImageCacheKind {
  PAGE = 0,
  THUMB = 1
}

export class ImageCache {
  private static ctx: common.UIAbilityContext | null = null;
  private static readonly DIR = 'img_cache';
  /** 封面解码最长边（列表展示位 ≤ ~460px，降采样省内存） */
  private static readonly COVER_MAX_EDGE: number = 512;
  /** 阅读中的漫画 id（ReaderPage 进出时设置）：页面图归因 + 淘汰保护 */
  static readingComicId: string = '';
  private static pinned: Set<string> = new Set();
  /** 写入后节流触发淘汰：距上次检查的最小间隔与最小累计新增字节，二者先到先查 */
  private static lastEvictCheck: number = 0;
  private static bytesSinceCheck: number = 0;
  private static readonly EVICT_CHECK_INTERVAL: number = 10 * 1000;
  private static readonly EVICT_CHECK_BYTES: number = 8 * 1024 * 1024;
  /** 封面像素内存缓存（LRU；淘汰只丢引用不 release，交给 GC，与 ReaderImageCache 同策略） */
  private static memMaps: Map<string, image.PixelMap> = new Map();
  private static memOrder: string[] = [];
  private static readonly MEM_CAP: number = 32;
  /** 同 URL 在途加载去重（列表复用组件并发请求同一封面时只下载解码一次） */
  private static inflight: Map<string, Promise<image.PixelMap | null>> = new Map();

  static init(context: common.UIAbilityContext): void {
    ImageCache.ctx = context;
  }

  // ---- 阅读中漫画 pin（进出阅读器时调用；被 pin 的 comicId 资源淘汰时跳过） ----

  static pinComic(comicId: string): void {
    if (comicId.length > 0) {
      ImageCache.pinned.add(comicId);
    }
  }

  static unpinComic(comicId: string): void {
    ImageCache.pinned.delete(comicId);
  }

  static isPinned(comicId: string): boolean {
    return comicId.length > 0 && ImageCache.pinned.has(comicId);
  }

  // ---- 字节缓存 ----

  /** 读磁盘缓存：命中返回字节并刷新最近使用时间；行/文件任一缺失按未命中处理并自愈删行 */
  static async get(url: string): Promise<Uint8Array | null> {
    if (url.length === 0) {
      return null;
    }
    const key: string = JmApi.md5Hex(url);
    if (key.length === 0) {
      return null;
    }
    const row: ImageCacheRow | null = await Database.queryImageCache(key);
    if (row === null) {
      return null;
    }
    const path: string = ImageCache.pathOf(key);
    try {
      if (path.length === 0 || !fs.accessSync(path)) {
        Database.removeImageCache(key).catch((e: Object) => {
          Logger.warn(TAG, `remove orphan row failed: ${Logger.describe(e)}`);
        });
        return null;
      }
      const stat: fs.Stat = fs.statSync(path);
      const buf: ArrayBuffer = new ArrayBuffer(stat.size);
      const file: fs.File = fs.openSync(path, fs.OpenMode.READ_ONLY);
      try {
        fs.readSync(file.fd, buf);
      } finally {
        fs.closeSync(file);
      }
      Database.touchImageCache(key).catch((e: Object) => {
        Logger.debug(TAG, `touch failed: ${Logger.describe(e)}`);
      });
      return new Uint8Array(buf);
    } catch (e) {
      Logger.warn(TAG, `get failed: ${Logger.describe(e)}`);
      return null;
    }
  }

  /** 写磁盘缓存（文件+元数据行），并节流触发超限淘汰；单图失败只丢弃该图 */
  static async put(url: string, bytes: Uint8Array, kind: number, comicId: string = ''): Promise<void> {
    if (url.length === 0 || bytes.length === 0 || ImageCache.ctx === null) {
      return;
    }
    const key: string = JmApi.md5Hex(url);
    if (key.length === 0) {
      return;
    }
    const path: string = ImageCache.pathOf(key);
    if (path.length === 0) {
      return;
    }
    try {
      const dir: string = `${ImageCache.ctx.filesDir}/${ImageCache.DIR}`;
      // mkdirSync 递归模式在目录已存在时也会抛 EEXIST，先探测再建
      if (!fs.accessSync(dir)) {
        fs.mkdirSync(dir, true);
      }
      const file: fs.File = fs.openSync(path,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        const ab: ArrayBuffer = bytes.buffer.slice(bytes.byteOffset,
          bytes.byteOffset + bytes.byteLength);
        fs.writeSync(file.fd, ab);
      } finally {
        fs.closeSync(file);
      }
      const row = new ImageCacheRow();
      row.key = key;
      row.url = url;
      row.comicId = comicId;
      row.kind = kind;
      row.bytes = bytes.length;
      row.updateTime = Date.now();
      await Database.upsertImageCache(row);
      ImageCache.maybeEvict(bytes.length).catch((e: Object) => {
        Logger.warn(TAG, `maybeEvict failed: ${Logger.describe(e)}`);
      });
    } catch (e) {
      const err = e as BusinessError;
      Logger.warn(TAG, `put failed: code=${err.code} msg=${err.message} path=${path}`);
    }
  }

  /** 缓存占用总字节（设置页统计用） */
  static async totalBytes(): Promise<number> {
    return await Database.imageCacheBytes();
  }

  /** 删除指定漫画的全部归因缓存条目（文件 + 元数据行 + 内存像素）；下载整本删除时联动调用 */
  static async removeByComic(comicId: string): Promise<void> {
    if (comicId.length === 0) {
      return;
    }
    const rows: ImageCacheRow[] = await Database.queryImageCacheByComic(comicId);
    for (const row of rows) {
      try {
        const path: string = ImageCache.pathOf(row.key);
        if (path.length > 0 && fs.accessSync(path)) {
          fs.unlinkSync(path);
        }
      } catch (e) {
        Logger.warn(TAG, `removeByComic unlink failed: ${row.key} ${Logger.describe(e)}`);
      }
      ImageCache.memDrop(row.url);
      await Database.removeImageCache(row.key);
    }
    if (rows.length > 0) {
      Logger.info(TAG, `removeByComic ${comicId}: ${rows.length} entries`);
    }
  }

  // ---- 封面/缩略图主入口（内存像素→已下载封面→磁盘→网络写穿） ----

  /**
   * 取封面/缩略图像素，优先级严格为：
   * ① 内存 LRU 像素 → ② 已下载漫画的本地封面文件（下载时落盘，离线可用）→
   * ③ 磁盘字节缓存 → ④ 双网络栈下载（成功即写穿缓存）。
   * 同 URL 并发去重；失败返回 null（永不 reject）。GIF 不走此路径（不重组不解码，系统路径直显）。
   */
  static getCoverPixelMap(url: string, comicId: string): Promise<image.PixelMap | null> {
    if (url.length === 0 || JmImage.isGif(url)) {
      return Promise.resolve(null);
    }
    const exist: Promise<image.PixelMap | null> | undefined = ImageCache.inflight.get(url);
    if (exist !== undefined) {
      return exist;
    }
    const task: Promise<image.PixelMap | null> = new Promise<image.PixelMap | null>((resolve) => {
      ImageCache.doGetCover(url, comicId).then((pm: image.PixelMap | null) => {
        ImageCache.inflight.delete(url);
        resolve(pm);
      }, (e: Object) => {
        ImageCache.inflight.delete(url);
        Logger.warn(TAG, `getCover failed: ${Logger.describe(e)}`);
        resolve(null);
      });
    });
    ImageCache.inflight.set(url, task);
    return task;
  }

  private static async doGetCover(url: string, comicId: string): Promise<image.PixelMap | null> {
    const mem: image.PixelMap | undefined = ImageCache.memGet(url);
    if (mem !== undefined) {
      return mem;
    }
    // ② 已下载优先：该漫画的本地封面文件命中即用（无需网络/磁盘缓存，离线可显示）
    const localBytes: Uint8Array | null = ImageCache.readLocalCover(comicId);
    if (localBytes !== null) {
      try {
        const lpm: image.PixelMap = await JmImage.decode(localBytes, ImageCache.COVER_MAX_EDGE);
        ImageCache.memPut(url, lpm);
        return lpm;
      } catch (e) {
        Logger.warn(TAG, `local cover decode failed, fallback: ${Logger.describe(e)}`);
      }
    }
    // ③ 磁盘字节缓存 ④ 网络（失败则 null）
    let bytes: Uint8Array | null = await ImageCache.get(url);
    if (bytes !== null && !JmImage.looksLikeImage(bytes)) {
      bytes = null;
    }
    if (bytes === null) {
      bytes = await ImageCache.fetchRemote(url);
      if (bytes !== null) {
        ImageCache.put(url, bytes, ImageCacheKind.THUMB, comicId).catch((e: Object) => {
          Logger.warn(TAG, `put cover failed: ${Logger.describe(e)}`);
        });
      }
    }
    if (bytes === null) {
      return null;
    }
    try {
      const pm: image.PixelMap = await JmImage.decode(bytes, ImageCache.COVER_MAX_EDGE);
      ImageCache.memPut(url, pm);
      return pm;
    } catch (e) {
      Logger.warn(TAG, `decode cover failed: ${Logger.describe(e)}`);
      return null;
    }
  }

  /** 读已下载漫画的本地封面文件（路径由 DetailCache 确定性推导；不存在/读失败返回 null） */
  private static readLocalCover(comicId: string): Uint8Array | null {
    const path: string = DetailCache.localCoverPath(comicId);
    if (path.length === 0) {
      return null;
    }
    try {
      const stat: fs.Stat = fs.statSync(path);
      const buf: ArrayBuffer = new ArrayBuffer(stat.size);
      const file: fs.File = fs.openSync(path, fs.OpenMode.READ_ONLY);
      try {
        fs.readSync(file.fd, buf);
      } finally {
        fs.closeSync(file);
      }
      const bytes: Uint8Array = new Uint8Array(buf);
      return JmImage.looksLikeImage(bytes) ? bytes : null;
    } catch (e) {
      Logger.debug(TAG, `read local cover failed: ${Logger.describe(e)}`);
      return null;
    }
  }

  /** 双网络栈取图（http 栈被拒走系统下载栈），魔数校验通过才返回 */
  private static async fetchRemote(url: string): Promise<Uint8Array | null> {
    let bytes: Uint8Array | null = await Network.getBytes(url, JmImage.imgHeaders());
    if ((bytes === null || bytes.length === 0) && ImageCache.ctx !== null) {
      try {
        bytes = await Network.getBytesViaDownload(url, JmImage.imgHeaders(), ImageCache.ctx);
      } catch (e) {
        bytes = null;
      }
    }
    if (bytes === null || bytes.length === 0 || !JmImage.looksLikeImage(bytes)) {
      return null;
    }
    return bytes;
  }

  /**
   * 封面是否已有本地可用缓存（内存像素/已下载封面文件/磁盘字节缓存任一命中）。
   * 详情页离线渲染相关推荐时过滤用：没有本地缓存的封面不展示，避免灰块占位。
   */
  static async hasCoverCache(url: string, comicId: string): Promise<boolean> {
    if (url.length === 0 || JmImage.isGif(url)) {
      return false;
    }
    if (ImageCache.memGet(url) !== undefined) {
      return true;
    }
    if (comicId.length > 0 && DetailCache.localCoverPath(comicId).length > 0) {
      return true;
    }
    const key: string = JmApi.md5Hex(url);
    if (key.length === 0) {
      return false;
    }
    const row: ImageCacheRow | null = await Database.queryImageCache(key);
    if (row === null) {
      return false;
    }
    const path: string = ImageCache.pathOf(key);
    try {
      return path.length > 0 && fs.accessSync(path);
    } catch (e) {
      return false;
    }
  }

  /**
   * 封面预取（联网时后台调用）：把相关推荐封面写入缓存，离线重进详情页时整排封面有图不灰块。
   * 已缓存的跳过；顺序拉取、单张失败不影响其余；最多前 10 张。
   */
  static async prefetchCovers(urls: string[], comicId: string): Promise<void> {
    const limit: number = Math.min(urls.length, 10);
    for (let i = 0; i < limit; i++) {
      const u: string = urls[i];
      if (u.length === 0 || JmImage.isGif(u)) {
        continue;
      }
      try {
        const hit: Uint8Array | null = await ImageCache.get(u);
        if (hit !== null && JmImage.looksLikeImage(hit)) {
          continue;
        }
        const bytes: Uint8Array | null = await ImageCache.fetchRemote(u);
        if (bytes !== null) {
          await ImageCache.put(u, bytes, ImageCacheKind.THUMB, comicId);
        }
      } catch (e) {
        Logger.debug(TAG, `prefetch cover failed: ${Logger.describe(e)}`);
      }
    }
  }

  // ---- 淘汰（仅超上限时触发） ----

  /**
   * 淘汰指定类型条目：最近使用从旧到新删，pin 中漫画跳过，最多释放 maxBytes；
   * 返回实际释放字节数。CacheManager 编排总淘汰时按类型分阶段调用（页图→详情→缩略图）。
   */
  static async evictKind(kind: number, maxBytes: number): Promise<number> {
    if (maxBytes <= 0) {
      return 0;
    }
    const rows: ImageCacheRow[] = await Database.queryImageCacheLru(kind);
    let freed: number = 0;
    for (let i = 0; i < rows.length && freed < maxBytes; i++) {
      const row: ImageCacheRow = rows[i];
      if (ImageCache.isPinned(row.comicId)) {
        continue;
      }
      try {
        const path: string = ImageCache.pathOf(row.key);
        if (path.length > 0 && fs.accessSync(path)) {
          fs.unlinkSync(path);
        }
      } catch (e) {
        Logger.warn(TAG, `unlink failed: ${row.key} ${Logger.describe(e)}`);
      }
      ImageCache.memDrop(row.url);
      await Database.removeImageCache(row.key);
      freed += row.bytes;
    }
    return freed;
  }

  /** 写入后节流检查：仅图片缓存自身超挡位上限时按优先级淘汰（页图先于缩略图） */
  private static async maybeEvict(addedBytes: number): Promise<void> {
    ImageCache.bytesSinceCheck += addedBytes;
    const now: number = Date.now();
    if (now - ImageCache.lastEvictCheck < ImageCache.EVICT_CHECK_INTERVAL &&
      ImageCache.bytesSinceCheck < ImageCache.EVICT_CHECK_BYTES) {
      return;
    }
    ImageCache.lastEvictCheck = now;
    ImageCache.bytesSinceCheck = 0;
    const gear: number = await Settings.getNumber(SettingsKeys.CACHE_GEAR, 0);
    const cap: number = gear >= 0 && gear < CACHE_GEAR_CAPS.length ? CACHE_GEAR_CAPS[gear] : 0;
    if (cap <= 0) {
      return;
    }
    const total: number = await Database.imageCacheBytes();
    if (total <= cap) {
      return;
    }
    let need: number = total - Math.floor(cap * 0.9);
    need -= await ImageCache.evictKind(ImageCacheKind.PAGE, need);
    need -= await ImageCache.evictKind(ImageCacheKind.THUMB, need);
    Logger.info(TAG, `evict on write: size=${total} cap=${cap} remainNeed=${need}`);
  }

  /** 手动清理：磁盘目录 + 元数据行 + 内存像素（调用方 CacheManager.clearAll 统一编排） */
  static async clear(): Promise<void> {
    ImageCache.memMaps.clear();
    ImageCache.memOrder = [];
    if (ImageCache.ctx !== null) {
      const dir: string = `${ImageCache.ctx.filesDir}/${ImageCache.DIR}`;
      try {
        if (fs.accessSync(dir)) {
          fs.rmdirSync(dir);
        }
      } catch (e) {
        Logger.warn(TAG, `remove dir failed: ${Logger.describe(e)}`);
      }
    }
    await Database.clearImageCache();
    Logger.info(TAG, 'image cache cleared');
  }

  // ---- internal ----

  private static pathOf(key: string): string {
    if (ImageCache.ctx === null) {
      return '';
    }
    return `${ImageCache.ctx.filesDir}/${ImageCache.DIR}/${key}.img`;
  }

  private static memGet(url: string): image.PixelMap | undefined {
    const pm: image.PixelMap | undefined = ImageCache.memMaps.get(url);
    if (pm !== undefined) {
      const idx: number = ImageCache.memOrder.indexOf(url);
      if (idx >= 0) {
        ImageCache.memOrder.splice(idx, 1);
      }
      ImageCache.memOrder.push(url);
    }
    return pm;
  }

  private static memPut(url: string, pm: image.PixelMap): void {
    if (ImageCache.memMaps.has(url)) {
      const idx: number = ImageCache.memOrder.indexOf(url);
      if (idx >= 0) {
        ImageCache.memOrder.splice(idx, 1);
      }
    }
    ImageCache.memMaps.set(url, pm);
    ImageCache.memOrder.push(url);
    while (ImageCache.memOrder.length > ImageCache.MEM_CAP) {
      const evict: string = ImageCache.memOrder[0];
      ImageCache.memOrder.splice(0, 1);
      ImageCache.memMaps.delete(evict);
    }
  }

  private static memDrop(url: string): void {
    ImageCache.memMaps.delete(url);
    const idx: number = ImageCache.memOrder.indexOf(url);
    if (idx >= 0) {
      ImageCache.memOrder.splice(idx, 1);
    }
  }
}
