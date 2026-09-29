// data/model/ReaderParam.ets - 阅读器参数（对象引用传递，避免路由参数超长）
import { Chapter } from './Chapter';

export class ReaderParam {
  comicId: string = '';
  source: string = '';
  title: string = '';
  images: string[] = [];
  chapters: Chapter[] = [];
  currentChapterOrder: number = 0;

  constructor(comicId: string, source: string, title: string, images: string[],
    chapters: Chapter[], currentChapterOrder: number) {
    this.comicId = comicId;
    this.source = source;
    this.title = title;
    this.images = images;
    this.chapters = chapters;
    this.currentChapterOrder = currentChapterOrder;
  }
}
