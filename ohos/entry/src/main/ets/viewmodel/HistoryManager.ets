// viewmodel/HistoryManager.ets - 阅读历史管理
import { Database, HistoryItem } from '../data/database/Database';
import { Logger } from '../common/Logger';

const TAG = 'HistoryManager';

export class HistoryManager {
  static items: HistoryItem[] = [];

  static async loadHistory(): Promise<HistoryItem[]> {
    try {
      HistoryManager.items = await Database.queryHistory();
      Logger.info(TAG, `Loaded ${HistoryManager.items.length} history items`);
      return HistoryManager.items;
    } catch (e) {
      Logger.error(TAG, `loadHistory failed: ${String(e)}`);
      return [];
    }
  }

  static async addHistory(id: string, title: string, coverUrl: string, source: string, lastChapter: string = '', lastPage: number = 0): Promise<void> {
    try {
      await Database.insertHistory(id, title, coverUrl, source, lastChapter, lastPage);
      Logger.info(TAG, `Added history: ${id} (${source})`);
    } catch (e) {
      Logger.error(TAG, `addHistory failed: ${String(e)}`);
    }
  }

  static async removeHistory(id: string, source: string): Promise<void> {
    try {
      await Database.removeHistory(id, source);
      HistoryManager.items = HistoryManager.items.filter(
        (item: HistoryItem) => !(item.id === id && item.source === source)
      );
      Logger.info(TAG, `Removed history: ${id} (${source})`);
    } catch (e) {
      Logger.error(TAG, `removeHistory failed: ${String(e)}`);
    }
  }

  static async clearHistory(): Promise<void> {
    try {
      await Database.clearHistory();
      HistoryManager.items = [];
      Logger.info(TAG, 'History cleared');
    } catch (e) {
      Logger.error(TAG, `clearHistory failed: ${String(e)}`);
    }
  }

  static isHistoryEmpty(): boolean {
    return HistoryManager.items.length === 0;
  }

  static getHistoryCount(): number {
    return HistoryManager.items.length;
  }
}
