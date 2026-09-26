// data/model/ComicPageData.ets - 漫画详情页数据
import { Comic } from './Comic';
import { Chapter } from './Chapter';
import { Comment } from './Comment';

export class ComicPageData {
  comic: Comic = new Comic();
  chapters: Chapter[] = [];
  comments: Comment[] = [];
  relatedComics: Comic[] = [];
}
