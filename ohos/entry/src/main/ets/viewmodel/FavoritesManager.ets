// viewmodel/FavoritesManager.ets - 收藏管理
import { Database, FavoriteItem } from '../data/database/Database';
import { Logger } from '../common/Logger';

const TAG = 'FavoritesManager';

export class FavoritesManager {
  static items: FavoriteItem[] = [];

  static async loadFavorites(): Promise<FavoriteItem[]> {
    try {
      FavoritesManager.items = await Database.queryFavorites();
      Logger.info(TAG, `Loaded ${FavoritesManager.items.length} favorites`);
      return FavoritesManager.items;
    } catch (e) {
      Logger.error(TAG, `loadFavorites failed: ${String(e)}`);
      return [];
    }
  }

  static async toggleFavorite(id: string, title: string, coverUrl: string, source: string): Promise<boolean> {
    try {
      const isFav = await Database.isFavorite(id, source);
      if (isFav) {
        await Database.removeFavorite(id, source);
        FavoritesManager.items = FavoritesManager.items.filter(
          (item: FavoriteItem) => !(item.id === id && item.source === source)
        );
        Logger.info(TAG, `Removed favorite: ${id} (${source})`);
        return false;
      } else {
        await Database.insertFavorite(id, title, coverUrl, source);
        FavoritesManager.items = await Database.queryFavorites();
        Logger.info(TAG, `Added favorite: ${id} (${source})`);
        return true;
      }
    } catch (e) {
      Logger.error(TAG, `toggleFavorite failed: ${String(e)}`);
      return false;
    }
  }

  static async removeFavorite(id: string, source: string): Promise<void> {
    try {
      await Database.removeFavorite(id, source);
      FavoritesManager.items = FavoritesManager.items.filter(
        (item: FavoriteItem) => !(item.id === id && item.source === source)
      );
      Logger.info(TAG, `Removed favorite: ${id} (${source})`);
    } catch (e) {
      Logger.error(TAG, `removeFavorite failed: ${String(e)}`);
    }
  }

  static async isFavorite(id: string, source: string): Promise<boolean> {
    try {
      return await Database.isFavorite(id, source);
    } catch (e) {
      Logger.error(TAG, `isFavorite check failed: ${String(e)}`);
      return false;
    }
  }

  static isFavoritesEmpty(): boolean {
    return FavoritesManager.items.length === 0;
  }

  static getFavoritesCount(): number {
    return FavoritesManager.items.length;
  }
}
