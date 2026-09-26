// data/api/JmApi.ets - 禁漫天堂 API 客户端
import { Network } from '../../common/Network';
import { Logger } from '../../common/Logger';
import { Comic, ComicBrief } from '../model/Comic';
import { Chapter } from '../model/Chapter';
import { ApiConstants } from '../../common/Constants';
import { Settings } from '../preferences/Settings';

const TAG = 'JmApi';

interface JmApiResult {
  code: number;
  info: string;
  data: JmApiData;
}

interface JmApiData {
  list: JmComicItem[];
  total: number;
  page: number;
  limit: number;
}

interface JmComicItem {
  id: string;
  author: string;
  name: string;
  description: string;
  category: JmCategory[];
  image: string;
  status: number;
  isFavorite: boolean;
  update_at: string;
  comment_total: number;
  related_groups: JmGroup[];
  chapter_list: JmChapterBrief[];
}

interface JmCategory {
  id: string;
  title: string;
}

interface JmChapterBrief {
  id: string;
  title: string;
  order: string;
}

interface JmGroup {
  name: string;
  description: string;
}

interface JmChapterDetail {
  id: string;
  title: string;
  images: JmImageItem[];
}

interface JmImageItem {
  url: string;
}

export class JmApi {
  private static currentDomain: string = ApiConstants.JM_DEFAULT_BASE;
  private static domains: string[] = [];
  private static cdnUrls: string[] = ApiConstants.JM_CDN_URLS;
  private static domainIndex: number = 0;
  private static lastDomainUpdate: number = 0;
  private static readonly DOMAIN_UPDATE_INTERVAL: number = 24 * 60 * 60 * 1000;
  private static readonly SECRET: string = ApiConstants.JM_SECRET;
  private static readonly AUTH_KEY: string = ApiConstants.JM_AUTH_KEY;
  private static readonly DOMAIN_SECRET: number[] = ApiConstants.JM_DOMAIN_SECRET;
  private static readonly DOMAIN_URLS: string[] = ApiConstants.JM_DOMAIN_URLS;
  private static readonly APP_VERSION: string = ApiConstants.JM_APP_VERSION;

  static getDomain(): string {
    return JmApi.currentDomain;
  }

  static async init(): Promise<void> {
    const savedDomain: string = await Settings.getString('jm_current_domain', '');
    if (savedDomain !== '') {
      JmApi.currentDomain = savedDomain;
    }
    JmApi.domainIndex = await Settings.getNumber('jm_domain_index', 0);
    JmApi.lastDomainUpdate = await Settings.getNumber('jm_domain_update_time', 0);
    await JmApi.autoSwitch();
  }

  static async fetchDomains(): Promise<string[]> {
    const results: string[] = [];
    for (let i: number = 0; i < JmApi.DOMAIN_URLS.length; i++) {
      try {
        const resp: string = await Network.get(JmApi.DOMAIN_URLS[i]);
        if (resp !== '') {
          const decrypted: string = JmApi.decryptDomainData(resp);
          const lines: string[] = decrypted.split('\n');
          for (let j: number = 0; j < lines.length; j++) {
            const line: string = lines[j].trim();
            if (line !== '' && line.indexOf('.') !== -1 && line.indexOf('://') === -1) {
              results.push(`https://${line}`);
            } else if (line.indexOf('://') !== -1) {
              results.push(line);
            }
          }
          break;
        }
      } catch (e) {
        Logger.error(TAG, `fetchDomains from ${JmApi.DOMAIN_URLS[i]} failed`);
      }
    }
    if (results.length > 0) {
      JmApi.domains = results;
      JmApi.lastDomainUpdate = Date.now();
      await Settings.putNumber('jm_domain_update_time', JmApi.lastDomainUpdate);
      await Settings.putStringList('jm_domains', results);
    }
    return results;
  }

  static async selectDomain(): Promise<void> {
    if (JmApi.domains.length === 0) {
      JmApi.domains = await Settings.getStringList('jm_domains', []);
    }
    if (JmApi.domains.length === 0) {
      await JmApi.fetchDomains();
    }
    if (JmApi.domains.length === 0) {
      JmApi.currentDomain = ApiConstants.JM_DEFAULT_BASE;
      return;
    }
    JmApi.domainIndex = (JmApi.domainIndex + 1) % JmApi.domains.length;
    JmApi.currentDomain = JmApi.domains[JmApi.domainIndex];
    await Settings.putString('jm_current_domain', JmApi.currentDomain);
    await Settings.putNumber('jm_domain_index', JmApi.domainIndex);
  }

  static async healthCheck(): Promise<boolean> {
    const ok: boolean = await Network.headCheck(JmApi.currentDomain, 5000);
    if (!ok) {
      Logger.warn(TAG, `healthCheck failed for ${JmApi.currentDomain}`);
    }
    return ok;
  }

  static async autoSwitch(): Promise<void> {
    const now: number = Date.now();
    if (now - JmApi.lastDomainUpdate > JmApi.DOMAIN_UPDATE_INTERVAL) {
      await JmApi.fetchDomains();
    }
    const isHealthy: boolean = await JmApi.healthCheck();
    if (!isHealthy) {
      await JmApi.selectDomain();
    }
  }

  static async getComics(page: number): Promise<Record<string, object>> {
    await JmApi.autoSwitch();
    const params: Record<string, string> = {
      'page': String(page),
      'is_hd': '0'
    };
    return JmApi.apiGet('/api/v1/me/comic/list', params);
  }

  static async search(keyword: string, page: number): Promise<Record<string, object>> {
    await JmApi.autoSwitch();
    const params: Record<string, string> = {
      'page': String(page),
      'is_hd': '0',
      'keyword': keyword
    };
    return JmApi.apiGet('/api/v1/search/comic', params);
  }

  static async getComicInfo(id: string): Promise<Comic> {
    await JmApi.autoSwitch();
    const params: Record<string, string> = {};
    const result: Record<string, object> = await JmApi.apiGet(`/api/v1/comic/detail?comicId=${id}`, params);
    const data: JmComicItem = result['data'] as JmComicItem;
    return JmApi.parseComic(data);
  }

  static async getChapter(id: string): Promise<Chapter> {
    await JmApi.autoSwitch();
    const params: Record<string, string> = {};
    const result: Record<string, object> = await JmApi.apiGet(`/api/v1/chapter?chapterId=${id}`, params);
    const data: JmChapterDetail = result['data'] as JmChapterDetail;
    const chapter: Chapter = new Chapter();
    chapter.id = data.id;
    chapter.title = data.title;
    chapter.imageUrls = [];
    for (let i: number = 0; i < data.images.length; i++) {
      chapter.imageUrls.push(JmApi.cdnUrl(data.images[i].url));
    }
    chapter.pages = data.images.length;
    return chapter;
  }

  private static async apiGet(path: string, params: Record<string, string>): Promise<Record<string, object>> {
    const url: string = `${JmApi.currentDomain}${path}`;
    const timestamp: string = String(Math.floor(Date.now() / 1000));
    const token: string = JmApi.generateToken(timestamp);

    let fullUrl: string = url;
    const paramKeys: string[] = Object.keys(params);
    if (paramKeys.length > 0) {
      const parts: string[] = [];
      for (let i: number = 0; i < paramKeys.length; i++) {
        const key: string = paramKeys[i];
        parts.push(`${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`);
      }
      if (path.indexOf('?') === -1) {
        fullUrl = fullUrl + '?' + parts.join('&');
      } else {
        fullUrl = fullUrl + '&' + parts.join('&');
      }
    }

    const sep: string = path.indexOf('?') !== -1 || paramKeys.length > 0 ? '&' : '?';
    fullUrl = fullUrl + `${sep}ts=${timestamp}&token=${token}&sign=${JmApi.generateSign(fullUrl, timestamp)}`;

    const headers: Record<string, string> = {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0 Mobile Safari/537.36',
      'Device': '2',
      'Authorization': token,
      'Version': JmApi.APP_VERSION
    };

    const resp: string = await Network.get(fullUrl, headers);
    const result: JmApiResult = JSON.parse(resp) as JmApiResult;
    if (result.code !== 200) {
      Logger.error(TAG, `apiGet ${path} error: ${result.info}`);
      await JmApi.selectDomain();
      throw new Error(result.info);
    }
    return result as Record<string, object>;
  }

  private static generateToken(timestamp: string): string {
    const raw: string = `${timestamp}${JmApi.AUTH_KEY}`;
    return JmApi.md5Hex(raw);
  }

  private static generateSign(url: string, timestamp: string): string {
    const raw: string = `${url}&${timestamp}`;
    return JmApi.md5Hex(raw);
  }

  private static md5Hex(input: string): string {
    const bytes: number[] = [];
    for (let i: number = 0; i < input.length; i++) {
      const code: number = input.charCodeAt(i);
      if (code < 0x80) {
        bytes.push(code);
      } else if (code < 0x800) {
        bytes.push(0xC0 | (code >> 6));
        bytes.push(0x80 | (code & 0x3F));
      } else {
        bytes.push(0xE0 | (code >> 12));
        bytes.push(0x80 | ((code >> 6) & 0x3F));
        bytes.push(0x80 | (code & 0x3F));
      }
    }

    const originalLength: number = bytes.length;
    bytes.push(0x80);
    while ((bytes.length % 64) !== 56) {
      bytes.push(0x00);
    }
    const bitLen: number = originalLength * 8;
    bytes.push(bitLen & 0xFF, (bitLen >> 8) & 0xFF, (bitLen >> 16) & 0xFF, (bitLen >> 24) & 0xFF);
    bytes.push(0, 0, 0, 0);

    let a0: number = 0x67452301;
    let b0: number = 0xEFCDAB89;
    let c0: number = 0x98BADCFE;
    let d0: number = 0x10325476;

    const S: number[] = [
      7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
      5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
      4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
      6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
    ];

    const K: number[] = [];
    for (let t: number = 0; t < 64; t++) {
      K.push(Math.floor(Math.abs(Math.sin(t + 1)) * 4294967296));
    }

    for (let i: number = 0; i < bytes.length; i += 64) {
      const M: number[] = new Array<number>(16);
      for (let j: number = 0; j < 16; j++) {
        M[j] = (bytes[i + j * 4]) | (bytes[i + j * 4 + 1] << 8) | (bytes[i + j * 4 + 2] << 16) | (bytes[i + j * 4 + 3] << 24);
      }

      let A: number = a0;
      let B: number = b0;
      let C: number = c0;
      let D: number = d0;

      for (let t: number = 0; t < 64; t++) {
        let F: number = 0;
        let g: number = 0;
        if (t < 16) {
          F = (B & C) | ((~B) & D);
          g = t;
        } else if (t < 32) {
          F = (D & B) | ((~D) & C);
          g = (5 * t + 1) % 16;
        } else if (t < 48) {
          F = B ^ C ^ D;
          g = (3 * t + 5) % 16;
        } else {
          F = C ^ (B | (~D));
          g = (7 * t) % 16;
        }
        const temp: number = (B + (((A + F + K[t] + M[g]) << S[t]) | (((A + F + K[t] + M[g]) >>> (32 - S[t]))))) | 0;
        A = D;
        D = C;
        C = B;
        B = temp;
      }

      a0 = (a0 + A) | 0;
      b0 = (b0 + B) | 0;
      c0 = (c0 + C) | 0;
      d0 = (d0 + D) | 0;
    }

    let hex: string = '';
    const words: number[] = [a0, b0, c0, d0];
    for (let i: number = 0; i < 4; i++) {
      const w: number = words[i];
      const b1: string = ((w & 0xFF) < 16 ? '0' : '') + (w & 0xFF).toString(16);
      const b2: string = (((w >> 8) & 0xFF) < 16 ? '0' : '') + ((w >> 8) & 0xFF).toString(16);
      const b3: string = (((w >> 16) & 0xFF) < 16 ? '0' : '') + ((w >> 16) & 0xFF).toString(16);
      const b4: string = (((w >> 24) & 0xFF) < 16 ? '0' : '') + ((w >> 24) & 0xFF).toString(16);
      hex = hex + b1 + b2 + b3 + b4;
    }
    return hex;
  }

  private static decryptDomainData(encrypted: string): string {
    const chars: string[] = [];
    for (let i: number = 0; i < encrypted.length; i++) {
      const code: number = encrypted.charCodeAt(i);
      chars.push(String.fromCharCode(code ^ 0x42));
    }
    return chars.join('');
  }

  private static cdnUrl(path: string): string {
    if (path.indexOf('http') === 0) {
      return path;
    }
    const cdnIndex: number = Math.floor(Math.random() * JmApi.cdnUrls.length);
    return `${JmApi.cdnUrls[cdnIndex]}${path}`;
  }

  private static parseComic(item: JmComicItem): Comic {
    const comic: Comic = new Comic();
    comic.id = item.id;
    comic.title = item.name;
    comic.author = item.author;
    comic.description = item.description;
    comic.coverUrl = JmApi.cdnUrl(item.image);
    comic.isFavorite = item.isFavorite;
    comic.comments = item.comment_total;
    comic.source = 'jm';

    const tags: string[] = [];
    for (let i: number = 0; i < item.category.length; i++) {
      tags.push(item.category[i].title);
    }
    comic.categories = tags;
    comic.tags = tags;

    if (item.chapter_list !== undefined) {
      comic.chapterCount = item.chapter_list.length;
    }

    return comic;
  }
}
