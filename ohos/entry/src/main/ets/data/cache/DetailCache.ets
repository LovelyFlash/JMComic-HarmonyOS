// data/cache/DetailCache.ets - 已下载漫画的详情/封面/首页评论本地缓存（离线秒开用）
import { common } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import { Chapter } from '../model/Chapter';
import { Comic } from '../model/Comic';
import { JmApi, JmComment, JmCommentPage } from '../api/JmApi';
import { ComicCacheRow, Database } from '../database/Database';
import { Settings } from '../preferences/Settings';
import { SettingsKeys } from '../../common/Constants';
import { Network } from '../../common/Network';
import { JmImage } from '../../common/JmImage';
import { Logger } from '../../common/Logger';

const TAG = 'DetailCache';
/** 封面文件落于 filesDir/download/detail/{comicId}/cover（download 根与章节文件同级，章节目录为纯数字 photoId 不冲突） */
const ROOT_DIR = 'download';

export class DetailCache {
  private static ctx: common.UIAbilityContext | null = null;

  static init(context: common.UIAbilityContext): void {
    DetailCache.ctx = context;
  }

  /** 双网络栈取图：http 栈被拒/返回非图片时走系统下载栈兜底（与阅读器/下载器同链路），失败返回 null */
  private static async fetchImage(url: string): Promise<Uint8Array | null> {
    let bytes: Uint8Array | null = await Network.getBytes(url, JmImage.imgHeaders());
    const ctx: common.UIAbilityContext | null = DetailCache.ctx;
    if ((bytes === null || bytes.length === 0) && ctx !== null) {
      try {
        bytes = await Network.getBytesViaDownload(url, JmImage.imgHeaders(), ctx);
      } catch (e) {
        bytes = null;
      }
    }
    if (bytes === null || bytes.length === 0 || !JmImage.looksLikeImage(bytes)) {
      return null;
    }
    return bytes;
  }

  /** 封面自愈：本地文件缺失时（旧版本下载）后台补抓一次，已有文件直接跳过 */
  static async ensureCover(comicId: string, coverUrl: string): Promise<void> {
    if (comicId.length === 0 || coverUrl.length === 0 || DetailCache.localCoverPath(comicId).length > 0) {
      return;
    }
    const bytes: Uint8Array | null = await DetailCache.fetchImage(coverUrl);
    if (bytes !== null) {
      DetailCache.writeCover(comicId, bytes);
      Logger.info(TAG, `cover healed ${comicId} len=${bytes.length}`);
    }
  }

  /**
   * 下载入队时触发（受「下载时保存详情数据」开关控制）：
   * 保存详情字段 + 章节列表 + 首页评论 + 封面文件；相关推荐按需求不保存。
   * 全程容错：任何一步失败只影响对应部分，不阻断下载。
   */
  static async capture(comicId: string, source: string, comic?: Comic): Promise<void> {
    try {
      const enabled: boolean = await Settings.getBool(SettingsKeys.SAVE_DETAIL_ON_DOWNLOAD, true);
      if (!enabled) {
        return;
      }
      let detail: Comic | null = comic !== undefined ? comic : null;
      if (detail === null) {
        if (source !== 'jm') {
          return;
        }
        detail = await JmApi.getComicInfo(comicId);
      }
      if (detail === null) {
        return;
      }
      let comments: JmComment[] = [];
      let maxPage: number = 1;
      if (source === 'jm') {
        try {
          const page: JmCommentPage = await JmApi.getComments(comicId, 1);
          comments = page.comments;
          maxPage = page.maxPage;
        } catch (e) {
          Logger.warn(TAG, `capture comments failed: ${Logger.describe(e)}`);
        }
      }
      let coverBytes: Uint8Array | null = null;
      if (detail.coverUrl.length > 0) {
        coverBytes = await DetailCache.fetchImage(detail.coverUrl);
      }
      await DetailCache.save(detail, source, comments, maxPage, coverBytes);
      Logger.info(TAG, `captured ${comicId} chapters=${detail.chapters.length} comments=${comments.length}` +
        ` cover=${coverBytes !== null}`);
    } catch (e) {
      Logger.warn(TAG, `capture failed: ${comicId} ${Logger.describe(e)}`);
    }
  }

  /** 详情本地秒开入口：返回缓存 Comic（relatedComics 恒为空，按需求不保存） */
  static async loadComic(comicId: string, source: string): Promise<Comic | null> {
    const row: ComicCacheRow | null = await Database.queryComicCache(comicId, source);
    if (row === null) {
      return null;
    }
    const comic: Comic = new Comic();
    comic.id = row.comicId;
    comic.source = row.source;
    comic.title = row.title;
    comic.coverUrl = row.coverUrl;
    comic.description = row.description;
    comic.author = row.author;
    comic.categories = DetailCache.parseStringArray(row.categoriesJson);
    comic.likes = row.likes;
    comic.comments = row.commentCount;
    comic.chapters = DetailCache.parseChapters(row.chaptersJson);
    return comic;
  }

  /** 首页评论本地秒开入口 */
  static async loadComments(comicId: string, source: string): Promise<JmCommentPage | null> {
    const row: ComicCacheRow | null = await Database.queryComicCache(comicId, source);
    if (row === null) {
      return null;
    }
    const page: JmCommentPage = new JmCommentPage();
    page.comments = DetailCache.parseComments(row.commentsJson);
    page.maxPage = row.commentMaxPage > 0 ? row.commentMaxPage : 1;
    return page;
  }

  /** 联网刷新成功后同步更新详情字段（保留既有评论缓存，评论由 CommentsPage 刷新回写） */
  static async updateComic(comic: Comic, source: string): Promise<void> {
    try {
      const old: ComicCacheRow | null = await Database.queryComicCache(comic.id, source);
      if (old === null) {
        return;
      }
      const row: ComicCacheRow = DetailCache.comicToRow(comic, source);
      row.commentsJson = old.commentsJson;
      row.commentMaxPage = old.commentMaxPage;
      await Database.upsertComicCache(row);
    } catch (e) {
      Logger.warn(TAG, `updateComic failed: ${comic.id} ${Logger.describe(e)}`);
    }
  }

  /** 评论页首页联网成功后回写，保持离线数据新鲜 */
  static async saveComments(comicId: string, source: string, comments: JmComment[], maxPage: number): Promise<void> {
    try {
      const old: ComicCacheRow | null = await Database.queryComicCache(comicId, source);
      if (old === null) {
        return;
      }
      old.commentsJson = DetailCache.commentsToJson(comments);
      old.commentMaxPage = maxPage > 0 ? maxPage : 1;
      await Database.upsertComicCache(old);
    } catch (e) {
      Logger.warn(TAG, `saveComments failed: ${comicId} ${Logger.describe(e)}`);
    }
  }

  /** 封面本地路径（文件不存在返回空串）；路径确定性推导，无需查库 */
  static localCoverPath(comicId: string): string {
    if (DetailCache.ctx === null || comicId.length === 0) {
      return '';
    }
    const path: string = `${DetailCache.ctx.filesDir}/${ROOT_DIR}/detail/${comicId}/cover`;
    try {
      return fs.accessSync(path) ? path : '';
    } catch (e) {
      return '';
    }
  }

  /** 删除整本缓存：DB 行 + 封面目录（下载删除时一并调用） */
  static async remove(comicId: string, source: string): Promise<void> {
    await Database.removeComicCache(comicId, source);
    if (DetailCache.ctx === null) {
      return;
    }
    const dir: string = `${DetailCache.ctx.filesDir}/${ROOT_DIR}/detail/${comicId}`;
    try {
      if (fs.accessSync(dir)) {
        fs.rmdirSync(dir);
      }
    } catch (e) {
      Logger.warn(TAG, `remove cover dir failed: ${dir} ${Logger.describe(e)}`);
    }
  }

  private static async save(comic: Comic, source: string, comments: JmComment[], maxPage: number,
    coverBytes: Uint8Array | null): Promise<void> {
    const row: ComicCacheRow = DetailCache.comicToRow(comic, source);
    row.commentsJson = DetailCache.commentsToJson(comments);
    row.commentMaxPage = maxPage > 0 ? maxPage : 1;
    if (coverBytes !== null) {
      DetailCache.writeCover(comic.id, coverBytes);
    }
    await Database.upsertComicCache(row);
  }

  private static comicToRow(comic: Comic, source: string): ComicCacheRow {
    const row: ComicCacheRow = new ComicCacheRow();
    row.comicId = comic.id;
    row.source = source;
    row.title = comic.title;
    row.coverUrl = comic.coverUrl;
    row.description = comic.description;
    row.author = comic.author;
    row.likes = comic.likes;
    row.commentCount = comic.comments;
    row.categoriesJson = JSON.stringify(comic.categories);
    row.chaptersJson = DetailCache.chaptersToJson(comic.chapters);
    return row;
  }

  private static writeCover(comicId: string, bytes: Uint8Array): void {
    if (DetailCache.ctx === null || comicId.length === 0) {
      return;
    }
    const dir: string = `${DetailCache.ctx.filesDir}/${ROOT_DIR}/detail/${comicId}`;
    const path: string = `${dir}/cover`;
    try {
      fs.mkdirSync(dir, true);
      const file: fs.File = fs.openSync(path,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        let offset: number = 0;
        while (offset < bytes.byteLength) {
          const buf: ArrayBuffer = bytes.buffer.slice(bytes.byteOffset + offset,
            bytes.byteOffset + bytes.byteLength);
          const written: number = fs.writeSync(file.fd, buf);
          if (written <= 0) {
            throw new Error('write returned 0');
          }
          offset += written;
        }
      } finally {
        fs.closeSync(file);
      }
    } catch (e) {
      Logger.warn(TAG, `write cover failed: ${comicId} ${Logger.describe(e)}`);
    }
  }

  // ---- JSON 序列化（ArkTS 无对象字面量类型断言，统一 Record 中转） ----

  private static chaptersToJson(chapters: Chapter[]): string {
    const arr: Record<string, Object>[] = [];
    for (const c of chapters) {
      const r: Record<string, Object> = {
        'id': c.id, 'title': c.title, 'comicId': c.comicId,
        'order': c.order, 'pages': c.pages,
        'isLocked': c.isLocked, 'needsLogin': c.needsLogin
      };
      arr.push(r);
    }
    return JSON.stringify(arr);
  }

  private static parseChapters(json: string): Chapter[] {
    const out: Chapter[] = [];
    if (json.length === 0) {
      return out;
    }
    try {
      const arr: Object[] = JSON.parse(json) as Object[];
      for (const item of arr) {
        const r: Record<string, Object> = item as Record<string, Object>;
        const c: Chapter = new Chapter();
        c.id = DetailCache.str(r, 'id');
        c.title = DetailCache.str(r, 'title');
        c.comicId = DetailCache.str(r, 'comicId');
        c.order = DetailCache.num(r, 'order');
        c.pages = DetailCache.num(r, 'pages');
        c.isLocked = DetailCache.bool(r, 'isLocked');
        c.needsLogin = DetailCache.bool(r, 'needsLogin');
        out.push(c);
      }
    } catch (e) {
      Logger.warn(TAG, `parseChapters failed: ${Logger.describe(e)}`);
    }
    return out;
  }

  private static commentsToJson(comments: JmComment[]): string {
    const arr: Record<string, Object>[] = [];
    for (const c of comments) {
      arr.push(DetailCache.commentToRecord(c));
    }
    return JSON.stringify(arr);
  }

  private static commentToRecord(c: JmComment): Record<string, Object> {
    const replies: Record<string, Object>[] = [];
    for (const r of c.replies) {
      replies.push(DetailCache.commentToRecord(r));
    }
    const rec: Record<string, Object> = {
      'id': c.id, 'avatar': c.avatar, 'username': c.username,
      'time': c.time, 'content': c.content, 'replies': replies
    };
    return rec;
  }

  private static parseComments(json: string): JmComment[] {
    const out: JmComment[] = [];
    if (json.length === 0) {
      return out;
    }
    try {
      const arr: Object[] = JSON.parse(json) as Object[];
      for (const item of arr) {
        out.push(DetailCache.recordToComment(item as Record<string, Object>));
      }
    } catch (e) {
      Logger.warn(TAG, `parseComments failed: ${Logger.describe(e)}`);
    }
    return out;
  }

  private static recordToComment(r: Record<string, Object>): JmComment {
    const c: JmComment = new JmComment();
    c.id = DetailCache.str(r, 'id');
    c.avatar = DetailCache.str(r, 'avatar');
    c.username = DetailCache.str(r, 'username');
    c.time = DetailCache.str(r, 'time');
    c.content = DetailCache.str(r, 'content');
    const repliesField: Object | undefined = r['replies'];
    if (repliesField !== undefined && repliesField !== null && Array.isArray(repliesField)) {
      const replies: Object[] = repliesField as Object[];
      for (const item of replies) {
        c.replies.push(DetailCache.recordToComment(item as Record<string, Object>));
      }
    }
    return c;
  }

  private static parseStringArray(json: string): string[] {
    const out: string[] = [];
    if (json.length === 0) {
      return out;
    }
    try {
      const arr: Object[] = JSON.parse(json) as Object[];
      for (const item of arr) {
        out.push(String(item));
      }
    } catch (e) {
      Logger.warn(TAG, `parseStringArray failed: ${Logger.describe(e)}`);
    }
    return out;
  }

  private static str(r: Record<string, Object>, key: string): string {
    const v: Object | undefined = r[key];
    return v !== undefined && v !== null ? String(v) : '';
  }

  private static num(r: Record<string, Object>, key: string): number {
    const v: Object | undefined = r[key];
    if (v === undefined || v === null) {
      return 0;
    }
    const n: number = Number(v);
    return Number.isNaN(n) ? 0 : n;
  }

  private static bool(r: Record<string, Object>, key: string): boolean {
    const v: Object | undefined = r[key];
    return v !== undefined && v !== null && String(v) === 'true';
  }
}
