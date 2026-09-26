// data/api/HtcomicApi.ets - 绅士漫画 API 客户端 (HTML Scraping)
import { Network } from '../../common/Network';
import { Logger } from '../../common/Logger';
import { Comic, ComicBrief } from '../model/Comic';
import { ApiConstants } from '../../common/Constants';
import { Settings } from '../preferences/Settings';

const TAG = 'HtcomicApi';

interface HtSearchResult {
  comics: ComicBrief[];
  currentPage: number;
  maxPage: number;
  totalCount: number;
}

export class HtcomicApi {
  private static baseUrl: string = ApiConstants.HT_DEFAULT_BASE;
  private static lastDomainUpdate: number = 0;
  private static readonly DOMAIN_UPDATE_INTERVAL: number = 24 * 60 * 60 * 1000;
  private static readonly DOMAIN_URL: string = ApiConstants.HT_DOMAIN_URL;

  static async init(): Promise<void> {
    const savedUrl: string = await Settings.getString('ht_base_url', '');
    if (savedUrl !== '') {
      HtcomicApi.baseUrl = savedUrl;
    }
    HtcomicApi.lastDomainUpdate = await Settings.getNumber('ht_domain_update_time', 0);
    await HtcomicApi.checkDomainUpdate();
  }

  static async checkDomainUpdate(): Promise<void> {
    const now: number = Date.now();
    if (now - HtcomicApi.lastDomainUpdate < HtcomicApi.DOMAIN_UPDATE_INTERVAL) {
      return;
    }
    try {
      const resp: string = await Network.get(HtcomicApi.DOMAIN_URL);
      if (resp !== '') {
        const decoded: string = HtcomicApi.base64Decode(resp);
        const domains: string[] = decoded.split('\n');
        for (let i: number = 0; i < domains.length; i++) {
          const domain: string = domains[i].trim();
          if (domain !== '' && domain.indexOf('.') !== -1) {
            let fullUrl: string = domain;
            if (domain.indexOf('http') === -1) {
              fullUrl = `https://${domain}`;
            }
            HtcomicApi.baseUrl = fullUrl;
            await Settings.putString('ht_base_url', HtcomicApi.baseUrl);
            break;
          }
        }
        HtcomicApi.lastDomainUpdate = now;
        await Settings.putNumber('ht_domain_update_time', now);
      }
    } catch (e) {
      Logger.error(TAG, 'checkDomainUpdate failed');
    }
  }

  static getBaseUrl(): string {
    return HtcomicApi.baseUrl;
  }

  static async setBaseUrl(url: string): Promise<void> {
    HtcomicApi.baseUrl = url;
    await Settings.putString('ht_base_url', url);
  }

  static async getHomePage(page: number): Promise<HtSearchResult> {
    await HtcomicApi.checkDomainUpdate();
    const url: string = `${HtcomicApi.baseUrl}/photos-index-page-${page}.html`;
    Logger.info(TAG, `getHomePage: page=${page}`);
    const body: string = await Network.get(url);
    return HtcomicApi.parseListPage(body, page);
  }

  static async search(keyword: string, page: number): Promise<HtSearchResult> {
    await HtcomicApi.checkDomainUpdate();
    const url: string = `${HtcomicApi.baseUrl}/search/index-${page}.html?keyword=${encodeURIComponent(keyword)}`;
    Logger.info(TAG, `search: keyword=${keyword}, page=${page}`);
    const body: string = await Network.get(url);
    return HtcomicApi.parseListPage(body, page);
  }

  static async getComicInfo(id: string): Promise<Comic> {
    await HtcomicApi.checkDomainUpdate();
    const url: string = `${HtcomicApi.baseUrl}/photos-${id}.html`;
    Logger.info(TAG, `getComicInfo: id=${id}`);
    const body: string = await Network.get(url);
    return HtcomicApi.parseDetailPage(body, id);
  }

  static async getImages(id: string): Promise<string[]> {
    await HtcomicApi.checkDomainUpdate();
    const urls: string[] = [];
    const url: string = `${HtcomicApi.baseUrl}/photos-${id}.html`;
    const body: string = await Network.get(url);

    const imgParts: string[] = body.split('class="photo-pic"');
    for (let i: number = 1; i < imgParts.length; i++) {
      const src: string = HtcomicApi.extractAttribute(imgParts[i], 'src');
      if (src !== '') {
        urls.push(HtcomicApi.resolveUrl(src));
      }
    }

    if (urls.length === 0) {
      const altParts: string[] = body.split('<img');
      for (let i: number = 1; i < altParts.length; i++) {
        const src: string = HtcomicApi.extractAttribute(altParts[i], 'data-src');
        if (src !== '' && src.indexOf('.jpg') !== -1) {
          urls.push(HtcomicApi.resolveUrl(src));
        } else {
          const src2: string = HtcomicApi.extractAttribute(altParts[i], 'src');
          if (src2 !== '' && src2.indexOf('.jpg') !== -1 && src2.indexOf('thumb') === -1) {
            urls.push(HtcomicApi.resolveUrl(src2));
          }
        }
      }
    }

    return urls;
  }

  private static parseListPage(html: string, currentPage: number): HtSearchResult {
    const comics: ComicBrief[] = [];
    const parts: string[] = html.split('class="pic"');
    for (let i: number = 1; i < parts.length; i++) {
      const block: string = parts[i];
      const comic: ComicBrief = new ComicBrief();

      const href: string = HtcomicApi.extractHref(block, '/photos-');
      if (href === '') {
        continue;
      }
      const idMatch: string = href.replace('/photos-', '').replace('.html', '');
      comic.id = idMatch;

      comic.title = HtcomicApi.cleanHtml(HtcomicApi.extractBetween(block, 'class="title"', '</a>'));
      comic.cover = HtcomicApi.resolveUrl(HtcomicApi.extractAttribute(block, 'src'));
      comic.author = HtcomicApi.cleanHtml(HtcomicApi.extractBetween(block, 'class="author"', '</a>'));
      comic.source = 'htcomic';

      const pagesStr: string = HtcomicApi.extractBetween(block, 'class="info">', '页');
      comic.pages = parseInt(pagesStr, 10);
      if (isNaN(comic.pages)) {
        comic.pages = 0;
      }

      comics.push(comic);
    }

    let maxPage: number = 1;
    const pageParts: string[] = html.split('page-');
    for (let i: number = 1; i < pageParts.length; i++) {
      const numStr: string = pageParts[i].split('.')[0].split('-')[0];
      const num: number = parseInt(numStr, 10);
      if (!isNaN(num) && num > maxPage) {
        maxPage = num;
      }
    }

    const result: HtSearchResult = {
      comics: comics,
      currentPage: currentPage,
      maxPage: maxPage,
      totalCount: comics.length
    };
    return result;
  }

  private static parseDetailPage(html: string, id: string): Comic {
    const comic: Comic = new Comic();
    comic.id = id;
    comic.source = 'htcomic';

    comic.title = HtcomicApi.cleanHtml(HtcomicApi.extractBetween(html, '<h2>', '</h2>'));
    if (comic.title === '') {
      comic.title = HtcomicApi.cleanHtml(HtcomicApi.extractBetween(html, 'class="page-title"', '</h1>'));
    }

    const cover: string = HtcomicApi.extractAttribute(html, 'property="og:image"');
    comic.coverUrl = cover !== '' ? cover : HtcomicApi.resolveUrl(HtcomicApi.extractAttribute(html, 'class="photo-pic" src'));

    comic.author = HtcomicApi.cleanHtml(HtcomicApi.extractBetween(html, 'class="author"', '</a>'));

    const pagesStr: string = HtcomicApi.extractBetween(html, 'class="info">共', '页');
    comic.pagesCount = parseInt(pagesStr, 10);

    comic.description = HtcomicApi.cleanHtml(HtcomicApi.extractBetween(html, 'class="desc"', '</div>'));

    const tags: string[] = [];
    const tagSection: string = HtcomicApi.extractBetween(html, 'class="tag-', '</div>');
    const tagParts: string[] = tagSection.split('<a');
    for (let i: number = 1; i < tagParts.length; i++) {
      const tag: string = HtcomicApi.cleanHtml(HtcomicApi.extractBetween(tagParts[i], '>', '</a>'));
      if (tag !== '') {
        tags.push(tag);
      }
    }
    comic.tags = tags;

    const updateTimeStr: string = HtcomicApi.extractBetween(html, 'class="date">', '</div>');
    comic.time = HtcomicApi.cleanHtml(updateTimeStr);

    return comic;
  }

  private static resolveUrl(path: string): string {
    if (path === '') {
      return '';
    }
    if (path.indexOf('http') === 0) {
      return path;
    }
    if (path.startsWith('//')) {
      return `https:${path}`;
    }
    if (path.startsWith('/')) {
      return `${HtcomicApi.baseUrl}${path}`;
    }
    return `${HtcomicApi.baseUrl}/${path}`;
  }

  private static extractHref(text: string, pattern: string): string {
    const idx: number = text.indexOf(pattern);
    if (idx === -1) {
      return '';
    }
    const start: number = text.lastIndexOf('"', idx);
    const end: number = text.indexOf('"', idx + pattern.length);
    if (start === -1 || end === -1) {
      return '';
    }
    return text.substring(start + 1, end);
  }

  private static extractBetween(text: string, start: string, end: string): string {
    const startIdx: number = text.indexOf(start);
    if (startIdx === -1) {
      return '';
    }
    const contentStart: number = startIdx + start.length;
    const endIdx: number = text.indexOf(end, contentStart);
    if (endIdx === -1) {
      return '';
    }
    return text.substring(contentStart, endIdx);
  }

  private static extractAttribute(text: string, pattern: string): string {
    const fullPattern: string = `${pattern}="`;
    const idx: number = text.indexOf(fullPattern);
    if (idx === -1) {
      return '';
    }
    const valStart: number = idx + fullPattern.length;
    const endIdx: number = text.indexOf('"', valStart);
    if (endIdx === -1) {
      return '';
    }
    return text.substring(valStart, endIdx);
  }

  private static cleanHtml(text: string): string {
    let result: string = text;
    result = result.replace(/<[^>]+>/g, '');
    result = result.replace(/&amp;/g, '&');
    result = result.replace(/&lt;/g, '<');
    result = result.replace(/&gt;/g, '>');
    result = result.replace(/&quot;/g, '"');
    result = result.replace(/&#39;/g, "'");
    result = result.replace(/&#\d+;/g, '');
    return result.trim();
  }

  private static base64Decode(encoded: string): string {
    const chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    let result: string = '';
    let buffer: number = 0;
    let bits: number = 0;
    for (let i: number = 0; i < encoded.length; i++) {
      const c: string = encoded.charAt(i);
      if (c === '=' || c === '\n' || c === '\r') {
        continue;
      }
      const val: number = chars.indexOf(c);
      if (val === -1) {
        continue;
      }
      buffer = (buffer << 6) | val;
      bits = bits + 6;
      if (bits >= 8) {
        bits = bits - 8;
        const byte: number = (buffer >> bits) & 0xFF;
        result = result + String.fromCharCode(byte);
      }
    }
    return result;
  }
}
