import { Network } from "@bundle:com.picacomic.harmony/entry/ets/common/Network";
import { Logger } from "@bundle:com.picacomic.harmony/entry/ets/common/Logger";
import { Comic } from "@bundle:com.picacomic.harmony/entry/ets/data/model/Comic";
const TAG = 'HitomiApi';
export interface HitomiGalleryBlock {
    id: string;
    title: string;
    thumbUrl: string;
    language: string;
    artist: string;
    series: string;
    type: string;
}
export class HitomiApi {
    private static readonly BASE_URL: string = 'https://hitomi.la';
    private static readonly JS_URL: string = 'https://hitomi.la/galleries.js';
    private static readonly IMAGE_BASE: string = 'https://a.hitomi.la';
    static getComics(url: string): Promise<HitomiGalleryBlock[]> {
        Logger.info(TAG, `getComics: url=${url}`);
        return Network.get(url).then((body: string) => {
            return HitomiApi.parseGalleryBlocks(body);
        });
    }
    static getComicInfo(id: string): Promise<Comic> {
        const url = `${HitomiApi.BASE_URL}/${HitomiApi.getGalleryUrl(id)}`;
        Logger.info(TAG, `getComicInfo: id=${id}`);
        return Network.get(url).then((body: string) => {
            return HitomiApi.parseGalleryPage(body, id);
        });
    }
    private static parseGalleryBlocks(html: string): HitomiGalleryBlock[] {
        const results: HitomiGalleryBlock[] = [];
        const parts: string[] = html.split('<div class="gallery-content');
        for (let i: number = 1; i < parts.length; i++) {
            const block: HitomiGalleryBlock = {
                id: HitomiApi.extractBetween(parts[i], 'href="/galleries/', '.html'),
                title: HitomiApi.extractAttribute(parts[i], 'alt'),
                thumbUrl: HitomiApi.extractSrc(parts[i]),
                language: HitomiApi.extractLanguage(parts[i]),
                artist: HitomiApi.extractArtist(parts[i]),
                series: '',
                type: 'gallery'
            };
            if (block.id !== '') {
                results.push(block);
            }
        }
        return results;
    }
    private static parseGalleryPage(html: string, id: string): Comic {
        const comic: Comic = new Comic();
        comic.id = id;
        comic.source = 'hitomi';
        const titleMatch: string = HitomiApi.extractBetween(html, '<h1>', '</h1>');
        comic.title = HitomiApi.cleanHtml(titleMatch);
        const artistMatch: string = HitomiApi.extractBetween(html, '<h2 class="artist"', '</h2>');
        comic.author = HitomiApi.cleanHtml(artistMatch);
        const coverMatch: string = HitomiApi.extractAttribute(html, 'data-src');
        if (coverMatch !== '') {
            comic.coverUrl = HitomiApi.fixCoverUrl(coverMatch);
        }
        const tags: string[] = [];
        const tagSection: string = HitomiApi.extractBetween(html, 'Tags:', '</div>');
        const tagParts: string[] = tagSection.split('tag-');
        for (let i: number = 1; i < tagParts.length; i++) {
            const tag: string = HitomiApi.extractBetween(tagParts[i], '>', '<');
            if (tag !== '') {
                tags.push(tag);
            }
        }
        comic.tags = tags;
        const languageMatch: string = HitomiApi.extractBetween(html, '<td>Language', '</td>');
        comic.language = HitomiApi.cleanHtml(languageMatch);
        return comic;
    }
    static getImages(id: string): Promise<string[]> {
        const galleryUrl: string = `${HitomiApi.BASE_URL}/${HitomiApi.getGalleryUrl(id)}`;
        Logger.info(TAG, `getImages: id=${id}`);
        return Network.get(galleryUrl).then((body: string) => {
            return HitomiApi.parseImageUrls(body, id);
        });
    }
    private static parseImageUrls(html: string, id: string): string[] {
        const urls: string[] = [];
        const pattern: string = `data-src="`;
        let pos: number = html.indexOf(pattern);
        while (pos !== -1) {
            const start: number = pos + pattern.length;
            const end: number = html.indexOf('"', start);
            if (end !== -1) {
                const rawUrl: string = html.substring(start, end);
                if (rawUrl.indexOf('.webp') !== -1 || rawUrl.indexOf('.jpg') !== -1 || rawUrl.indexOf('.png') !== -1) {
                    const fullUrl: string = HitomiApi.fixCoverUrl(rawUrl);
                    urls.push(fullUrl);
                }
            }
            pos = html.indexOf(pattern, end);
        }
        return urls;
    }
    private static getGalleryUrl(id: string): string {
        const numId: number = Number(id);
        const b: number = numId % 10000 === 0 ? 1 : Math.floor(numId / 10000);
        const a: number = numId >= 10000 ? Math.floor(numId / 10000) : numId;
        return `galleries${String(b)}/${id}.html`;
    }
    private static fixCoverUrl(url: string): string {
        if (url.startsWith('//')) {
            return `https:${url}`;
        }
        if (url.startsWith('/')) {
            return `${HitomiApi.BASE_URL}${url}`;
        }
        return url;
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
    private static extractSrc(text: string): string {
        return HitomiApi.extractAttribute(text, 'src');
    }
    private static extractLanguage(text: string): string {
        const lang: string = HitomiApi.extractBetween(text, 'class="language-', '"');
        return lang;
    }
    private static extractArtist(text: string): string {
        return HitomiApi.extractBetween(text, 'class="artist"', '</a>');
    }
    private static cleanHtml(text: string): string {
        let result: string = text;
        result = result.replace(/<[^>]+>/g, '');
        result = result.replace(/&amp;/g, '&');
        result = result.replace(/&lt;/g, '<');
        result = result.replace(/&gt;/g, '>');
        result = result.replace(/&quot;/g, '"');
        result = result.replace(/&#39;/g, "'");
        return result.trim();
    }
}
