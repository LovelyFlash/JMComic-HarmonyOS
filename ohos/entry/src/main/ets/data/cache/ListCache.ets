// data/cache/ListCache.ets - 收藏页 / 发现页列表 JSON 缓存（列表首屏秒开，随后后台刷新）
// 仅缓存展示所需字段与首页分页信息；键按 JM 用户区分，避免切换账号时串数据。
import { Comic } from '../model/Comic';
import { JmFolder, JmHomeSection } from '../api/JmApi';
import { Settings } from '../preferences/Settings';
import { Logger } from '../../common/Logger';

const TAG = 'ListCache';
const KEY_FAV = 'list_cache_fav_v1';
const KEY_DISCOVER_HOME = 'list_cache_discover_home_v1';
const KEY_DISCOVER_LATEST = 'list_cache_discover_latest_v1';

/** 收藏夹漫画首页缓存 */
export class CachedComicPage {
  comics: Comic[] = [];
  maxPage: number = 1;
}

export class ListCache {
  private static favKey(userId: string): string {
    return `${KEY_FAV}_${userId.length > 0 ? userId : 'guest'}`;
  }

  // ---- 收藏页 ----

  static async loadFolders(userId: string): Promise<JmFolder[] | null> {
    const raw: string = await Settings.getString(ListCache.favKey(userId) + '_folders', '');
    if (raw.length === 0) {
      return null;
    }
    try {
      const arr: Object[] = JSON.parse(raw) as Object[];
      const out: JmFolder[] = [];
      for (const item of arr) {
        const r: Record<string, Object> = item as Record<string, Object>;
        const folder: JmFolder = new JmFolder();
        folder.id = ListCache.str(r, 'id');
        folder.name = ListCache.str(r, 'name');
        if (folder.id.length > 0) {
          out.push(folder);
        }
      }
      return out.length > 0 ? out : null;
    } catch (e) {
      Logger.warn(TAG, `loadFolders failed: ${Logger.describe(e)}`);
      return null;
    }
  }

  static async saveFolders(userId: string, folders: JmFolder[]): Promise<void> {
    const arr: Record<string, Object>[] = [];
    for (const folder of folders) {
      arr.push({ 'id': folder.id, 'name': folder.name });
    }
    await Settings.setString(ListCache.favKey(userId) + '_folders', JSON.stringify(arr));
  }

  static async loadFolderComics(userId: string, folderId: string): Promise<CachedComicPage | null> {
    const raw: string = await Settings.getString(
      ListCache.favKey(userId) + '_comics_' + folderId, '');
    if (raw.length === 0) {
      return null;
    }
    try {
      const wrapper: Record<string, Object> = JSON.parse(raw) as Record<string, Object>;
      const page: CachedComicPage = new CachedComicPage();
      page.maxPage = ListCache.num(wrapper, 'maxPage');
      if (page.maxPage <= 0) {
        page.maxPage = 1;
      }
      page.comics = ListCache.parseComics(wrapper['comics'] as Object[]);
      return page.comics.length > 0 ? page : null;
    } catch (e) {
      Logger.warn(TAG, `loadFolderComics failed: ${Logger.describe(e)}`);
      return null;
    }
  }

  static async saveFolderComics(userId: string, folderId: string, comics: Comic[],
    maxPage: number): Promise<void> {
    const wrapper: Record<string, Object> = {
      'maxPage': maxPage,
      'comics': ListCache.comicsToRecords(comics)
    };
    await Settings.setString(ListCache.favKey(userId) + '_comics_' + folderId, JSON.stringify(wrapper));
  }

  // ---- 发现页 ----

  static async loadHome(): Promise<JmHomeSection[] | null> {
    const raw: string = await Settings.getString(KEY_DISCOVER_HOME, '');
    if (raw.length === 0) {
      return null;
    }
    try {
      const arr: Object[] = JSON.parse(raw) as Object[];
      const out: JmHomeSection[] = [];
      for (const item of arr) {
        const r: Record<string, Object> = item as Record<string, Object>;
        const section: JmHomeSection = new JmHomeSection();
        section.id = ListCache.str(r, 'id');
        section.title = ListCache.str(r, 'title');
        section.comics = ListCache.parseComics(r['comics'] as Object[]);
        if (section.comics.length > 0) {
          out.push(section);
        }
      }
      return out.length > 0 ? out : null;
    } catch (e) {
      Logger.warn(TAG, `loadHome failed: ${Logger.describe(e)}`);
      return null;
    }
  }

  static async saveHome(sections: JmHomeSection[]): Promise<void> {
    const arr: Record<string, Object>[] = [];
    for (const section of sections) {
      arr.push({
        'id': section.id,
        'title': section.title,
        'comics': ListCache.comicsToRecords(section.comics)
      });
    }
    await Settings.setString(KEY_DISCOVER_HOME, JSON.stringify(arr));
  }

  static async loadLatest(): Promise<Comic[] | null> {
    const raw: string = await Settings.getString(KEY_DISCOVER_LATEST, '');
    if (raw.length === 0) {
      return null;
    }
    try {
      const comics: Comic[] = ListCache.parseComics(JSON.parse(raw) as Object[]);
      return comics.length > 0 ? comics : null;
    } catch (e) {
      Logger.warn(TAG, `loadLatest failed: ${Logger.describe(e)}`);
      return null;
    }
  }

  static async saveLatest(comics: Comic[]): Promise<void> {
    await Settings.setString(KEY_DISCOVER_LATEST, JSON.stringify(ListCache.comicsToRecords(comics)));
  }

  // ---- 序列化 ----

  private static comicsToRecords(comics: Comic[]): Record<string, Object>[] {
    const arr: Record<string, Object>[] = [];
    for (const comic of comics) {
      arr.push({
        'id': comic.id,
        'source': comic.source,
        'title': comic.title,
        'author': comic.author,
        'coverUrl': comic.coverUrl
      });
    }
    return arr;
  }

  private static parseComics(arr: Object[]): Comic[] {
    const out: Comic[] = [];
    if (!Array.isArray(arr)) {
      return out;
    }
    for (const item of arr) {
      const r: Record<string, Object> = item as Record<string, Object>;
      const comic: Comic = new Comic();
      comic.id = ListCache.str(r, 'id');
      comic.source = ListCache.str(r, 'source');
      if (comic.source.length === 0) {
        comic.source = 'jm';
      }
      comic.title = ListCache.str(r, 'title');
      comic.author = ListCache.str(r, 'author');
      comic.coverUrl = ListCache.str(r, 'coverUrl');
      if (comic.id.length > 0) {
        out.push(comic);
      }
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
}
