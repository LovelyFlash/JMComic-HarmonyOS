// data/database/Database.ets - SQLite 数据库封装
import relationalStore from '@ohos.data.relationalStore';
import { Logger } from '../../common/Logger';
import { common } from '@kit.AbilityKit';
import { JmApi } from '../api/JmApi';

const TAG = 'Database';
const SQL_CREATE_HISTORY = `CREATE TABLE IF NOT EXISTS history (
  id TEXT PRIMARY KEY, title TEXT NOT NULL, coverUrl TEXT,
  readTime INTEGER DEFAULT 0, lastChapter TEXT DEFAULT '',
  lastPage INTEGER DEFAULT 0, source TEXT DEFAULT '')`;
const SQL_CREATE_DOWNLOADS = `CREATE TABLE IF NOT EXISTS downloads (
  id TEXT NOT NULL, title TEXT NOT NULL, coverUrl TEXT DEFAULT '',
  source TEXT DEFAULT '', downloadPath TEXT DEFAULT '',
  downloadTime INTEGER DEFAULT 0, status INTEGER DEFAULT 0,
  PRIMARY KEY(id, source))`;
const SQL_CREATE_FOLLOWS = `CREATE TABLE IF NOT EXISTS follows (
  id TEXT NOT NULL, title TEXT NOT NULL, coverUrl TEXT DEFAULT '',
  source TEXT DEFAULT '', followTime INTEGER DEFAULT 0,
  lastUpdate INTEGER DEFAULT 0, hasUpdate INTEGER DEFAULT 0,
  PRIMARY KEY(id, source))`;
const SQL_CREATE_COMMENTS = `CREATE TABLE IF NOT EXISTS comments (
  id INTEGER PRIMARY KEY AUTOINCREMENT, comicId TEXT NOT NULL,
  source TEXT DEFAULT '', userName TEXT DEFAULT '我',
  content TEXT NOT NULL, time INTEGER DEFAULT 0, likeCount INTEGER DEFAULT 0)`;
const SQL_CREATE_DOWNLOAD_CHAPTERS = `CREATE TABLE IF NOT EXISTS download_chapters (
  chapterId TEXT NOT NULL, comicId TEXT NOT NULL, title TEXT DEFAULT '',
  sortOrder INTEGER DEFAULT 0, pageCount INTEGER DEFAULT 0,
  progress INTEGER DEFAULT 0, status INTEGER DEFAULT 0,
  localDir TEXT DEFAULT '', updateTime INTEGER DEFAULT 0,
  PRIMARY KEY(chapterId, comicId))`;
const SQL_CREATE_COMIC_CACHE = `CREATE TABLE IF NOT EXISTS comic_cache (
  comicId TEXT NOT NULL, source TEXT NOT NULL, title TEXT DEFAULT '',
  coverUrl TEXT DEFAULT '', description TEXT DEFAULT '', author TEXT DEFAULT '',
  categoriesJson TEXT DEFAULT '', likes INTEGER DEFAULT 0, commentCount INTEGER DEFAULT 0,
  chaptersJson TEXT DEFAULT '', commentsJson TEXT DEFAULT '',
  commentMaxPage INTEGER DEFAULT 1, updateTime INTEGER DEFAULT 0,
  relatedJson TEXT DEFAULT '',
  PRIMARY KEY(comicId, source))`;
const SQL_CREATE_IMAGE_CACHE = `CREATE TABLE IF NOT EXISTS image_cache (
  key TEXT PRIMARY KEY, url TEXT NOT NULL, comicId TEXT DEFAULT '',
  kind INTEGER DEFAULT 0, bytes INTEGER DEFAULT 0, updateTime INTEGER DEFAULT 0)`;

export enum ChapterDlStatus {
  QUEUED = 0, RUNNING = 1, PAUSED = 2, DONE = 3, FAILED = 4,
  /** 仅内存态：已取消（行已删除，runner 观察后不再写库），不落盘 */
  CANCELED = 99
}

export class Database {
  private static store: relationalStore.RdbStore | null = null;

  static async init(context: common.UIAbilityContext): Promise<void> {
    try {
      Database.store = await relationalStore.getRdbStore(context, {
        name: 'pica_comic.db',
        securityLevel: relationalStore.SecurityLevel.S1
      });
      await Database.store.executeSql(SQL_CREATE_HISTORY);
      await Database.store.executeSql(SQL_CREATE_DOWNLOADS);
      await Database.store.executeSql(SQL_CREATE_FOLLOWS);
      await Database.store.executeSql(SQL_CREATE_COMMENTS);
      await Database.store.executeSql(SQL_CREATE_DOWNLOAD_CHAPTERS);
      await Database.store.executeSql(SQL_CREATE_COMIC_CACHE);
      await Database.migrateComicCacheRelated();
      await Database.store.executeSql(SQL_CREATE_IMAGE_CACHE);
      Logger.info(TAG, 'Database initialized');
    } catch (e) {
      Logger.error(TAG, `Database init failed: ${Logger.describe(e)}`);
    }
  }

  // --- History ---
  /** 历史变更广播：bump AppStorage historyChanged，驱动 MePage/HistoryPage @Watch 重查 */
  private static notifyHistoryChanged(): void {
    try {
      const prev: number | undefined = AppStorage.get<number>('historyChanged');
      AppStorage.setOrCreate('historyChanged', prev === undefined ? 1 : prev + 1);
    } catch (e) {
      Logger.warn(TAG, `notifyHistoryChanged failed: ${Logger.describe(e)}`);
    }
  }

  static async insertHistory(id: string, title: string, coverUrl: string, source: string, lastChapter: string = '', lastPage: number = 0): Promise<void> {
    if (!Database.store) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        'id': id, 'title': title, 'coverUrl': coverUrl,
        'readTime': Date.now(), 'lastChapter': lastChapter,
        'lastPage': lastPage, 'source': source
      };
      // 主键冲突静默吞错会导致二次进入同一漫画 readTime/封面永不刷新、排序不更新
      await Database.store.insert('history', bucket,
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
      Database.notifyHistoryChanged();
    } catch (e) {
      Logger.error(TAG, `insertHistory failed: ${Logger.describe(e)}`);
    }
  }

  static async updateReadingProgress(id: string, source: string, lastChapter: string, lastPage: number): Promise<void> {
    if (!Database.store) return;
    try {
      const predicates = new relationalStore.RdbPredicates('history');
      predicates.equalTo('id', id).equalTo('source', source);
      const bucket: relationalStore.ValuesBucket = {
        'lastChapter': lastChapter, 'lastPage': lastPage, 'readTime': Date.now()
      };
      await Database.store.update(bucket, predicates);
      Database.notifyHistoryChanged();
    } catch (e) {
      Logger.error(TAG, `updateReadingProgress failed: ${Logger.describe(e)}`);
    }
  }

  static async queryHistory(): Promise<HistoryItem[]> {
    if (!Database.store) return [];
    try {
      const predicates = new relationalStore.RdbPredicates('history');
      predicates.equalTo('source', 'jm');
      predicates.orderByDesc('readTime');
      const resultSet = await Database.store.query(predicates,
        ['id', 'title', 'coverUrl', 'readTime', 'lastChapter', 'lastPage', 'source']);
      const results: HistoryItem[] = [];
      while (resultSet.goToNextRow()) {
        const item = new HistoryItem();
        item.id = resultSet.getString(resultSet.getColumnIndex('id'));
        item.title = resultSet.getString(resultSet.getColumnIndex('title'));
        item.coverUrl = JmApi.rehostUrl(resultSet.getString(resultSet.getColumnIndex('coverUrl')));
        item.readTime = resultSet.getLong(resultSet.getColumnIndex('readTime'));
        item.lastChapter = resultSet.getString(resultSet.getColumnIndex('lastChapter'));
        item.lastPage = resultSet.getLong(resultSet.getColumnIndex('lastPage'));
        item.source = resultSet.getString(resultSet.getColumnIndex('source'));
        results.push(item);
      }
      resultSet.close();
      return results;
    } catch (e) {
      Logger.error(TAG, `queryHistory failed: ${Logger.describe(e)}`);
      return [];
    }
  }

  static async removeHistory(id: string, source: string): Promise<void> {
    if (!Database.store) return;
    try {
      const predicates = new relationalStore.RdbPredicates('history');
      predicates.equalTo('id', id).equalTo('source', source);
      await Database.store.delete(predicates);
      Database.notifyHistoryChanged();
    } catch (e) {
      Logger.error(TAG, `removeHistory failed: ${Logger.describe(e)}`);
    }
  }

  static async clearHistory(): Promise<void> {
    if (!Database.store) return;
    try {
      await Database.store.executeSql('DELETE FROM history');
      Database.notifyHistoryChanged();
    } catch (e) {
      Logger.error(TAG, `clearHistory failed: ${Logger.describe(e)}`);
    }
  }

  static async getReadingProgress(id: string, source: string): Promise<ReadingProgress> {
    if (!Database.store) return new ReadingProgress();
    try {
      const predicates = new relationalStore.RdbPredicates('history');
      predicates.equalTo('id', id).equalTo('source', source);
      const resultSet = await Database.store.query(predicates, ['lastChapter', 'lastPage']);
      const progress = new ReadingProgress();
      if (resultSet.goToNextRow()) {
        progress.lastChapter = resultSet.getString(resultSet.getColumnIndex('lastChapter'));
        progress.lastPage = resultSet.getLong(resultSet.getColumnIndex('lastPage'));
      }
      resultSet.close();
      return progress;
    } catch (e) {
      return new ReadingProgress();
    }
  }

  // --- Downloads ---
  static async insertDownload(id: string, title: string, coverUrl: string, source: string, downloadPath: string): Promise<void> {
    if (!Database.store) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        'id': id, 'title': title, 'coverUrl': coverUrl,
        'source': source, 'downloadPath': downloadPath,
        'downloadTime': Date.now()
      };
      await Database.store.insert('downloads', bucket, relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (e) {
      Logger.error(TAG, `insertDownload failed: ${Logger.describe(e)}`);
    }
  }

  static async removeDownload(id: string, source: string): Promise<void> {
    if (!Database.store) return;
    try {
      const predicates = new relationalStore.RdbPredicates('downloads');
      predicates.equalTo('id', id).equalTo('source', source);
      await Database.store.delete(predicates);
    } catch (e) {
      Logger.error(TAG, `removeDownload failed: ${Logger.describe(e)}`);
    }
  }

  static async queryDownloads(): Promise<DownloadItem[]> {
    if (!Database.store) return [];
    try {
      const predicates = new relationalStore.RdbPredicates('downloads');
      predicates.equalTo('source', 'jm');
      predicates.orderByDesc('downloadTime');
      const resultSet = await Database.store.query(predicates,
        ['id', 'title', 'coverUrl', 'source', 'downloadPath', 'downloadTime']);
      const results: DownloadItem[] = [];
      while (resultSet.goToNextRow()) {
        results.push(Database.rowToDownloadItem(resultSet));
      }
      resultSet.close();
      return results;
    } catch (e) {
      Logger.error(TAG, `queryDownloads failed: ${Logger.describe(e)}`);
      return [];
    }
  }

  /** 单个下载条目（详情页离线兜底用；不存在返回 null） */
  static async queryDownload(id: string, source: string): Promise<DownloadItem | null> {
    if (!Database.store) return null;
    try {
      const predicates = new relationalStore.RdbPredicates('downloads');
      predicates.equalTo('id', id).equalTo('source', source);
      const resultSet = await Database.store.query(predicates,
        ['id', 'title', 'coverUrl', 'source', 'downloadPath', 'downloadTime']);
      const item: DownloadItem | null = resultSet.goToNextRow() ?
        Database.rowToDownloadItem(resultSet) : null;
      resultSet.close();
      return item;
    } catch (e) {
      Logger.error(TAG, `queryDownload failed: ${Logger.describe(e)}`);
      return null;
    }
  }

  private static rowToDownloadItem(resultSet: relationalStore.ResultSet): DownloadItem {
    const item = new DownloadItem();
    item.id = resultSet.getString(resultSet.getColumnIndex('id'));
    item.title = resultSet.getString(resultSet.getColumnIndex('title'));
    item.coverUrl = JmApi.rehostUrl(resultSet.getString(resultSet.getColumnIndex('coverUrl')));
    item.source = resultSet.getString(resultSet.getColumnIndex('source'));
    item.downloadPath = resultSet.getString(resultSet.getColumnIndex('downloadPath'));
    item.downloadTime = resultSet.getLong(resultSet.getColumnIndex('downloadTime'));
    return item;
  }

  // --- Download chapters (章节下载任务) ---
  static async upsertChapterTask(task: ChapterTask): Promise<void> {
    if (!Database.store) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        'chapterId': task.chapterId, 'comicId': task.comicId, 'title': task.title,
        'sortOrder': task.sortOrder, 'pageCount': task.pageCount,
        'progress': task.progress, 'status': task.status,
        'localDir': task.localDir, 'updateTime': Date.now()
      };
      await Database.store.insert('download_chapters', bucket,
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (e) {
      Logger.error(TAG, `upsertChapterTask failed: ${Logger.describe(e)}`);
    }
  }

  static async updateChapterTask(task: ChapterTask): Promise<void> {
    if (!Database.store) return;
    try {
      const predicates = new relationalStore.RdbPredicates('download_chapters');
      predicates.equalTo('chapterId', task.chapterId).equalTo('comicId', task.comicId);
      const bucket: relationalStore.ValuesBucket = {
        'pageCount': task.pageCount, 'progress': task.progress,
        'status': task.status, 'updateTime': Date.now()
      };
      await Database.store.update(bucket, predicates);
    } catch (e) {
      Logger.error(TAG, `updateChapterTask failed: ${Logger.describe(e)}`);
    }
  }

  static async queryChapterTasks(comicId: string): Promise<ChapterTask[]> {
    if (!Database.store) return [];
    try {
      const predicates = new relationalStore.RdbPredicates('download_chapters');
      predicates.equalTo('comicId', comicId).orderByAsc('sortOrder');
      const resultSet = await Database.store.query(predicates,
        ['chapterId', 'comicId', 'title', 'sortOrder', 'pageCount', 'progress', 'status', 'localDir']);
      const results: ChapterTask[] = [];
      while (resultSet.goToNextRow()) {
        results.push(Database.rowToChapterTask(resultSet));
      }
      resultSet.close();
      return results;
    } catch (e) {
      Logger.error(TAG, `queryChapterTasks failed: ${Logger.describe(e)}`);
      return [];
    }
  }

  static async queryAllChapterTasks(): Promise<ChapterTask[]> {
    if (!Database.store) return [];
    try {
      const predicates = new relationalStore.RdbPredicates('download_chapters');
      predicates.orderByDesc('updateTime');
      const resultSet = await Database.store.query(predicates,
        ['chapterId', 'comicId', 'title', 'sortOrder', 'pageCount', 'progress', 'status', 'localDir']);
      const results: ChapterTask[] = [];
      while (resultSet.goToNextRow()) {
        results.push(Database.rowToChapterTask(resultSet));
      }
      resultSet.close();
      return results;
    } catch (e) {
      Logger.error(TAG, `queryAllChapterTasks failed: ${Logger.describe(e)}`);
      return [];
    }
  }

  static async queryChapterTask(chapterId: string, comicId: string): Promise<ChapterTask | null> {
    if (!Database.store) return null;
    try {
      const predicates = new relationalStore.RdbPredicates('download_chapters');
      predicates.equalTo('chapterId', chapterId).equalTo('comicId', comicId);
      const resultSet = await Database.store.query(predicates,
        ['chapterId', 'comicId', 'title', 'sortOrder', 'pageCount', 'progress', 'status', 'localDir']);
      const task: ChapterTask | null = resultSet.goToNextRow() ? Database.rowToChapterTask(resultSet) : null;
      resultSet.close();
      return task;
    } catch (e) {
      Logger.error(TAG, `queryChapterTask failed: ${Logger.describe(e)}`);
      return null;
    }
  }

  static async removeChapterTask(chapterId: string, comicId: string): Promise<void> {
    if (!Database.store) return;
    try {
      const predicates = new relationalStore.RdbPredicates('download_chapters');
      predicates.equalTo('chapterId', chapterId).equalTo('comicId', comicId);
      await Database.store.delete(predicates);
    } catch (e) {
      Logger.error(TAG, `removeChapterTask failed: ${Logger.describe(e)}`);
    }
  }

  /** 应用启动时把被杀进程中断的 RUNNING 任务改回 QUEUED，实现断点续传 */
  static async requeueInterruptedDownloads(): Promise<void> {
    if (!Database.store) return;
    try {
      await Database.store.executeSql(
        `UPDATE download_chapters SET status = ${ChapterDlStatus.QUEUED} WHERE status = ${ChapterDlStatus.RUNNING}`);
    } catch (e) {
      Logger.error(TAG, `requeueInterruptedDownloads failed: ${Logger.describe(e)}`);
    }
  }

  private static rowToChapterTask(resultSet: relationalStore.ResultSet): ChapterTask {
    const task = new ChapterTask();
    try {
      task.chapterId = resultSet.getString(resultSet.getColumnIndex('chapterId'));
      task.comicId = resultSet.getString(resultSet.getColumnIndex('comicId'));
      task.title = resultSet.getString(resultSet.getColumnIndex('title'));
      task.sortOrder = resultSet.getLong(resultSet.getColumnIndex('sortOrder'));
      task.pageCount = resultSet.getLong(resultSet.getColumnIndex('pageCount'));
      task.progress = resultSet.getLong(resultSet.getColumnIndex('progress'));
      task.status = resultSet.getLong(resultSet.getColumnIndex('status'));
      task.localDir = resultSet.getString(resultSet.getColumnIndex('localDir'));
    } catch (e) {
      throw new Error(`rowToChapterTask failed: ${Logger.describe(e)}`);
    }
    return task;
  }

  // --- Comic detail cache (已下载漫画的详情/评论缓存) ---

  /** comic_cache 增列迁移（幂等）：ALTER 补列 → 探测列真实存在 → 缺失则重建表兜底（详情缓存可再生） */
  private static async migrateComicCacheRelated(): Promise<void> {
    if (!Database.store) return;
    try {
      await Database.store.executeSql(
        `ALTER TABLE comic_cache ADD COLUMN relatedJson TEXT DEFAULT ''`);
    } catch (e) {
      // 列已存在（新库自带/重复迁移）或驱动不支持 ALTER，下方统一探测
    }
    try {
      const rs = await Database.store.querySql(`SELECT relatedJson FROM comic_cache LIMIT 1`);
      rs.close();
      return;
    } catch (e) {
      Logger.warn(TAG, `relatedJson missing after alter, recreate table: ${Logger.describe(e)}`);
    }
    try {
      await Database.store.executeSql(
        `CREATE TABLE comic_cache_new (comicId TEXT NOT NULL, source TEXT NOT NULL, title TEXT DEFAULT '',` +
        ` coverUrl TEXT DEFAULT '', description TEXT DEFAULT '', author TEXT DEFAULT '',` +
        ` categoriesJson TEXT DEFAULT '', likes INTEGER DEFAULT 0, commentCount INTEGER DEFAULT 0,` +
        ` chaptersJson TEXT DEFAULT '', commentsJson TEXT DEFAULT '',` +
        ` commentMaxPage INTEGER DEFAULT 1, updateTime INTEGER DEFAULT 0, relatedJson TEXT DEFAULT '',` +
        ` PRIMARY KEY(comicId, source))`);
      await Database.store.executeSql(
        `INSERT INTO comic_cache_new (comicId, source, title, coverUrl, description, author,` +
        ` categoriesJson, likes, commentCount, chaptersJson, commentsJson, commentMaxPage, updateTime)` +
        ` SELECT comicId, source, title, coverUrl, description, author, categoriesJson, likes,` +
        ` commentCount, chaptersJson, commentsJson, commentMaxPage, updateTime FROM comic_cache`);
      await Database.store.executeSql(`DROP TABLE comic_cache`);
      await Database.store.executeSql(`ALTER TABLE comic_cache_new RENAME TO comic_cache`);
      Logger.info(TAG, 'comic_cache recreated with relatedJson');
    } catch (e) {
      Logger.error(TAG, `comic_cache recreate failed: ${Logger.describe(e)}`);
    }
  }

  static async upsertComicCache(row: ComicCacheRow): Promise<void> {
    if (!Database.store) return;
    try {
      const bucket: relationalStore.ValuesBucket = Database.comicCacheBucket(row, true);
      await Database.store.insert('comic_cache', bucket,
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (e) {
      // relatedJson 列缺失（ALTER 迁移未生效）时降级写旧列，保住详情缓存主功能
      try {
        const legacy: relationalStore.ValuesBucket = Database.comicCacheBucket(row, false);
        await Database.store.insert('comic_cache', legacy,
          relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
        Logger.warn(TAG, `upsertComicCache legacy path (relatedJson column missing)`);
      } catch (e2) {
        Logger.error(TAG, `upsertComicCache failed: ${Logger.describe(e2)}`);
      }
    }
  }

  private static comicCacheBucket(row: ComicCacheRow, withRelated: boolean):
    relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {
      'comicId': row.comicId, 'source': row.source, 'title': row.title,
      'coverUrl': row.coverUrl, 'description': row.description, 'author': row.author,
      'categoriesJson': row.categoriesJson, 'likes': row.likes,
      'commentCount': row.commentCount, 'chaptersJson': row.chaptersJson,
      'commentsJson': row.commentsJson, 'commentMaxPage': row.commentMaxPage,
      'updateTime': Date.now()
    };
    if (withRelated) {
      bucket['relatedJson'] = row.relatedJson;
    }
    return bucket;
  }

  static async queryComicCache(comicId: string, source: string): Promise<ComicCacheRow | null> {
    if (!Database.store) return null;
    try {
      return await Database.queryComicCacheCols(comicId, source, true);
    } catch (e) {
      // relatedJson 列缺失（ALTER 迁移未生效）时降级按旧列查，保住离线详情入口
      Logger.error(TAG, `queryComicCache retry legacy: ${Logger.describe(e)}`);
      try {
        return await Database.queryComicCacheCols(comicId, source, false);
      } catch (e2) {
        Logger.error(TAG, `queryComicCache failed: ${Logger.describe(e2)}`);
        return null;
      }
    }
  }

  private static async queryComicCacheCols(comicId: string, source: string,
    withRelated: boolean): Promise<ComicCacheRow | null> {
    if (!Database.store) return null;
    const predicates = new relationalStore.RdbPredicates('comic_cache');
    predicates.equalTo('comicId', comicId).equalTo('source', source);
    const columns: string[] = ['comicId', 'source', 'title', 'coverUrl', 'description',
      'author', 'categoriesJson', 'likes', 'commentCount', 'chaptersJson', 'commentsJson',
      'commentMaxPage', 'updateTime'];
    if (withRelated) {
      columns.push('relatedJson');
    }
    const resultSet = await Database.store.query(predicates, columns);
    let row: ComicCacheRow | null = null;
    if (resultSet.goToNextRow()) {
      row = new ComicCacheRow();
      row.comicId = resultSet.getString(resultSet.getColumnIndex('comicId'));
      row.source = resultSet.getString(resultSet.getColumnIndex('source'));
      row.title = resultSet.getString(resultSet.getColumnIndex('title'));
      row.coverUrl = JmApi.rehostUrl(resultSet.getString(resultSet.getColumnIndex('coverUrl')));
      row.description = resultSet.getString(resultSet.getColumnIndex('description'));
      row.author = resultSet.getString(resultSet.getColumnIndex('author'));
      row.categoriesJson = resultSet.getString(resultSet.getColumnIndex('categoriesJson'));
      row.likes = resultSet.getLong(resultSet.getColumnIndex('likes'));
      row.commentCount = resultSet.getLong(resultSet.getColumnIndex('commentCount'));
      row.chaptersJson = resultSet.getString(resultSet.getColumnIndex('chaptersJson'));
      row.commentsJson = resultSet.getString(resultSet.getColumnIndex('commentsJson'));
      row.commentMaxPage = resultSet.getLong(resultSet.getColumnIndex('commentMaxPage'));
      if (withRelated) {
        row.relatedJson = resultSet.getString(resultSet.getColumnIndex('relatedJson'));
      }
      row.updateTime = resultSet.getLong(resultSet.getColumnIndex('updateTime'));
    }
    resultSet.close();
    return row;
  }

  static async removeComicCache(comicId: string, source: string): Promise<void> {
    if (!Database.store) return;
    try {
      const predicates = new relationalStore.RdbPredicates('comic_cache');
      predicates.equalTo('comicId', comicId).equalTo('source', source);
      await Database.store.delete(predicates);
    } catch (e) {
      Logger.error(TAG, `removeComicCache failed: ${Logger.describe(e)}`);
    }
  }

  /** comic_cache 内容总字节（SQL 聚合，不整表拉入内存；不含 SQLite 页开销） */
  static async comicCacheBytes(): Promise<number> {
    if (!Database.store) return 0;
    try {
      const sql = `SELECT IFNULL(SUM(LENGTH(title)+LENGTH(coverUrl)+LENGTH(description)` +
        `+LENGTH(author)+LENGTH(categoriesJson)+LENGTH(chaptersJson)+LENGTH(commentsJson)` +
        `+LENGTH(relatedJson)),0) AS bytes` +
        ` FROM comic_cache`;
      const resultSet = await Database.store.querySql(sql);
      let bytes: number = 0;
      if (resultSet.goToNextRow()) {
        bytes = resultSet.getLong(resultSet.getColumnIndex('bytes'));
      }
      resultSet.close();
      return bytes;
    } catch (e) {
      Logger.error(TAG, `comicCacheBytes failed: ${Logger.describe(e)}`);
      return 0;
    }
  }

  /** 按 updateTime 从旧到新返回缓存行（comicId+source+内容字节），容量挡位淘汰用 */
  static async queryComicCacheLru(): Promise<ComicCacheLruRow[]> {
    if (!Database.store) return [];
    try {
      const sql = `SELECT comicId, source, LENGTH(title)+LENGTH(coverUrl)+LENGTH(description)` +
        `+LENGTH(author)+LENGTH(categoriesJson)+LENGTH(chaptersJson)+LENGTH(commentsJson)` +
        `+LENGTH(relatedJson) AS bytes` +
        ` FROM comic_cache ORDER BY updateTime ASC`;
      const resultSet = await Database.store.querySql(sql);
      const results: ComicCacheLruRow[] = [];
      while (resultSet.goToNextRow()) {
        const row = new ComicCacheLruRow();
        row.comicId = resultSet.getString(resultSet.getColumnIndex('comicId'));
        row.source = resultSet.getString(resultSet.getColumnIndex('source'));
        row.bytes = resultSet.getLong(resultSet.getColumnIndex('bytes'));
        results.push(row);
      }
      resultSet.close();
      return results;
    } catch (e) {
      Logger.error(TAG, `queryComicCacheLru failed: ${Logger.describe(e)}`);
      return [];
    }
  }

  /** 清空详情缓存表（下载章节/历史/追更/本地评论不受影响） */
  static async clearComicCache(): Promise<void> {
    if (!Database.store) return;
    try {
      await Database.store.executeSql('DELETE FROM comic_cache');
    } catch (e) {
      Logger.error(TAG, `clearComicCache failed: ${Logger.describe(e)}`);
    }
  }

  // --- Image Cache（图片持久缓存元数据，文件本体在 filesDir/img_cache/<key>.img） ---
  static async upsertImageCache(row: ImageCacheRow): Promise<void> {
    if (!Database.store) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        'key': row.key, 'url': row.url, 'comicId': row.comicId,
        'kind': row.kind, 'bytes': row.bytes, 'updateTime': row.updateTime
      };
      await Database.store.insert('image_cache', bucket,
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (e) {
      Logger.error(TAG, `upsertImageCache failed: ${Logger.describe(e)}`);
    }
  }

  static async queryImageCache(key: string): Promise<ImageCacheRow | null> {
    if (!Database.store) return null;
    try {
      const predicates = new relationalStore.RdbPredicates('image_cache');
      predicates.equalTo('key', key);
      const resultSet = await Database.store.query(predicates);
      const row = new ImageCacheRow();
      let found: boolean = false;
      if (resultSet.goToNextRow()) {
        row.key = resultSet.getString(resultSet.getColumnIndex('key'));
        row.url = resultSet.getString(resultSet.getColumnIndex('url'));
        row.comicId = resultSet.getString(resultSet.getColumnIndex('comicId'));
        row.kind = resultSet.getLong(resultSet.getColumnIndex('kind'));
        row.bytes = resultSet.getLong(resultSet.getColumnIndex('bytes'));
        row.updateTime = resultSet.getLong(resultSet.getColumnIndex('updateTime'));
        found = true;
      }
      resultSet.close();
      return found ? row : null;
    } catch (e) {
      Logger.error(TAG, `queryImageCache failed: ${Logger.describe(e)}`);
      return null;
    }
  }

  /** 命中后刷新最近使用时间（LRU 淘汰依据），调用方可 fire-and-forget */
  static async touchImageCache(key: string): Promise<void> {
    if (!Database.store) return;
    try {
      const predicates = new relationalStore.RdbPredicates('image_cache');
      predicates.equalTo('key', key);
      const bucket: relationalStore.ValuesBucket = { 'updateTime': Date.now() };
      await Database.store.update(bucket, predicates);
    } catch (e) {
      Logger.error(TAG, `touchImageCache failed: ${Logger.describe(e)}`);
    }
  }

  /** image_cache 内容总字节（SQL 聚合，不含磁盘文件系统开销） */
  static async imageCacheBytes(): Promise<number> {
    if (!Database.store) return 0;
    try {
      const sql = `SELECT IFNULL(SUM(bytes),0) AS bytes FROM image_cache`;
      const resultSet = await Database.store.querySql(sql);
      let bytes: number = 0;
      if (resultSet.goToNextRow()) {
        bytes = resultSet.getLong(resultSet.getColumnIndex('bytes'));
      }
      resultSet.close();
      return bytes;
    } catch (e) {
      Logger.error(TAG, `imageCacheBytes failed: ${Logger.describe(e)}`);
      return 0;
    }
  }

  /** 按指定类型 updateTime 从旧到新返回缓存行，容量淘汰用 */
  static async queryImageCacheLru(kind: number): Promise<ImageCacheRow[]> {
    if (!Database.store) return [];
    try {
      const predicates = new relationalStore.RdbPredicates('image_cache');
      predicates.equalTo('kind', kind);
      predicates.orderByAsc('updateTime');
      const resultSet = await Database.store.query(predicates);
      const results: ImageCacheRow[] = [];
      while (resultSet.goToNextRow()) {
        const row = new ImageCacheRow();
        row.key = resultSet.getString(resultSet.getColumnIndex('key'));
        row.url = resultSet.getString(resultSet.getColumnIndex('url'));
        row.comicId = resultSet.getString(resultSet.getColumnIndex('comicId'));
        row.kind = resultSet.getLong(resultSet.getColumnIndex('kind'));
        row.bytes = resultSet.getLong(resultSet.getColumnIndex('bytes'));
        row.updateTime = resultSet.getLong(resultSet.getColumnIndex('updateTime'));
        results.push(row);
      }
      resultSet.close();
      return results;
    } catch (e) {
      Logger.error(TAG, `queryImageCacheLru failed: ${Logger.describe(e)}`);
      return [];
    }
  }

  static async removeImageCache(key: string): Promise<void> {
    if (!Database.store) return;
    try {
      const predicates = new relationalStore.RdbPredicates('image_cache');
      predicates.equalTo('key', key);
      await Database.store.delete(predicates);
    } catch (e) {
      Logger.error(TAG, `removeImageCache failed: ${Logger.describe(e)}`);
    }
  }

  /** 清空图片缓存元数据（磁盘文件由 ImageCache.clear 一并删除） */
  static async clearImageCache(): Promise<void> {
    if (!Database.store) return;
    try {
      await Database.store.executeSql('DELETE FROM image_cache');
    } catch (e) {
      Logger.error(TAG, `clearImageCache failed: ${Logger.describe(e)}`);
    }
  }

  // --- Follows (追更) ---
  static async insertFollow(id: string, title: string, coverUrl: string, source: string): Promise<void> {
    if (!Database.store) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        'id': id, 'title': title, 'coverUrl': coverUrl,
        'source': source, 'followTime': Date.now(), 'lastUpdate': 0, 'hasUpdate': 0
      };
      await Database.store.insert('follows', bucket);
    } catch (e) {
      Logger.error(TAG, `insertFollow failed: ${Logger.describe(e)}`);
    }
  }

  static async removeFollow(id: string, source: string): Promise<void> {
    if (!Database.store) return;
    try {
      const predicates = new relationalStore.RdbPredicates('follows');
      predicates.equalTo('id', id).equalTo('source', source);
      await Database.store.delete(predicates);
    } catch (e) {
      Logger.error(TAG, `removeFollow failed: ${Logger.describe(e)}`);
    }
  }

  static async isFollowing(id: string, source: string): Promise<boolean> {
    if (!Database.store) return false;
    try {
      const predicates = new relationalStore.RdbPredicates('follows');
      predicates.equalTo('id', id).equalTo('source', source);
      const resultSet = await Database.store.query(predicates, ['id']);
      const exists = resultSet.goToNextRow();
      resultSet.close();
      return exists;
    } catch (e) {
      return false;
    }
  }

  static async queryFollows(): Promise<FollowItem[]> {
    if (!Database.store) return [];
    try {
      const predicates = new relationalStore.RdbPredicates('follows');
      predicates.equalTo('source', 'jm');
      predicates.orderByDesc('followTime');
      const resultSet = await Database.store.query(predicates,
        ['id', 'title', 'coverUrl', 'source', 'followTime', 'lastUpdate', 'hasUpdate']);
      const results: FollowItem[] = [];
      while (resultSet.goToNextRow()) {
        const item = new FollowItem();
        item.id = resultSet.getString(resultSet.getColumnIndex('id'));
        item.title = resultSet.getString(resultSet.getColumnIndex('title'));
        item.coverUrl = JmApi.rehostUrl(resultSet.getString(resultSet.getColumnIndex('coverUrl')));
        item.source = resultSet.getString(resultSet.getColumnIndex('source'));
        item.followTime = resultSet.getLong(resultSet.getColumnIndex('followTime'));
        item.hasUpdate = resultSet.getLong(resultSet.getColumnIndex('hasUpdate')) === 1;
        results.push(item);
      }
      resultSet.close();
      return results;
    } catch (e) {
      Logger.error(TAG, `queryFollows failed: ${Logger.describe(e)}`);
      return [];
    }
  }

  // --- Comments (本地评论) ---
  static async insertComment(comicId: string, source: string, content: string): Promise<void> {
    if (!Database.store) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        'comicId': comicId, 'source': source, 'userName': '我',
        'content': content, 'time': Date.now(), 'likeCount': 0
      };
      await Database.store.insert('comments', bucket);
    } catch (e) {
      Logger.error(TAG, `insertComment failed: ${Logger.describe(e)}`);
    }
  }

  static async queryComments(comicId: string, source: string): Promise<CommentItem[]> {
    if (!Database.store) return [];
    try {
      const predicates = new relationalStore.RdbPredicates('comments');
      predicates.equalTo('comicId', comicId).equalTo('source', source);
      predicates.orderByDesc('time');
      const resultSet = await Database.store.query(predicates,
        ['id', 'comicId', 'source', 'userName', 'content', 'time', 'likeCount']);
      const results: CommentItem[] = [];
      while (resultSet.goToNextRow()) {
        const item = new CommentItem();
        item.id = resultSet.getLong(resultSet.getColumnIndex('id'));
        item.comicId = resultSet.getString(resultSet.getColumnIndex('comicId'));
        item.userName = resultSet.getString(resultSet.getColumnIndex('userName'));
        item.content = resultSet.getString(resultSet.getColumnIndex('content'));
        item.time = resultSet.getLong(resultSet.getColumnIndex('time'));
        item.likeCount = resultSet.getLong(resultSet.getColumnIndex('likeCount'));
        results.push(item);
      }
      resultSet.close();
      return results;
    } catch (e) {
      Logger.error(TAG, `queryComments failed: ${Logger.describe(e)}`);
      return [];
    }
  }

  static async likeComment(id: number): Promise<void> {
    if (!Database.store) return;
    try {
      const predicates = new relationalStore.RdbPredicates('comments');
      predicates.equalTo('id', id);
      await Database.store.executeSql(`UPDATE comments SET likeCount = likeCount + 1 WHERE id = ${id}`);
    } catch (e) {
      Logger.error(TAG, `likeComment failed: ${Logger.describe(e)}`);
    }
  }
}

export class HistoryItem {
  id: string = '';
  title: string = '';
  coverUrl: string = '';
  readTime: number = 0;
  lastChapter: string = '';
  lastPage: number = 0;
  source: string = '';
}

export class DownloadItem {
  id: string = '';
  title: string = '';
  coverUrl: string = '';
  source: string = '';
  downloadPath: string = '';
  downloadTime: number = 0;
}

/** 章节下载任务（download_chapters 表行） */
export class ChapterTask {
  chapterId: string = '';
  comicId: string = '';
  title: string = '';
  sortOrder: number = 0;
  pageCount: number = 0;
  progress: number = 0;
  status: number = ChapterDlStatus.QUEUED;
  localDir: string = '';
}

/** 已下载漫画详情缓存（comic_cache 表行；chapters/comments/categories 为 JSON 文本） */
export class ComicCacheRow {
  comicId: string = '';
  source: string = 'jm';
  title: string = '';
  coverUrl: string = '';
  description: string = '';
  author: string = '';
  categoriesJson: string = '';
  likes: number = 0;
  commentCount: number = 0;
  chaptersJson: string = '';
  commentsJson: string = '';
  commentMaxPage: number = 1;
  relatedJson: string = '';
  updateTime: number = 0;
}

/** 容量挡位淘汰用：comic_cache 行的 LRU 摘要（按 updateTime 升序） */
export class ComicCacheLruRow {
  comicId: string = '';
  source: string = 'jm';
  bytes: number = 0;
}

/** image_cache 行：URL→文件键（md5），kind 0=阅读页图 1=缩略图/预览 */
export class ImageCacheRow {
  key: string = '';
  url: string = '';
  comicId: string = '';
  kind: number = 0;
  bytes: number = 0;
  updateTime: number = 0;
}

export class FollowItem {
  id: string = '';
  title: string = '';
  coverUrl: string = '';
  source: string = '';
  followTime: number = 0;
  hasUpdate: boolean = false;
}

export class CommentItem {
  id: number = 0;
  comicId: string = '';
  userName: string = '';
  content: string = '';
  time: number = 0;
  likeCount: number = 0;
}

export class ReadingProgress {
  lastChapter: string = '';
  lastPage: number = 0;
}
