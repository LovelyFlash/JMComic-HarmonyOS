// data/api/EhentaiApi.ets - E-Hentai / ExHentai API 客户端
import { Network } from '../../common/Network';
import { Logger } from '../../common/Logger';
import { Comic, ComicBrief } from '../model/Comic';
import { ApiConstants } from '../../common/Constants';
import { Settings } from '../preferences/Settings';

const TAG = 'EhentaiApi';

interface EhSearchResult {
  comics: ComicBrief[];
  currentPage: number;
  maxPage: number;
  totalCount: number;
}

export class EhentaiApi {
  private static async getBaseUrl(): Promise<string> {
    const useEx: boolean = await Settings.getBool('0', false);
    if (useEx) {
      return ApiConstants.EXHENTAI_BASE;
    }
    return ApiConstants.EHENTAI_BASE;
  }

  static async getGalleries(page: number, category: string = ''): Promise<EhSearchResult> {
    const base: string = await EhentaiApi.getBaseUrl();
    let url: string = `${base}/?page=${page}`;
    if (category !== '') {
      url = url + `&f_cats=${category}`;
    }
    Logger.info(TAG, `getGalleries: page=${page}`);
    const body: string = await Network.get(url);
    return EhentaiApi.parseGalleryList(body, page);
  }

  static async search(keyword: string, page: number): Promise<EhSearchResult> {
    const base: string = await EhentaiApi.getBaseUrl();
    const url: string = `${base}/?page=${page}&f_search=${encodeURIComponent(keyword)}&f_srch=1`;
    Logger.info(TAG, `search: keyword=${keyword}, page=${page}`);
    const body: string = await Network.get(url);
    return EhentaiApi.parseGalleryList(body, page);
  }

  static async getComicInfo(id: string): Promise<Comic> {
    const base: string = await EhentaiApi.getBaseUrl();
    const parts: string[] = id.split('-');
    const gid: string = parts[0];
    const token: string = parts.length > 1 ? parts[1] : '';
    const url: string = `${base}/g/${gid}/${token}`;
    Logger.info(TAG, `getComicInfo: id=${id}`);
    const body: string = await Network.get(url);
    return EhentaiApi.parseGalleryPage(body, gid, token);
  }

  static async getImages(id: string): Promise<string[]> {
    const base: string = await EhentaiApi.getBaseUrl();
    const parts: string[] = id.split('-');
    const gid: string = parts[0];
    const token: string = parts.length > 1 ? parts[1] : '';
    const url: string = `${base}/g/${gid}/${token}`;
    Logger.info(TAG, `getImages: id=${id}`);
    const body: string = await Network.get(url);
    return EhentaiApi.parseImageUrls(body);
  }

  private static parseGalleryList(html: string, currentPage: number): EhSearchResult {
    const comics: ComicBrief[] = [];
    const rows: string[] = html.split('class="gl1t"');
    for (let i: number = 1; i < rows.length; i++) {
      const row: string = rows[i];
      const comic: ComicBrief = new ComicBrief();
      const href: string = EhentaiApi.extractHref(row, '/g/');
      if (href === '') {
        continue;
      }
      const idParts: string[] = href.replace('/g/', '').split('/');
      comic.id = `${idParts[0]}-${idParts[1]}`;
      comic.title = EhentaiApi.extractBetween(row, 'class="glink">', '</div>');
      comic.cover = EhentaiApi.extractAttribute(row, 'data-src');
      if (comic.cover === '') {
        comic.cover = EhentaiApi.extractAttribute(row, 'src');
      }
      comic.author = EhentaiApi.extractUploader(row);
      comic.source = 'ehentai';
      const pagesStr: string = EhentaiApi.extractBetween(row, 'class="pages">', ' pages');
      comic.pages = parseInt(pagesStr, 10);
      comics.push(comic);
    }

    let maxPage: number = 1;
    const navMatch: string = EhentaiApi.extractBetween(html, 'id="ujump"', '</div>');
    const pageNums: number[] = [];
    const pageParts: string[] = navMatch.split('page=');
    for (let i: number = 1; i < pageParts.length; i++) {
      const numStr: string = pageParts[i].split('&')[0].split('"')[0];
      const num: number = parseInt(numStr, 10);
      if (!isNaN(num)) {
        pageNums.push(num);
      }
    }
    if (pageNums.length > 0) {
      let largest: number = 0;
      for (let i: number = 0; i < pageNums.length; i++) {
        if (pageNums[i] > largest) {
          largest = pageNums[i];
        }
      }
      maxPage = largest + 1;
    }

    const result: EhSearchResult = {
      comics: comics,
      currentPage: currentPage,
      maxPage: maxPage,
      totalCount: comics.length
    };
    return result;
  }

  private static parseGalleryPage(html: string, gid: string, token: string): Comic {
    const comic: Comic = new Comic();
    comic.id = `${gid}-${token}`;
    comic.source = 'ehentai';
    comic.title = EhentaiApi.extractBetween(html, '<h1 id="gn">', '</h1>');
    comic.author = EhentaiApi.extractBetween(html, '<span id="upowner">', '</span>');
    comic.description = EhentaiApi.extractBetween(html, '<div id="ld">', '</div>');
    comic.coverUrl = EhentaiApi.extractAttribute(html, 'id="imgsrc"');
    if (comic.coverUrl === '') {
      comic.coverUrl = EhentaiApi.extractBetween(html, "var imagelogo = '", "'");
    }

    const ratingStr: string = EhentaiApi.extractBetween(html, 'id="rating"', '/10');
    comic.stars = parseFloat(ratingStr);

    const pagesStr: string = EhentaiApi.extractBetween(html, 'Length:</td><td>', ' pages');
    comic.pagesCount = parseInt(pagesStr, 10);

    const tags: string[] = [];
    const tagSection: string = EhentaiApi.extractBetween(html, 'id="taglist"', '</div>');
    const tagParts: string[] = tagSection.split('id="tag_');
    for (let i: number = 1; i < tagParts.length; i++) {
      const tag: string = EhentaiApi.extractBetween(tagParts[i], '>', '<');
      if (tag !== '') {
        tags.push(tag);
      }
    }
    comic.tags = tags;

    comic.uploader = EhentaiApi.extractBetween(html, '<span id="uploader">', '</span>');
    comic.type = EhentaiApi.extractBetween(html, 'id="c_">', '</a>');

    return comic;
  }

  private static parseImageUrls(html: string): string[] {
    const urls: string[] = [];
    const parts: string[] = html.split('class="mi2"');
    for (let i: number = 1; i < parts.length; i++) {
      const imgTag: string = EhentaiApi.extractBetween(parts[i], '<img', '/>');
      if (imgTag === '') {
        continue;
      }
      const src: string = EhentaiApi.extractAttribute(imgTag, 'src');
      if (src !== '') {
        urls.push(src);
      }
    }

    if (urls.length === 0) {
      const thumbParts: string[] = html.split('data-src="');
      for (let i: number = 1; i < thumbParts.length; i++) {
        const endIdx: number = thumbParts[i].indexOf('"');
        if (endIdx !== -1) {
          urls.push(thumbParts[i].substring(0, endIdx));
        }
      }
    }

    return urls;
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

  private static extractUploader(text: string): string {
    return EhentaiApi.extractBetween(text, 'class="u">', '</a>');
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

  private static extractAttribute(text: string, attr: string): string {
    const pattern: string = `${attr}="`;
    const startIdx: number = text.indexOf(pattern);
    if (startIdx === -1) {
      return '';
    }
    const valStart: number = startIdx + pattern.length;
    const endIdx: number = text.indexOf('"', valStart);
    if (endIdx === -1) {
      return '';
    }
    return text.substring(valStart, endIdx);
  }
}
