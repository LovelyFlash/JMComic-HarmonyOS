// data/api/NhentaiApi.ets - NHentai API 客户端
import { Network } from '../../common/Network';
import { Logger } from '../../common/Logger';
import { Comic, ComicBrief } from '../model/Comic';

const TAG = 'NhentaiApi';

interface NhentaiPageResult {
  comics: ComicBrief[];
  totalCount: number;
  currentPage: number;
  maxPage: number;
}

interface NhentaiGallery {
  id: number;
  media_id: number;
  title: NhentaiTitle;
  images: NhentaiImages;
  scanlator: string;
  upload_date: number;
  tags: NhentaiTag[];
  num_pages: number;
  num_favorites: number;
}

interface NhentaiTitle {
  japanese: string;
  english: string;
  pretty: string;
}

interface NhentaiImages {
  pages: NhentaiImageSize[];
  cover: NhentaiImageSize;
  thumbnail: NhentaiImageSize;
}

interface NhentaiImageSize {
  width: number;
  height: number;
}

interface NhentaiTag {
  id: number;
  type: string;
  name: string;
  url: string;
  count: number;
}

interface NhentaiApiResponse {
  data: NhentaiGallery[];
  total_items: number;
  page: number;
  total_pages: number;
}

export class NhentaiApi {
  private static readonly BASE_URL: string = 'https://nhentai.net';
  private static readonly API_URL: string = 'https://nhentai.net/api/v2';
  private static readonly IMAGE_CDN: string = 'https://i3.nhentai.net';

  static getHomePage(page: number): Promise<NhentaiPageResult> {
    const url: string = `${NhentaiApi.API_URL}/galleries?page=${page}`;
    Logger.info(TAG, `getHomePage: page=${page}`);
    return Network.get(url).then((body: string) => {
      const resp: NhentaiApiResponse = JSON.parse(body) as NhentaiApiResponse;
      const items: NhentaiGallery[] = resp.data ?? [];
      const comics: ComicBrief[] = [];
      for (let i: number = 0; i < items.length; i++) {
        comics.push(NhentaiApi.galleryToBrief(items[i]));
      }
      const result: NhentaiPageResult = {
        comics: comics,
        totalCount: resp.total_items ?? 0,
        currentPage: resp.page ?? page,
        maxPage: resp.total_pages ?? 0
      };
      return result;
    });
  }

  static search(keyword: string, page: number): Promise<NhentaiPageResult> {
    const url: string = `${NhentaiApi.API_URL}/galleries?search=${encodeURIComponent(keyword)}&page=${page}`;
    Logger.info(TAG, `search: keyword=${keyword}, page=${page}`);
    return Network.get(url).then((body: string) => {
      const resp: NhentaiApiResponse = JSON.parse(body) as NhentaiApiResponse;
      const items: NhentaiGallery[] = resp.data ?? [];
      const comics: ComicBrief[] = [];
      for (let i: number = 0; i < items.length; i++) {
        comics.push(NhentaiApi.galleryToBrief(items[i]));
      }
      const result: NhentaiPageResult = {
        comics: comics,
        totalCount: resp.total_items ?? 0,
        currentPage: resp.page ?? page,
        maxPage: resp.total_pages ?? 0
      };
      return result;
    });
  }

  static getComicInfo(id: string): Promise<Comic> {
    const url: string = `${NhentaiApi.API_URL}/gallery/${id}`;
    Logger.info(TAG, `getComicInfo: id=${id}`);
    return Network.get(url).then((body: string) => {
      const resp: Record<string, NhentaiGallery> = JSON.parse(body) as Record<string, NhentaiGallery>;
      const gallery: NhentaiGallery = resp.data as NhentaiGallery;
      return NhentaiApi.galleryToComic(gallery);
    });
  }

  static getImages(id: string): Promise<string[]> {
    const url: string = `${NhentaiApi.API_URL}/gallery/${id}`;
    Logger.info(TAG, `getImages: id=${id}`);
    return Network.get(url).then((body: string) => {
      const resp: Record<string, NhentaiGallery> = JSON.parse(body) as Record<string, NhentaiGallery>;
      const gallery: NhentaiGallery = resp.data as NhentaiGallery;
      const mediaId: number = gallery.media_id;
      const imagePages: NhentaiImageSize[] = gallery.images.pages;
      const urls: string[] = [];
      for (let i: number = 0; i < imagePages.length; i++) {
        const ext: string = NhentaiApi.getPageExtension(imagePages[i]);
        const imgUrl: string = `${NhentaiApi.IMAGE_CDN}/galleries/${mediaId}/${i + 1}.${ext}`;
        urls.push(imgUrl);
      }
      return urls;
    });
  }

  private static galleryToBrief(gallery: NhentaiGallery): ComicBrief {
    const brief: ComicBrief = new ComicBrief();
    brief.id = String(gallery.id);
    brief.title = NhentaiApi.extractTitle(gallery.title);
    brief.cover = `${NhentaiApi.IMAGE_CDN}/galleries/${gallery.media_id}/${gallery.images.cover.width}x${gallery.images.cover.height}t.jpg`;
    brief.author = NhentaiApi.findTag(gallery.tags, 'artist');
    brief.pages = gallery.num_pages;
    brief.source = 'nhentai';
    brief.language = NhentaiApi.findTag(gallery.tags, 'language');
    brief.tags = [];
    for (let i: number = 0; i < gallery.tags.length; i++) {
      brief.tags.push(gallery.tags[i].name);
    }
    return brief;
  }

  private static galleryToComic(gallery: NhentaiGallery): Comic {
    const comic: Comic = new Comic();
    comic.id = String(gallery.id);
    comic.title = NhentaiApi.extractTitle(gallery.title);
    comic.coverUrl = `${NhentaiApi.IMAGE_CDN}/galleries/${gallery.media_id}/${gallery.images.cover.width}x${gallery.images.cover.height}l.jpg`;
    comic.author = NhentaiApi.findTag(gallery.tags, 'artist');
    comic.pagesCount = gallery.num_pages;
    comic.source = 'nhentai';
    comic.language = NhentaiApi.findTag(gallery.tags, 'language');
    comic.tags = [];
    for (let i: number = 0; i < gallery.tags.length; i++) {
      comic.tags.push(gallery.tags[i].name);
    }
    comic.updateTime = gallery.upload_date;
    comic.uploader = gallery.scanlator;
    return comic;
  }

  private static extractTitle(title: NhentaiTitle): string {
    if (title.pretty !== '') {
      return title.pretty;
    }
    if (title.english !== '') {
      return title.english;
    }
    return title.japanese;
  }

  private static findTag(tags: NhentaiTag[], type: string): string {
    for (let i: number = 0; i < tags.length; i++) {
      if (tags[i].type === type) {
        return tags[i].name;
      }
    }
    return '';
  }

  private static getPageExtension(size: NhentaiImageSize): string {
    if (size.width === 950) {
      return 'p';
    }
    return 'j';
  }
}
