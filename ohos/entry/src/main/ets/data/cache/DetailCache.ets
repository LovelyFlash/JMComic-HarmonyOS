// data/cache/DetailCache.ets - 已下载漫画的详情/封面/首页评论本地缓存（离线秒开用）
import { common } from '@kit.AbilityKit';
import fs from '@ohos.file.fs';
import { Chapter } from '../model/Chapter';
import { Comic } from '../model/Comic';
import { JmApi, JmComment, JmCommentPage } from '../api/JmApi';
import { ChapterTask, ComicCacheRow, Database, DownloadItem } from '../database/Database';
import { Settings } from '../preferences/Settings';
import { SettingsKeys } from '../../common/Constants';
import { Network } from '../../common/Network';
import { JmImage } from '../../common/JmImage';
import { Logger } from '../../common/Logger';

const TAG = 'DetailCache';
/** 封面文件落于 filesDir/download/detail/{comicId}/cover（download 根与章节文件同级，章节目录为纯数字 photoId 不冲突） */
const ROOT_DIR = 'download';
/** 下载入队时预缓存的评论页数（更多页由评论页在线浏览时逐页缓存，离线可回看） */
const COMMENT_CAPTURE_PAGES: number = 3;

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
   * 保存详情字段 + 章节列表 + 首页评论 + 相关推荐 + 封面文件（相关推荐离线展示用）。
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
      // 预缓存后续评论页（离线翻页用）：单页失败即停（弱网/触限不拖累整体）
      if (source === 'jm') {
        for (let pageNo: number = 2; pageNo <= COMMENT_CAPTURE_PAGES && pageNo <= maxPage; pageNo++) {
          try {
            const more: JmCommentPage = await JmApi.getComments(comicId, pageNo);
            if (more.comments.length === 0) {
              break;
            }
            await DetailCache.saveCommentsPage(comicId, source, pageNo, more.comments,
              more.maxPage > 0 ? more.maxPage : maxPage);
          } catch (e) {
            Logger.warn(TAG, `capture comments page ${pageNo} failed: ${Logger.describe(e)}`);
            break;
          }
        }
      }
    } catch (e) {
      Logger.warn(TAG, `capture failed: ${comicId} ${Logger.describe(e)}`);
    }
  }

  /** 详情本地秒开入口：返回缓存 Comic（含相关推荐，离线时详情页可展示） */
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
    comic.relatedComics = DetailCache.parseRelated(row.relatedJson);
    return comic;
  }

  /**
   * 详情缓存缺失时的离线兜底（老版本下载/关闭「下载时保存详情数据」的漫画）：
   * 用 downloads + download_chapters 表拼最小详情（标题/封面/章节），
   * 保证完全离线也能进入已下载漫画详情页并读本地章节；描述/标签等联网后由页面静默刷新补全。
   * 无下载记录或无章节任务返回 null。
   */
  static async localDetail(comicId: string, source: string): Promise<Comic | null> {
    if (comicId.length === 0 || source !== 'jm') {
      return null;
    }
    const dl: DownloadItem | null = await Database.queryDownload(comicId, source);
    if (dl === null) {
      return null;
    }
    const tasks: ChapterTask[] = await Database.queryChapterTasks(comicId);
    if (tasks.length === 0) {
      return null;
    }
    const comic: Comic = new Comic();
    comic.id = dl.id;
    comic.source = dl.source.length > 0 ? dl.source : source;
    comic.title = dl.title;
    comic.coverUrl = dl.coverUrl;
    const chapters: Chapter[] = [];
    for (const t of tasks) {
      const ch: Chapter = new Chapter();
      ch.id = t.chapterId;
      ch.comicId = comicId;
      ch.title = t.title;
      ch.order = t.sortOrder;
      ch.pages = t.pageCount;
      chapters.push(ch);
    }
    comic.chapters = chapters;
    comic.chapterCount = chapters.length;
    return comic;
  }

  /** 首页评论本地秒开入口（= loadCommentsPage 第 1 页；行存在但无评论数据=浏览时建的行，视为无缓存走网络） */
  static async loadComments(comicId: string, source: string): Promise<JmCommentPage | null> {
    return await DetailCache.loadCommentsPage(comicId, source, 1);
  }

  /**
   * 按页读取评论缓存（下载预缓存前 3 页 + 浏览逐页回写；离线翻页可回看）。
   * 格式：v2 包装 {"v":2,"p":{"1":"<评论数组JSON>",...}}；旧版行=纯 JSON 数组（仅第 1 页）。
   * 无行 / 无数据 / 该页未缓存均返回 null（调用方回退网络）。
   */
  static async loadCommentsPage(comicId: string, source: string, page: number): Promise<JmCommentPage | null> {
    if (page < 1) {
      return null;
    }
    const row: ComicCacheRow | null = await Database.queryComicCache(comicId, source);
    if (row === null || row.commentsJson.length === 0) {
      return null;
    }
    let pageJson: string = '';
    if (DetailCache.isLegacyComments(row.commentsJson)) {
      if (page === 1) {
        pageJson = row.commentsJson;
      }
    } else {
      const pages: Record<string, Object> = DetailCache.pagesRecord(row.commentsJson);
      const key: string = String(page);
      if (pages[key] !== undefined && pages[key] !== null) {
        pageJson = String(pages[key]);
      }
    }
    if (pageJson.length === 0) {
      return null;
    }
    const out: JmCommentPage = new JmCommentPage();
    out.comments = DetailCache.parseComments(pageJson);
    out.maxPage = row.commentMaxPage > 0 ? row.commentMaxPage : 1;
    return out;
  }

  /**
   * 联网成功后同步更新详情字段（保留既有评论缓存，评论由 CommentsPage 刷新回写）。
   * 浏览即缓存：无缓存行也直接建行（首开联网成功即落库，相关推荐供离线展示），
   * 容量由 CacheManager 按 updateTime LRU 淘汰管理。
   */
  static async updateComic(comic: Comic, source: string): Promise<void> {
    try {
      const old: ComicCacheRow | null = await Database.queryComicCache(comic.id, source);
      const row: ComicCacheRow = DetailCache.comicToRow(comic, source);
      if (old !== null) {
        row.commentsJson = old.commentsJson;
        row.commentMaxPage = old.commentMaxPage;
      }
      await Database.upsertComicCache(row);
    } catch (e) {
      Logger.warn(TAG, `updateComic failed: ${comic.id} ${Logger.describe(e)}`);
    }
  }

  /** 评论页联网成功后回写（第 1 页语义等同旧接口），保持离线数据新鲜 */
  static async saveComments(comicId: string, source: string, comments: JmComment[], maxPage: number): Promise<void> {
    await DetailCache.saveCommentsPage(comicId, source, 1, comments, maxPage);
  }

  /** 按页写入评论缓存（v2 多页包装；旧格式行升级为 v2 并保留第 1 页内容）；行不存在则跳过（详情浏览会建行） */
  static async saveCommentsPage(comicId: string, source: string, page: number, comments: JmComment[],
    maxPage: number): Promise<void> {
    if (page < 1) {
      return;
    }
    try {
      const old: ComicCacheRow | null = await Database.queryComicCache(comicId, source);
      if (old === null) {
        return;
      }
      const pages: Record<string, Object> = DetailCache.pagesRecord(old.commentsJson);
      pages[String(page)] = DetailCache.commentsToJson(comments);
      const wrapper: Record<string, Object> = {};
      wrapper['v'] = 2;
      wrapper['p'] = pages;
      old.commentsJson = JSON.stringify(wrapper);
      if (maxPage > 0) {
        old.commentMaxPage = maxPage;
      } else if (old.commentMaxPage <= 0) {
        old.commentMaxPage = 1;
      }
      await Database.upsertComicCache(old);
    } catch (e) {
      Logger.warn(TAG, `saveCommentsPage ${page} failed: ${comicId} ${Logger.describe(e)}`);
    }
  }

  /** 旧格式判定（首字符 '['=纯评论数组；v2 为对象包装） */
  private static isLegacyComments(json: string): boolean {
    return json.trim().startsWith('[');
  }

  /** 取 v2 包装内的页表 {page -> 评论数组JSON字符串}；旧格式行返回含第 1 页的表；坏数据返回空表 */
  private static pagesRecord(json: string): Record<string, Object> {
    const out: Record<string, Object> = {};
    if (json.length === 0) {
      return out;
    }
    if (DetailCache.isLegacyComments(json)) {
      out['1'] = json;
      return out;
    }
    try {
      const wrapper: Record<string, Object> = JSON.parse(json) as Record<string, Object>;
      if (wrapper === null) {
        return out;
      }
      const p: Object | undefined = wrapper['p'];
      if (p === undefined || p === null) {
        return out;
      }
      // JSON.parse 后 p 即已解析的页表对象（存入时 wrapper['p'] 直接放 Record，非字符串）
      const pages: Record<string, Object> = p as Record<string, Object>;
      const keys: string[] = Object.keys(pages);
      for (const key of keys) {
        const val: Object | undefined = pages[key];
        if (val !== undefined && val !== null) {
          out[key] = String(val);
        }
      }
    } catch (e) {
    }
    return out;
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
    // v2 包装落第 1 页；后续页由 capture/浏览 saveCommentsPage 合入
    const pages: Record<string, Object> = {};
    pages['1'] = DetailCache.commentsToJson(comments);
    const wrapper: Record<string, Object> = {};
    wrapper['v'] = 2;
    wrapper['p'] = pages;
    row.commentsJson = JSON.stringify(wrapper);
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
    row.relatedJson = DetailCache.relatedToJson(comic.relatedComics);
    return row;
  }

  private static writeCover(comicId: string, bytes: Uint8Array): void {
    if (DetailCache.ctx === null || comicId.length === 0) {
      return;
    }
    const dir: string = `${DetailCache.ctx.filesDir}/${ROOT_DIR}/detail/${comicId}`;
    const path: string = `${dir}/cover`;
    try {
      // mkdirSync 递归模式在目录已存在时也会抛 EEXIST，先探测再建
      if (!fs.accessSync(dir)) {
        fs.mkdirSync(dir, true);
      }
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

  /** 相关推荐序列化（仅存展示/跳转所需字段 id/source/title/coverUrl，够 relatedSection 渲染与跳转用） */
  private static relatedToJson(comics: Comic[]): string {
    const arr: Record<string, Object>[] = [];
    for (const c of comics) {
      const rec: Record<string, Object> = {
        'id': c.id, 'source': c.source, 'title': c.title, 'coverUrl': c.coverUrl
      };
      arr.push(rec);
    }
    return JSON.stringify(arr);
  }

  private static parseRelated(json: string): Comic[] {
    const out: Comic[] = [];
    if (json.length === 0) {
      return out;
    }
    try {
      const arr: Object[] = JSON.parse(json) as Object[];
      for (const item of arr) {
        const r: Record<string, Object> = item as Record<string, Object>;
        const c: Comic = new Comic();
        c.id = DetailCache.str(r, 'id');
        c.source = DetailCache.str(r, 'source');
        if (c.source.length === 0) {
          c.source = 'jm';
        }
        c.title = DetailCache.str(r, 'title');
        c.coverUrl = DetailCache.str(r, 'coverUrl');
        if (c.id.length > 0) {
          out.push(c);
        }
      }
    } catch (e) {
      Logger.warn(TAG, `parseRelated failed: ${Logger.describe(e)}`);
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
