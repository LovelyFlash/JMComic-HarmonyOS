import relationalStore from "@ohos:data.relationalStore";
import { Logger } from "@bundle:com.picacomic.harmony/entry/ets/common/Logger";
import type common from "@ohos:app.ability.common";
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
  downloadTime INTEGER DEFAULT 0, PRIMARY KEY(id, source))`;
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
            Logger.info(TAG, 'Database initialized');
        }
        catch (e) {
            Logger.error(TAG, `Database init failed: ${String(e)}`);
        }
    }
    // --- History ---
    static async insertHistory(id: string, title: string, coverUrl: string, source: string, lastChapter: string = '', lastPage: number = 0): Promise<void> {
        if (!Database.store)
            return;
        try {
            const bucket: relationalStore.ValuesBucket = {
                'id': id, 'title': title, 'coverUrl': coverUrl,
                'readTime': Date.now(), 'lastChapter': lastChapter,
                'lastPage': lastPage, 'source': source
            };
            await Database.store.insert('history', bucket);
        }
        catch (e) {
            Logger.error(TAG, `insertHistory failed: ${String(e)}`);
        }
    }
    static async updateReadingProgress(id: string, source: string, lastChapter: string, lastPage: number): Promise<void> {
        if (!Database.store)
            return;
        try {
            const predicates = new relationalStore.RdbPredicates('history');
            predicates.equalTo('id', id).equalTo('source', source);
            const bucket: relationalStore.ValuesBucket = {
                'lastChapter': lastChapter, 'lastPage': lastPage, 'readTime': Date.now()
            };
            await Database.store.update(bucket, predicates);
        }
        catch (e) {
            Logger.error(TAG, `updateReadingProgress failed: ${String(e)}`);
        }
    }
    static async queryHistory(): Promise<HistoryItem[]> {
        if (!Database.store)
            return [];
        try {
            const predicates = new relationalStore.RdbPredicates('history');
            predicates.orderByDesc('readTime');
            const resultSet = await Database.store.query(predicates, ['id', 'title', 'coverUrl', 'readTime', 'lastChapter', 'lastPage', 'source']);
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
        }
        catch (e) {
            Logger.error(TAG, `queryHistory failed: ${String(e)}`);
            return [];
        }
    }
    static async removeHistory(id: string, source: string): Promise<void> {
        if (!Database.store)
            return;
        try {
            const predicates = new relationalStore.RdbPredicates('history');
            predicates.equalTo('id', id).equalTo('source', source);
            await Database.store.delete(predicates);
        }
        catch (e) {
            Logger.error(TAG, `removeHistory failed: ${String(e)}`);
        }
    }
    static async clearHistory(): Promise<void> {
        if (!Database.store)
            return;
        try {
            await Database.store.executeSql('DELETE FROM history');
        }
        catch (e) {
            Logger.error(TAG, `clearHistory failed: ${String(e)}`);
        }
    }
    static async getReadingProgress(id: string, source: string): Promise<ReadingProgress> {
        if (!Database.store)
            return new ReadingProgress();
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
        }
        catch (e) {
            return new ReadingProgress();
        }
    }
    // --- Favorites ---
    static async insertFavorite(id: string, title: string, coverUrl: string, source: string): Promise<void> {
        if (!Database.store)
            return;
        try {
            const bucket: relationalStore.ValuesBucket = {
                'id': id, 'title': title, 'coverUrl': coverUrl,
                'source': source, 'addTime': Date.now()
            };
            await Database.store.insert('favorites', bucket);
        }
        catch (e) {
            Logger.error(TAG, `insertFavorite failed: ${String(e)}`);
        }
    }
    static async removeFavorite(id: string, source: string): Promise<void> {
        if (!Database.store)
            return;
        try {
            const predicates = new relationalStore.RdbPredicates('favorites');
            predicates.equalTo('id', id).equalTo('source', source);
            await Database.store.delete(predicates);
        }
        catch (e) {
            Logger.error(TAG, `removeFavorite failed: ${String(e)}`);
        }
    }
    static async isFavorite(id: string, source: string): Promise<boolean> {
        if (!Database.store)
            return false;
        try {
            const predicates = new relationalStore.RdbPredicates('favorites');
            predicates.equalTo('id', id).equalTo('source', source);
            const resultSet = await Database.store.query(predicates, ['id']);
            const exists = resultSet.goToNextRow();
            resultSet.close();
            return exists;
        }
        catch (e) {
            return false;
        }
    }
    static async queryFavorites(): Promise<FavoriteItem[]> {
        if (!Database.store)
            return [];
        try {
            const predicates = new relationalStore.RdbPredicates('favorites');
            predicates.orderByDesc('addTime');
            const resultSet = await Database.store.query(predicates, ['id', 'title', 'coverUrl', 'source', 'addTime']);
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
        }
        catch (e) {
            Logger.error(TAG, `queryFavorites failed: ${String(e)}`);
            return [];
        }
    }
    // --- Downloads ---
    static async insertDownload(id: string, title: string, coverUrl: string, source: string, downloadPath: string): Promise<void> {
        if (!Database.store)
            return;
        try {
            const bucket: relationalStore.ValuesBucket = {
                'id': id, 'title': title, 'coverUrl': coverUrl,
                'source': source, 'downloadPath': downloadPath,
                'downloadTime': Date.now()
            };
            await Database.store.insert('downloads', bucket);
        }
        catch (e) {
            Logger.error(TAG, `insertDownload failed: ${String(e)}`);
        }
    }
    static async removeDownload(id: string, source: string): Promise<void> {
        if (!Database.store)
            return;
        try {
            const predicates = new relationalStore.RdbPredicates('downloads');
            predicates.equalTo('id', id).equalTo('source', source);
            await Database.store.delete(predicates);
        }
        catch (e) {
            Logger.error(TAG, `removeDownload failed: ${String(e)}`);
        }
    }
    static async queryDownloads(): Promise<DownloadItem[]> {
        if (!Database.store)
            return [];
        try {
            const predicates = new relationalStore.RdbPredicates('downloads');
            predicates.orderByDesc('downloadTime');
            const resultSet = await Database.store.query(predicates, ['id', 'title', 'coverUrl', 'source', 'downloadPath', 'downloadTime']);
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
        }
        catch (e) {
            Logger.error(TAG, `queryDownloads failed: ${String(e)}`);
            return [];
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
export class ReadingProgress {
    lastChapter: string = '';
    lastPage: number = 0;
}
