// data/api/JmApi.ets - 禁漫天堂 API 客户端 (完整版)
import { Network } from '../../common/Network';
import { Logger } from '../../common/Logger';
import { Comic } from '../model/Comic';
import { Chapter } from '../model/Chapter';
import { ApiConstants } from '../../common/Constants';
import { Settings } from '../preferences/Settings';
import cryptoFramework from '@ohos.security.cryptoFramework';

const TAG = 'JmApi';
const DOMAIN = 0x0000;

export class JmApi {
  private static currentDomain: string = ApiConstants.JM_DEFAULT_BASE;
  private static domains: string[] = [];
  private static cdnUrls: string[] = ApiConstants.JM_CDN_URLS;
  private static imgHost: string = ApiConstants.JM_CDN_URLS[0];
  private static domainIndex: number = 0;
  private static lastDomainUpdate: number = 0;
  private static readonly DOMAIN_UPDATE_INTERVAL: number = 24 * 60 * 60 * 1000;
  private static readonly AUTH_KEY: string = ApiConstants.JM_AUTH_KEY;
  private static readonly APP_VERSION: string = ApiConstants.JM_APP_VERSION;
  private static readonly DOMAIN_SECRET_BYTES: number[] = ApiConstants.JM_DOMAIN_SECRET;
  private static readonly DOMAIN_SECRET_STR: string = JmApi.bytesToString(ApiConstants.JM_DOMAIN_SECRET);

  // ========== Public Methods ==========

  static getDomain(): string {
    return JmApi.currentDomain;
  }

  static async init(): Promise<void> {
    const savedDomains: string[] = await Settings.getStringList('jm_domains', []);
    if (savedDomains.length > 0) {
      JmApi.domains = savedDomains;
    }
    JmApi.domainIndex = await Settings.getNumber('jm_domain_index', 0);
    JmApi.imgHost = await Settings.getString('jm_img_host', ApiConstants.JM_CDN_URLS[0]);
    JmApi.lastDomainUpdate = await Settings.getNumber('jm_domain_update_time', 0);

    if (JmApi.domains.length === 0) {
      JmApi.domains = ApiConstants.JM_CDN_URLS;
    }
    if (JmApi.domainIndex >= 0 && JmApi.domainIndex < JmApi.domains.length) {
      JmApi.currentDomain = JmApi.domains[JmApi.domainIndex];
    }

    await JmApi.autoRefreshDomains();
  }

  static async getComics(page: number): Promise<Comic[]> {
    await JmApi.ensureDomain();
    const data: Record<string, object> = await JmApi.apiGet('/promote', { 'page': String(page) });
    const list: object[] = data['list'] as object[] ?? [];
    const result: Comic[] = [];
    for (let i = 0; i < list.length; i++) {
      const item: Record<string, object> = list[i] as Record<string, object>;
      result.push(JmApi.parseComicBrief(item));
    }
    return result;
  }

  static async search(keyword: string, page: number, order: string = 'mr'): Promise<Comic[]> {
    await JmApi.ensureDomain();
    const data: Record<string, object> = await JmApi.apiGet('/search', {
      'search_query': keyword,
      'o': order,
      'page': String(page)
    });
    const list: object[] = data['list'] as object[] ?? [];
    const result: Comic[] = [];
    for (let i = 0; i < list.length; i++) {
      const item: Record<string, object> = list[i] as Record<string, object>;
      result.push(JmApi.parseComicBrief(item));
    }
    return result;
  }

  static async getComicInfo(id: string): Promise<Comic> {
    await JmApi.ensureDomain();
    const data: Record<string, object> = await JmApi.apiGet('/album', { 'id': id });
    const comic: Comic = new Comic();
    comic.id = id;
    comic.title = (data['name'] as string) ?? '';
    comic.author = Array.isArray(data['author']) ? (data['author'] as string[]).join(', ') : (data['author'] as string) ?? '';
    comic.description = (data['description'] as string) ?? '';
    comic.likes = (data['likes'] as number) ?? 0;
    comic.source = 'jm';

    const tags: string[] = [];
    const tagsObj: object[] = data['tags'] as object[] ?? [];
    for (let i = 0; i < tagsObj.length; i++) {
      const t: Record<string, object> = tagsObj[i] as Record<string, object>;
      tags.push((t['name'] as string) ?? '');
    }
    comic.tags = tags;
    comic.categories = tags;

    const series: Record<string, string> = data['series'] as Record<string, string> ?? {};
    const seriesKeys: string[] = Object.keys(series);
    comic.chapterCount = seriesKeys.length;

    const coverId: string = (data['related_ids'] as object[] as string[])[0] ?? id;
    comic.coverUrl = JmApi.imgUrl(`/media/albums/${coverId}_3x4.jpg`);

    return comic;
  }

  static async getChapter(id: string): Promise<Chapter> {
    await JmApi.ensureDomain();
    const data: Record<string, object> = await JmApi.apiGet('/chapter', { 'id': id });
    const chapter: Chapter = new Chapter();
    chapter.id = id;
    chapter.title = (data['name'] as string) ?? '';
    chapter.comicId = (data['album_id'] as string) ?? '';

    const images: object[] = data['images'] as object[] ?? [];
    const urls: string[] = [];
    for (let i = 0; i < images.length; i++) {
      const img: Record<string, object> = images[i] as Record<string, object>;
      const url: string = (img['url'] as string) ?? '';
      if (url !== '') {
        urls.push(JmApi.imgUrl(url));
      }
    }
    chapter.imageUrls = urls;
    chapter.pages = urls.length;
    return chapter;
  }

  static async getCategories(): Promise<string[]> {
    await JmApi.ensureDomain();
    const data: Record<string, object> = await JmApi.apiGet('/categories', {});
    const categories: object[] = data['categories'] as object[] ?? [];
    const result: string[] = [];
    for (let i = 0; i < categories.length; i++) {
      const cat: Record<string, object> = categories[i] as Record<string, object>;
      result.push((cat['name'] as string) ?? '');
    }
    return result;
  }

  static async getHotTags(): Promise<string[]> {
    await JmApi.ensureDomain();
    const data: Record<string, object> = await JmApi.apiGet('/hot_tags', {});
    const tags: object[] = data['tags'] as object[] ?? [];
    const result: string[] = [];
    for (let i = 0; i < tags.length; i++) {
      const tag: Record<string, object> = tags[i] as Record<string, object>;
      result.push((tag['name'] as string) ?? '');
    }
    return result;
  }

  // ========== Domain Management ==========

  static async fetchDomains(): Promise<string[]> {
    for (let i = 0; i < ApiConstants.JM_DOMAIN_URLS.length; i++) {
      try {
        const resp: string = await Network.get(ApiConstants.JM_DOMAIN_URLS[i]);
        if (resp !== '') {
          const decrypted: string = await JmApi.aesEcbDecrypt(resp, JmApi.DOMAIN_SECRET_STR);
          if (decrypted !== '') {
            const parsed: Record<string, object> = JSON.parse(decrypted) as Record<string, object>;
            const serverList: string[] = parsed['Server'] as string[] ?? [];
            const domains: string[] = serverList.slice(0, 4);
            if (domains.length > 0) {
              JmApi.domains = domains;
              JmApi.lastDomainUpdate = Date.now();
              await Settings.putNumber('jm_domain_update_time', JmApi.lastDomainUpdate);
              await Settings.putStringList('jm_domains', domains);
              Logger.info(TAG, `Fetched ${domains.length} domains from remote`);
              return domains;
            }
          }
        }
      } catch (e) {
        Logger.error(TAG, `fetchDomains from URL[${i}] failed: ${String(e)}`);
      }
    }
    return [];
  }

  static async selectDomain(): Promise<number | undefined> {
    if (JmApi.domains.length === 0) {
      await JmApi.fetchDomains();
    }
    if (JmApi.domains.length === 0) {
      return undefined;
    }

    for (let i = 0; i < JmApi.domains.length; i++) {
      const domain: string = JmApi.domains[i];
      try {
        const timestamp: string = String(Math.floor(Date.now() / 1000));
        const token: string = JmApi.generateToken(timestamp);
        const headers: Record<string, string> = {
          'token': token,
          'tokenparam': `${timestamp},${JmApi.APP_VERSION}`,
          'User-Agent': 'Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 Chrome/100.0 Mobile Safari/537.36',
          'X-Requested-With': 'com.example.app',
          'Origin': 'https://localhost',
          'Referer': 'https://localhost/'
        };
        const url: string = `https://${domain}/login`;
        const code: number = await Network.requestWithCode(url, 1, headers, '&');
        if (code === 401) {
          JmApi.domainIndex = i;
          JmApi.currentDomain = domain;
          await Settings.putString('jm_current_domain', domain);
          await Settings.putNumber('jm_domain_index', JmApi.domainIndex);
          Logger.info(TAG, `Selected domain: ${domain}`);
          return i;
        }
      } catch (e) {
        Logger.error(TAG, `selectDomain check ${domain} failed`);
      }
    }
    return undefined;
  }

  static async healthCheck(): Promise<boolean> {
    return await Network.headCheck(JmApi.currentDomain, 5000);
  }

  static async autoSwitch(): Promise<void> {
    const isHealthy: boolean = await JmApi.healthCheck();
    if (!isHealthy) {
      Logger.warn(TAG, `Current domain ${JmApi.currentDomain} unhealthy, switching...`);
      await JmApi.selectDomain();
    }
  }

  static async updateImgUrl(index: number): Promise<void> {
    if (index >= 0 && index < JmApi.cdnUrls.length) {
      JmApi.imgHost = JmApi.cdnUrls[index];
      await Settings.putString('jm_img_host', JmApi.imgHost);
    }
  }

  static getImgHost(): string {
    return JmApi.imgHost;
  }

  // ========== Private Methods ==========

  private static async ensureDomain(): Promise<void> {
    const now: number = Date.now();
    if (now - JmApi.lastDomainUpdate > JmApi.DOMAIN_UPDATE_INTERVAL) {
      await JmApi.fetchDomains();
    }
    await JmApi.autoSwitch();
  }

  private static async autoRefreshDomains(): Promise<void> {
    const now: number = Date.now();
    if (now - JmApi.lastDomainUpdate > JmApi.DOMAIN_UPDATE_INTERVAL) {
      await JmApi.fetchDomains();
    }
  }

  private static async apiGet(path: string, params: Record<string, string>): Promise<Record<string, object>> {
    const timestamp: string = String(Math.floor(Date.now() / 1000));
    const token: string = JmApi.generateToken(timestamp);

    let fullUrl: string = `${JmApi.currentDomain}${path}`;
    const paramKeys: string[] = Object.keys(params);
    const hasQuery: boolean = path.indexOf('?') !== -1;
    const parts: string[] = [];
    for (let i = 0; i < paramKeys.length; i++) {
      const key: string = paramKeys[i];
      if (params[key] !== '') {
        parts.push(`${key}=${encodeURIComponent(params[key])}`);
      }
    }
    if (parts.length > 0) {
      fullUrl += hasQuery ? '&' : '?';
      fullUrl += parts.join('&');
    }

    const sep: string = fullUrl.indexOf('?') !== -1 ? '&' : '?';
    fullUrl += `${sep}ts=${timestamp}&token=${token}`;

    const headers: Record<string, string> = {
      'token': token,
      'tokenparam': `${timestamp},${JmApi.APP_VERSION}`,
      'User-Agent': 'Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 Chrome/100.0 Mobile Safari/537.36',
      'X-Requested-With': 'com.example.app',
      'Origin': 'https://localhost',
      'Referer': 'https://localhost/'
    };

    const resp: string = await Network.get(fullUrl, headers);
    if (resp === '') {
      await JmApi.selectDomain();
      throw new Error('Empty response from JM API');
    }
    const result: Record<string, object> = JSON.parse(resp) as Record<string, object>;
    const code: number = result['code'] as number ?? 0;
    if (code !== 200) {
      const info: string = (result['info'] as string) ?? 'Unknown error';
      Logger.error(TAG, `apiGet ${path} error (code=${code}): ${info}`);
      await JmApi.selectDomain();
      throw new Error(info);
    }
    return (result['data'] as Record<string, object>) ?? result;
  }

  private static generateToken(timestamp: string): string {
    const raw: string = `${timestamp}${JmApi.AUTH_KEY}`;
    return JmApi.md5Hex(raw);
  }

  private static md5Hex(input: string): string {
    const bytes: number[] = [];
    for (let i = 0; i < input.length; i++) {
      bytes.push(input.charCodeAt(i) & 0xFF);
    }
    // MD5 implementation
    const msgLen: number = bytes.length;
    bytes.push(0x80);
    while (bytes.length % 64 !== 56) {
      bytes.push(0x00);
    }
    const bitLen: number = msgLen * 8;
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
    for (let t = 0; t < 64; t++) {
      K.push(Math.floor(Math.abs(Math.sin(t + 1)) * 4294967296));
    }

    for (let i = 0; i < bytes.length; i += 64) {
      const M: number[] = [];
      for (let j = 0; j < 16; j++) {
        M[j] = (bytes[i + j * 4]) | (bytes[i + j * 4 + 1] << 8) |
                (bytes[i + j * 4 + 2] << 16) | (bytes[i + j * 4 + 3] << 24);
      }

      let A: number = a0;
      let B: number = b0;
      let C: number = c0;
      let D: number = d0;

      for (let t = 0; t < 64; t++) {
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
        const temp: number = (B + (((A + F + K[t] + M[g]) << S[t]) |
          (((A + F + K[t] + M[g]) >>> (32 - S[t]))))) | 0;
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

    const words: number[] = [a0, b0, c0, d0];
    let hex: string = '';
    for (let i = 0; i < 4; i++) {
      const w: number = words[i];
      hex += JmApi.hexByte(w & 0xFF);
      hex += JmApi.hexByte((w >> 8) & 0xFF);
      hex += JmApi.hexByte((w >> 16) & 0xFF);
      hex += JmApi.hexByte((w >> 24) & 0xFF);
    }
    return hex;
  }

  private static hexByte(b: number): string {
    const h: string = (b & 0xFF).toString(16);
    return h.length < 2 ? '0' + h : h;
  }

  private static bytesToString(bytes: number[]): string {
    let result: string = '';
    for (let i = 0; i < bytes.length; i++) {
      result += String.fromCharCode(bytes[i]);
    }
    return result;
  }

  private static async aesEcbDecrypt(base64Data: string, keyStr: string): Promise<string> {
    try {
      // Step 1: MD5 hash the key string
      const md5Bytes: number[] = JmApi.strToBytes(keyStr);
      const md5: cryptoFramework.Md = cryptoFramework.createMd('MD5');
      md5.update({ data: new Uint8Array(md5Bytes) });
      const hashResult: cryptoFramework.DataBlob = await md5.digest();
      const keyBytes: Uint8Array = hashResult.data;

      // Step 2: Base64 decode the data
      const decoded: Uint8Array = JmApi.base64Decode(base64Data);

      // Step 3: AES-ECB decrypt
      const cipher: cryptoFramework.Cipher = cryptoFramework.createCipher('AES-128-ECB');
      const key: cryptoFramework.CryptoKey = await cryptoFramework.generateSymKeyGenerator('AES-128').generateSymKey({ data: keyBytes });
      await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, key, null);
      const decrypted: cryptoFramework.DataBlob = await cipher.doFinal({ data: decoded });

      // Step 4: UTF-8 decode
      const result: string = JmApi.bytesToString(Array.from(decrypted.data));

      // Step 5: Trim trailing garbage (find last } or ])
      let endIdx: number = result.length - 1;
      while (endIdx >= 0) {
        const ch: string = result.charAt(endIdx);
        if (ch === '}' || ch === ']') {
          break;
        }
        endIdx--;
      }
      return result.substring(0, endIdx + 1);
    } catch (e) {
      Logger.error(TAG, `aesEcbDecrypt failed: ${String(e)}`);
      return '';
    }
  }

  private static strToBytes(str: string): number[] {
    const bytes: number[] = [];
    for (let i = 0; i < str.length; i++) {
      bytes.push(str.charCodeAt(i) & 0xFF);
    }
    return bytes;
  }

  private static base64Decode(input: string): Uint8Array {
    const chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    const bytes: number[] = [];
    let buffer: number = 0;
    let bits: number = 0;
    for (let i = 0; i < input.length; i++) {
      const c: string = input.charAt(i);
      if (c === '=' || c === '\n' || c === '\r') {
        continue;
      }
      const val: number = chars.indexOf(c);
      if (val === -1) {
        continue;
      }
      buffer = (buffer << 6) | val;
      bits += 6;
      if (bits >= 8) {
        bits -= 8;
        bytes.push((buffer >> bits) & 0xFF);
      }
    }
    return new Uint8Array(bytes);
  }

  private static imgUrl(path: string): string {
    if (path.indexOf('http') === 0) {
      return path;
    }
    return `${JmApi.imgHost}${path}`;
  }

  private static parseComicBrief(item: Record<string, object>): Comic {
    const comic: Comic = new Comic();
    comic.id = (item['id'] as string) ?? '';
    comic.title = (item['name'] as string) ?? '';
    comic.author = (item['author'] as string) ?? '';
    comic.description = (item['description'] as string) ?? '';
    comic.source = 'jm';

    const categories: object[] = item['categories'] as object[] ?? [];
    const tags: string[] = [];
    for (let i = 0; i < categories.length; i++) {
      const cat: Record<string, object> = categories[i] as Record<string, object>;
      tags.push((cat['title'] as string) ?? '');
    }
    comic.tags = tags;
    comic.categories = tags;

    const coverId: string = (item['id'] as string) ?? '';
    comic.coverUrl = JmApi.imgUrl(`/media/albums/${coverId}_3x4.jpg`);

    return comic;
  }
}
