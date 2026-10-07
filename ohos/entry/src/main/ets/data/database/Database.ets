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
      await Database.store.insert('downloads', bucket);
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
