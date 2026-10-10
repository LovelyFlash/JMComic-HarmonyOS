// data/database/Database.ets - SQLite 数据库封装
import relationalStore from '@ohos.data.relationalStore';
import { Logger } from '../../common/Logger';
import { common } from '@kit.AbilityKit';

const TAG = 'Database';
const SQL_CREATE_HISTORY = `CREATE TABLE IF NOT EXISTS history (
  id TEXT PRIMARY KEY, title TEXT NOT NULL, coverUrl TEXT,
  readTime INTEGER DEFAULT 0, lastChapter TEXT DEFAULT '',
  lastPage INTEGER DEFAULT 0, source TEXT DEFAULT '')`;
const SQL_CREATE_FAVORITES = `CREATE TABLE IF NOT EXISTS favorites (
  id TEXT NOT NULL, title TEXT NOT NULL, coverUrl TEXT DEFAULT '',
  source TEXT DEFAULT '', addTime INTEGER DEFAULT 0,
  PRIMARY KEY(id, source))`;
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
  PRIMARY KEY(comicId, source))`;

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
      await Database.store.executeSql(SQL_CREATE_FAVORITES);
      await Database.store.executeSql(SQL_CREATE_DOWNLOADS);
      await Database.store.executeSql(SQL_CREATE_FOLLOWS);
      await Database.store.executeSql(SQL_CREATE_COMMENTS);
      await Database.store.executeSql(SQL_CREATE_DOWNLOAD_CHAPTERS);
      await Database.store.executeSql(SQL_CREATE_COMIC_CACHE);
      Logger.info(TAG, 'Database initialized');
    } catch (e) {
      Logger.error(TAG, `Database init failed: ${Logger.describe(e)}`);
    }
  }

  // --- History ---
  static async insertHistory(id: string, title: string, coverUrl: string, source: string, lastChapter: string = '', lastPage: number = 0): Promise<void> {
    if (!Database.store) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        'id': id, 'title': title, 'coverUrl': coverUrl,
        'readTime': Date.now(), 'lastChapter': lastChapter,
        'lastPage': lastPage, 'source': source
      };
      await Database.store.insert('history', bucket);
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
        item.coverUrl = resultSet.getString(resultSet.getColumnIndex('coverUrl'));
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
    } catch (e) {
      Logger.error(TAG, `removeHistory failed: ${Logger.describe(e)}`);
    }
  }

  static async clearHistory(): Promise<void> {
    if (!Database.store) return;
    try {
      await Database.store.executeSql('DELETE FROM history');
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

  // --- Favorites ---
  static async insertFavorite(id: string, title: string, coverUrl: string, source: string): Promise<void> {
    if (!Database.store) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        'id': id, 'title': title, 'coverUrl': coverUrl,
        'source': source, 'addTime': Date.now()
      };
      await Database.store.insert('favorites', bucket);
    } catch (e) {
      Logger.error(TAG, `insertFavorite failed: ${Logger.describe(e)}`);
    }
  }

  static async removeFavorite(id: string, source: string): Promise<void> {
    if (!Database.store) return;
    try {
      const predicates = new relationalStore.RdbPredicates('favorites');
      predicates.equalTo('id', id).equalTo('source', source);
      await Database.store.delete(predicates);
    } catch (e) {
      Logger.error(TAG, `removeFavorite failed: ${Logger.describe(e)}`);
    }
  }

  static async isFavorite(id: string, source: string): Promise<boolean> {
    if (!Database.store) return false;
    try {
      const predicates = new relationalStore.RdbPredicates('favorites');
      predicates.equalTo('id', id).equalTo('source', source);
      const resultSet = await Database.store.query(predicates, ['id']);
      const exists = resultSet.goToNextRow();
      resultSet.close();
      return exists;
    } catch (e) {
      return false;
    }
  }

  static async queryFavorites(): Promise<FavoriteItem[]> {
    if (!Database.store) return [];
    try {
      const predicates = new relationalStore.RdbPredicates('favorites');
      predicates.equalTo('source', 'jm');
      predicates.orderByDesc('addTime');
      const resultSet = await Database.store.query(predicates,
        ['id', 'title', 'coverUrl', 'source', 'addTime']);
      const results: FavoriteItem[] = [];
      while (resultSet.goToNextRow()) {
        const item = new FavoriteItem();
        item.id = resultSet.getString(resultSet.getColumnIndex('id'));
        item.title = resultSet.getString(resultSet.getColumnIndex('title'));
        item.coverUrl = resultSet.getString(resultSet.getColumnIndex('coverUrl'));
        item.source = resultSet.getString(resultSet.getColumnIndex('source'));
        item.addTime = resultSet.getLong(resultSet.getColumnIndex('addTime'));
        results.push(item);
      }
      resultSet.close();
      return results;
    } catch (e) {
      Logger.error(TAG, `queryFavorites failed: ${Logger.describe(e)}`);
      return [];
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
        const item = new DownloadItem();
        item.id = resultSet.getString(resultSet.getColumnIndex('id'));
        item.title = resultSet.getString(resultSet.getColumnIndex('title'));
        item.coverUrl = resultSet.getString(resultSet.getColumnIndex('coverUrl'));
        item.source = resultSet.getString(resultSet.getColumnIndex('source'));
        item.downloadPath = resultSet.getString(resultSet.getColumnIndex('downloadPath'));
        item.downloadTime = resultSet.getLong(resultSet.getColumnIndex('downloadTime'));
        results.push(item);
      }
      resultSet.close();
      return results;
    } catch (e) {
      Logger.error(TAG, `queryDownloads failed: ${Logger.describe(e)}`);
      return [];
    }
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
  static async upsertComicCache(row: ComicCacheRow): Promise<void> {
    if (!Database.store) return;
    try {
      const bucket: relationalStore.ValuesBucket = {
        'comicId': row.comicId, 'source': row.source, 'title': row.title,
        'coverUrl': row.coverUrl, 'description': row.description, 'author': row.author,
        'categoriesJson': row.categoriesJson, 'likes': row.likes,
        'commentCount': row.commentCount, 'chaptersJson': row.chaptersJson,
        'commentsJson': row.commentsJson, 'commentMaxPage': row.commentMaxPage,
        'updateTime': Date.now()
      };
      await Database.store.insert('comic_cache', bucket,
        relationalStore.ConflictResolution.ON_CONFLICT_REPLACE);
    } catch (e) {
      Logger.error(TAG, `upsertComicCache failed: ${Logger.describe(e)}`);
    }
  }

  static async queryComicCache(comicId: string, source: string): Promise<ComicCacheRow | null> {
    if (!Database.store) return null;
    try {
      const predicates = new relationalStore.RdbPredicates('comic_cache');
      predicates.equalTo('comicId', comicId).equalTo('source', source);
      const resultSet = await Database.store.query(predicates,
        ['comicId', 'source', 'title', 'coverUrl', 'description', 'author',
          'categoriesJson', 'likes', 'commentCount', 'chaptersJson', 'commentsJson',
          'commentMaxPage', 'updateTime']);
      let row: ComicCacheRow | null = null;
      if (resultSet.goToNextRow()) {
        row = new ComicCacheRow();
        row.comicId = resultSet.getString(resultSet.getColumnIndex('comicId'));
        row.source = resultSet.getString(resultSet.getColumnIndex('source'));
        row.title = resultSet.getString(resultSet.getColumnIndex('title'));
        row.coverUrl = resultSet.getString(resultSet.getColumnIndex('coverUrl'));
        row.description = resultSet.getString(resultSet.getColumnIndex('description'));
        row.author = resultSet.getString(resultSet.getColumnIndex('author'));
        row.categoriesJson = resultSet.getString(resultSet.getColumnIndex('categoriesJson'));
        row.likes = resultSet.getLong(resultSet.getColumnIndex('likes'));
        row.commentCount = resultSet.getLong(resultSet.getColumnIndex('commentCount'));
        row.chaptersJson = resultSet.getString(resultSet.getColumnIndex('chaptersJson'));
        row.commentsJson = resultSet.getString(resultSet.getColumnIndex('commentsJson'));
        row.commentMaxPage = resultSet.getLong(resultSet.getColumnIndex('commentMaxPage'));
        row.updateTime = resultSet.getLong(resultSet.getColumnIndex('updateTime'));
      }
      resultSet.close();
      return row;
    } catch (e) {
      Logger.error(TAG, `queryComicCache failed: ${Logger.describe(e)}`);
      return null;
    }
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
        item.coverUrl = resultSet.getString(resultSet.getColumnIndex('coverUrl'));
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

export class FavoriteItem {
  id: string = '';
  title: string = '';
  coverUrl: string = '';
  source: string = '';
  addTime: number = 0;
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
