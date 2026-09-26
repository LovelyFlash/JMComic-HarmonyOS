// data/model/Comic.ets - 漫画数据模型
export class Comic {
  id: string = '';
  title: string = '';
  subTitle: string = '';
  author: string = '';
  coverUrl: string = '';
  description: string = '';
  categories: string[] = [];
  tags: string[] = [];
  likes: number = 0;
  comments: number = 0;
  isFavorite: boolean = false;
  isLiked: boolean = false;
  source: string = '';
  page: number = 0;
  language: string = '';
  updateTime: number = 0;
  chapterCount: number = 0;
  pagesCount: number = 0;
  uploader: string = '';
  stars: number = 0;
  type: string = '';
  time: string = '';
  enableTagsTranslation: boolean = false;
}

export class ComicBrief {
  id: string = '';
  title: string = '';
  subTitle: string = '';
  cover: string = '';
  author: string = '';
  tags: string[] = [];
  pages: number = 0;
  language: string = '';
  source: string = '';
}
