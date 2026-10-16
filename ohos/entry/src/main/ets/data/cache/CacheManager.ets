// data/cache/CacheManager.ets - 缓存管理（占用统计 / 手动清理 / 按容量上限 LRU 淘汰）
// 统计口径：详情缓存（comic_cache 表 + download/detail/* 封面）+ cacheDir 临时图；
// 下载章节（download/ 下纯数字 photoId 目录）仅统计展示、永不清理；系统 Image 框架缓存不可控不计入。
import { common } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import { ComicCacheLruRow, Database } from '../database/Database';
import { DetailCache } from './DetailCache';
import { Network } from '../../common/Network';
import { ReaderImageCache } from '../../components/ReaderImage';
import { Settings } from '../preferences/Settings';
import { SettingsKeys } from '../../common/Constants';
import { Logger } from '../../common/Logger';

const TAG = 'CacheManager';
/** download 根（与 DetailCache.ets 一致）：detail/ 子目录=封面缓存，纯数字子目录=下载章节 */
const DOWNLOAD_ROOT = 'download';
/** 封面缓存子目录名（统计缓存/统计下载的分界线） */
const DETAIL_SUBDIR = 'detail';

export class CacheManager {
  /** 容量挡位上限（字节），索引 = 设置页 SettingSelect 选项：0=不限 1=200MB 2=100MB 3=50MB */
  static readonly GEAR_CAPS: number[] = [0, 500 * 1024 * 1024, 200 * 1024 * 1024, 100 * 1024 * 1024, 50 * 1024 * 1024];

  private static ctx: common.UIAbilityContext | null = null;

  static init(context: common.UIAbilityContext): void {
    CacheManager.ctx = context;
  }

  static gearCapBytes(gear: number): number {
    if (gear < 0 || gear >= CacheManager.GEAR_CAPS.length) {
      return 0;
    }
    return CacheManager.GEAR_CAPS[gear];
  }

  static async getGear(): Promise<number> {
    const gear: number = await Settings.getNumber(SettingsKeys.CACHE_GEAR, 0);
    return gear >= 0 && gear < CacheManager.GEAR_CAPS.length ? gear : 0;
  }

  static async setGear(gear: number): Promise<void> {
    await Settings.putNumber(SettingsKeys.CACHE_GEAR, gear);
  }

  /** 缓存占用：comic_cache 表 + download/detail/* 封面 + cacheDir 临时图 */
  static async statCache(): Promise<number> {
    let bytes: number = await Database.comicCacheBytes();
    bytes += CacheManager.walkBytes(CacheManager.pathOf(`${DOWNLOAD_ROOT}/${DETAIL_SUBDIR}`));
    bytes += CacheManager.statTempBytes();
    return bytes;
  }

  /** 下载章节占用（仅统计，永不清理；排除 detail 封面子目录） */
  static statDownloads(): number {
    const root: string = CacheManager.pathOf(DOWNLOAD_ROOT);
    if (root.length === 0) {
      return 0;
    }
    let total: number = 0;
    try {
      if (!fs.accessSync(root)) {
        return 0;
      }
      const names: string[] = fs.listFileSync(root);
      for (let i = 0; i < names.length; i++) {
        if (names[i] === DETAIL_SUBDIR) {
          continue;
        }
        total += CacheManager.walkBytes(`${root}/${names[i]}`);
      }
    } catch (e) {
      Logger.warn(TAG, `statDownloads failed: ${Logger.describe(e)}`);
    }
    return total;
  }

  /**
   * 手动清理：详情缓存（DB 行 + 封面目录）+ 临时图 + 网络/阅读器内存缓存。
   * 不动：下载章节、历史、追更、本地评论、登录态等用户数据。
   */
  static async clearAll(): Promise<void> {
    await Database.clearComicCache();
    const detailDir: string = CacheManager.pathOf(`${DOWNLOAD_ROOT}/${DETAIL_SUBDIR}`);
    try {
      if (detailDir.length > 0 && fs.accessSync(detailDir)) {
        fs.rmdirSync(detailDir);
      }
    } catch (e) {
      Logger.warn(TAG, `remove detail dir failed: ${Logger.describe(e)}`);
    }
    CacheManager.clearTemp();
    Network.clearCache();
    ReaderImageCache.clearAll();
    Logger.info(TAG, 'cache cleared (db+cover+temp+memory)');
  }

  /** 超上限淘汰：按 updateTime 从旧到新删详情缓存（DB 行+封面目录），降到上限的 90%；挡位 0=不限 */
  static async evictToGear(): Promise<void> {
    try {
      const gear: number = await CacheManager.getGear();
      const cap: number = CacheManager.gearCapBytes(gear);
      if (cap <= 0) {
        return;
      }
      const bytes: number = await CacheManager.statCache();
      if (bytes <= cap) {
        return;
      }
      const target: number = Math.floor(cap * 0.9);
      const rows: ComicCacheLruRow[] = await Database.queryComicCacheLru();
      let need: number = bytes - target;
      let removed: number = 0;
      for (let i = 0; i < rows.length && need > 0; i++) {
        await DetailCache.remove(rows[i].comicId, rows[i].source);
        need -= rows[i].bytes;
        removed++;
      }
      Logger.info(TAG, `evict gear=${gear} size=${bytes}->cap=${cap} removed=${removed} rows`);
    } catch (e) {
      Logger.warn(TAG, `evictToGear failed: ${Logger.describe(e)}`);
    }
  }

  /** 字节数格式化（设置页占用展示用） */
  static formatBytes(bytes: number): string {
    if (bytes >= 1024 * 1024 * 1024) {
      return `${(bytes / 1024 / 1024 / 1024).toFixed(1)} GB`;
    }
    if (bytes >= 1024 * 1024) {
      return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
    }
    if (bytes >= 1024) {
      return `${(bytes / 1024).toFixed(1)} KB`;
    }
    return `${bytes} B`;
  }

  // ---- internal ----

  private static pathOf(rel: string): string {
    if (CacheManager.ctx === null) {
      return '';
    }
    return `${CacheManager.ctx.filesDir}/${rel}`;
  }

  /** cacheDir 下 jm_*.img 临时文件总量（写入中的图不应计入，量小忽略不计） */
  private static statTempBytes(): number {
    if (CacheManager.ctx === null) {
      return 0;
    }
    const cacheDir: string = CacheManager.ctx.cacheDir;
    let total: number = 0;
    try {
      const names: string[] = fs.listFileSync(cacheDir);
      for (let i = 0; i < names.length; i++) {
        const name: string = names[i];
        if (name.startsWith('jm_') && name.endsWith('.img')) {
          const stat: fs.Stat = fs.statSync(`${cacheDir}/${name}`);
          if (stat.isFile()) {
            total += stat.size;
          }
        }
      }
    } catch (e) {
      Logger.warn(TAG, `statTempBytes failed: ${Logger.describe(e)}`);
    }
    return total;
  }

  private static clearTemp(): void {
    if (CacheManager.ctx === null) {
      return;
    }
    const cacheDir: string = CacheManager.ctx.cacheDir;
    try {
      const names: string[] = fs.listFileSync(cacheDir);
      for (let i = 0; i < names.length; i++) {
        const name: string = names[i];
        if (name.startsWith('jm_') && name.endsWith('.img')) {
          try {
            fs.unlinkSync(`${cacheDir}/${name}`);
          } catch (e) {
            Logger.warn(TAG, `remove temp failed: ${name} ${Logger.describe(e)}`);
          }
        }
      }
    } catch (e) {
      Logger.warn(TAG, `clearTemp failed: ${Logger.describe(e)}`);
    }
  }

  /** 递归统计目录字节数（不存在返回 0） */
  private static walkBytes(path: string): number {
    if (path.length === 0) {
      return 0;
    }
    let total: number = 0;
    try {
      if (!fs.accessSync(path)) {
        return 0;
      }
      const names: string[] = fs.listFileSync(path);
      for (let i = 0; i < names.length; i++) {
        const child: string = `${path}/${names[i]}`;
        try {
          const stat: fs.Stat = fs.statSync(child);
          if (stat.isDirectory()) {
            total += CacheManager.walkBytes(child);
          } else if (stat.isFile()) {
            total += stat.size;
          }
        } catch (e) {
          // 单个文件 stat 失败忽略
        }
      }
    } catch (e) {
      Logger.warn(TAG, `walkBytes failed: ${path} ${Logger.describe(e)}`);
    }
    return total;
  }
}
