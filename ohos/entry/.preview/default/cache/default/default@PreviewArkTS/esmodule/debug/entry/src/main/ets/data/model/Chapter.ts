// data/model/Chapter.ets - 章节数据模型
export class Chapter {
    id: string = '';
    title: string = '';
    comicId: string = '';
    order: number = 0;
    pages: number = 0;
    imageUrls: string[] = [];
    isLocked: boolean = false;
    needsLogin: boolean = false;
}
