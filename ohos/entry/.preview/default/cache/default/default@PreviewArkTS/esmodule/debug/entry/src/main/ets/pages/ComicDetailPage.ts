if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ComicDetailPage_Params {
    comicId?: string;
    title?: string;
    source?: string;
    comic?: Comic;
    loading?: boolean;
    error?: string;
    chapterImages?: string[];
    isFavorite?: boolean;
    isDarkMode?: boolean;
}
import router from "@ohos:router";
import { Comic } from "@bundle:com.picacomic.harmony/entry/ets/data/model/Comic";
import { Database } from "@bundle:com.picacomic.harmony/entry/ets/data/database/Database";
import { NhentaiApi } from "@bundle:com.picacomic.harmony/entry/ets/data/api/NhentaiApi";
import { JmApi } from "@bundle:com.picacomic.harmony/entry/ets/data/api/JmApi";
import { HtcomicApi } from "@bundle:com.picacomic.harmony/entry/ets/data/api/HtcomicApi";
import { EhentaiApi } from "@bundle:com.picacomic.harmony/entry/ets/data/api/EhentaiApi";
import { PicacgApi } from "@bundle:com.picacomic.harmony/entry/ets/data/api/PicacgApi";
import { HitomiApi } from "@bundle:com.picacomic.harmony/entry/ets/data/api/HitomiApi";
class ComicDetailPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__comicId = new ObservedPropertySimplePU('', this, "comicId");
        this.__title = new ObservedPropertySimplePU('', this, "title");
        this.__source = new ObservedPropertySimplePU('', this, "source");
        this.__comic = new ObservedPropertyObjectPU(new Comic(), this, "comic");
        this.__loading = new ObservedPropertySimplePU(true, this, "loading");
        this.__error = new ObservedPropertySimplePU('', this, "error");
        this.__chapterImages = new ObservedPropertyObjectPU([], this, "chapterImages");
        this.__isFavorite = new ObservedPropertySimplePU(false, this, "isFavorite");
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ComicDetailPage_Params) {
        if (params.comicId !== undefined) {
            this.comicId = params.comicId;
        }
        if (params.title !== undefined) {
            this.title = params.title;
        }
        if (params.source !== undefined) {
            this.source = params.source;
        }
        if (params.comic !== undefined) {
            this.comic = params.comic;
        }
        if (params.loading !== undefined) {
            this.loading = params.loading;
        }
        if (params.error !== undefined) {
            this.error = params.error;
        }
        if (params.chapterImages !== undefined) {
            this.chapterImages = params.chapterImages;
        }
        if (params.isFavorite !== undefined) {
            this.isFavorite = params.isFavorite;
        }
    }
    updateStateVars(params: ComicDetailPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__comicId.purgeDependencyOnElmtId(rmElmtId);
        this.__title.purgeDependencyOnElmtId(rmElmtId);
        this.__source.purgeDependencyOnElmtId(rmElmtId);
        this.__comic.purgeDependencyOnElmtId(rmElmtId);
        this.__loading.purgeDependencyOnElmtId(rmElmtId);
        this.__error.purgeDependencyOnElmtId(rmElmtId);
        this.__chapterImages.purgeDependencyOnElmtId(rmElmtId);
        this.__isFavorite.purgeDependencyOnElmtId(rmElmtId);
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__comicId.aboutToBeDeleted();
        this.__title.aboutToBeDeleted();
        this.__source.aboutToBeDeleted();
        this.__comic.aboutToBeDeleted();
        this.__loading.aboutToBeDeleted();
        this.__error.aboutToBeDeleted();
        this.__chapterImages.aboutToBeDeleted();
        this.__isFavorite.aboutToBeDeleted();
        this.__isDarkMode.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __comicId: ObservedPropertySimplePU<string>;
    get comicId() {
        return this.__comicId.get();
    }
    set comicId(newValue: string) {
        this.__comicId.set(newValue);
    }
    private __title: ObservedPropertySimplePU<string>;
    get title() {
        return this.__title.get();
    }
    set title(newValue: string) {
        this.__title.set(newValue);
    }
    private __source: ObservedPropertySimplePU<string>;
    get source() {
        return this.__source.get();
    }
    set source(newValue: string) {
        this.__source.set(newValue);
    }
    private __comic: ObservedPropertyObjectPU<Comic>;
    get comic() {
        return this.__comic.get();
    }
    set comic(newValue: Comic) {
        this.__comic.set(newValue);
    }
    private __loading: ObservedPropertySimplePU<boolean>;
    get loading() {
        return this.__loading.get();
    }
    set loading(newValue: boolean) {
        this.__loading.set(newValue);
    }
    private __error: ObservedPropertySimplePU<string>;
    get error() {
        return this.__error.get();
    }
    set error(newValue: string) {
        this.__error.set(newValue);
    }
    private __chapterImages: ObservedPropertyObjectPU<string[]>;
    get chapterImages() {
        return this.__chapterImages.get();
    }
    set chapterImages(newValue: string[]) {
        this.__chapterImages.set(newValue);
    }
    private __isFavorite: ObservedPropertySimplePU<boolean>;
    get isFavorite() {
        return this.__isFavorite.get();
    }
    set isFavorite(newValue: boolean) {
        this.__isFavorite.set(newValue);
    }
    private __isDarkMode: ObservedPropertyAbstractPU<boolean>;
    get isDarkMode() {
        return this.__isDarkMode.get();
    }
    set isDarkMode(newValue: boolean) {
        this.__isDarkMode.set(newValue);
    }
    aboutToAppear(): void {
        const params = router.getParams() as Record<string, string>;
        if (params !== null && params !== undefined) {
            this.comicId = params['comicId'] ?? '';
            this.title = params['title'] ?? '';
            this.source = params['source'] ?? '';
        }
        this.loadDetail();
        this.checkFavorite();
    }
    async loadDetail(): Promise<void> {
        this.loading = true;
        try {
            switch (this.source) {
                case 'nhentai':
                    this.comic = await NhentaiApi.getComicInfo(this.comicId);
                    break;
                case 'jm':
                    this.comic = await JmApi.getComicInfo(this.comicId);
                    break;
                case 'ehentai':
                    this.comic = await EhentaiApi.getComicInfo(this.comicId);
                    break;
                case 'picacg':
                    this.comic = await PicacgApi.getComicInfo(this.comicId);
                    break;
                case 'hitomi':
                    this.comic = await HitomiApi.getComicInfo(this.comicId);
                    break;
                case 'htcomic':
                    this.comic = await HtcomicApi.getComicInfo(this.comicId);
                    break;
            }
            this.title = this.comic.title;
        }
        catch (e) {
            this.error = String(e);
        }
        this.loading = false;
    }
    async checkFavorite(): Promise<void> {
        this.isFavorite = await Database.isFavorite(this.comicId, this.source);
    }
    async toggleFavorite(): Promise<void> {
        if (this.isFavorite) {
            await Database.removeFavorite(this.comicId, this.source);
        }
        else {
            await Database.insertFavorite(this.comicId, this.title, this.comic.coverUrl, this.source);
        }
        this.isFavorite = !this.isFavorite;
    }
    async loadImages(): Promise<void> {
        try {
            switch (this.source) {
                case 'nhentai':
                    this.chapterImages = await NhentaiApi.getImages(this.comicId);
                    break;
                case 'jm':
                    {
                        const ch = await JmApi.getChapter(this.comicId);
                        this.chapterImages = ch.imageUrls;
                    }
                    break;
                case 'htcomic':
                    this.chapterImages = await HtcomicApi.getImages(this.comicId);
                    break;
            }
            if (this.chapterImages.length > 0) {
                router.pushUrl({ url: 'pages/reader/ReaderPage', params: { comicId: this.comicId, images: this.chapterImages.join(','), source: this.source } });
            }
        }
        catch (e) {
            this.error = String(e);
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 8 });
            Column.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(80:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(81:7)", "entry");
            Row.width('100%');
            Row.height(64);
            Row.padding({ left: 16, right: 16 });
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 0, "type": 30000, params: ['icons/ic_back.svg'], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Image.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(82:9)", "entry");
            Image.width(24);
            Image.height(24);
            Image.objectFit(ImageFit.Contain);
            Image.onClick(() => { router.back(); });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.title);
            Text.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(83:9)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF');
            Text.layoutWeight(1);
            Text.margin({ left: 12 });
            Text.maxLines(1);
            Text.textOverflow({ overflow: TextOverflow.Ellipsis });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 0, "type": 30000, params: ['icons/ic_favorites.svg'], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Image.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(85:9)", "entry");
            Image.width(24);
            Image.height(24);
            Image.objectFit(ImageFit.Contain);
            Image.onClick(() => { this.toggleFavorite(); });
        }, Image);
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.loading) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 8 });
                        Column.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(89:27)", "entry");
                        Column.layoutWeight(1);
                        Column.justifyContent(FlexAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        LoadingProgress.create();
                        LoadingProgress.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(89:50)", "entry");
                        LoadingProgress.width(48);
                        LoadingProgress.height(48);
                    }, LoadingProgress);
                    Column.pop();
                });
            }
            else if (this.error.length > 0) {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 8 });
                        Column.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(90:41)", "entry");
                        Column.layoutWeight(1);
                        Column.justifyContent(FlexAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.error);
                        Text.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(90:64)", "entry");
                        Text.fontSize(14);
                        Text.fontColor('#FF3B30');
                    }, Text);
                    Text.pop();
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(2, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Scroll.create();
                        Scroll.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(92:9)", "entry");
                        Scroll.layoutWeight(1);
                    }, Scroll);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 8 });
                        Column.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(93:11)", "entry");
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // Cover + Info
                        Row.create();
                        Row.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(95:13)", "entry");
                        // Cover + Info
                        Row.width('100%');
                        // Cover + Info
                        Row.padding(16);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Image.create(this.comic.coverUrl);
                        Image.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(96:15)", "entry");
                        Image.width(130);
                        Image.height(180);
                        Image.objectFit(ImageFit.Cover);
                        Image.borderRadius(8);
                        Image.backgroundColor('#F0F0F0');
                    }, Image);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 8 });
                        Column.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(97:15)", "entry");
                        Column.layoutWeight(1);
                        Column.alignItems(HorizontalAlign.Start);
                        Column.margin({ left: 16 });
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.comic.title);
                        Text.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(98:17)", "entry");
                        Text.fontSize(18);
                        Text.fontWeight(FontWeight.Bold);
                        Text.fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF');
                        Text.maxLines(3);
                        Text.textOverflow({ overflow: TextOverflow.Ellipsis });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.comic.author.length > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('作者: ' + this.comic.author);
                                    Text.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(99:53)", "entry");
                                    Text.fontSize(13);
                                    Text.fontColor(this.isDarkMode ? '#8E8E93' : '#666666');
                                    Text.margin({ top: 8 });
                                }, Text);
                                Text.pop();
                            });
                        }
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        if (this.comic.likes > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create('❤ ' + this.comic.likes.toString());
                                    Text.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(100:45)", "entry");
                                    Text.fontSize(13);
                                    Text.fontColor('#FF3B30');
                                    Text.margin({ top: 4 });
                                }, Text);
                                Text.pop();
                            });
                        }
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.comic.source);
                        Text.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(101:17)", "entry");
                        Text.fontSize(12);
                        Text.fontColor(this.isDarkMode ? '#8E8E93' : '#666666');
                        Text.margin({ top: 4 });
                    }, Text);
                    Text.pop();
                    Column.pop();
                    // Cover + Info
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        // Description
                        if (this.comic.description.length > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Text.create(this.comic.description);
                                    Text.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(107:15)", "entry");
                                    Text.fontSize(14);
                                    Text.fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF');
                                    Text.width('100%');
                                    Text.padding({ left: 16, right: 16, bottom: 16 });
                                }, Text);
                                Text.pop();
                            });
                        }
                        // Tags
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        If.create();
                        // Tags
                        if (this.comic.tags.length > 0) {
                            this.ifElseBranchUpdateFunction(0, () => {
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    Flex.create({ wrap: FlexWrap.Wrap });
                                    Flex.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(112:15)", "entry");
                                    Flex.width('100%');
                                    Flex.padding({ left: 16, right: 16, bottom: 16 });
                                }, Flex);
                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                    ForEach.create();
                                    const forEachItemGenFunction = _item => {
                                        const tag = _item;
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create(tag);
                                            Text.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(114:19)", "entry");
                                            Text.fontSize(12);
                                            Text.fontColor(this.isDarkMode ? '#4DA6FF' : '#007AFF');
                                            Text.backgroundColor('#F0F8FF');
                                            Text.borderRadius(4);
                                            Text.padding({ left: 8, right: 8, top: 4, bottom: 4 });
                                            Text.margin({ right: 6, bottom: 6 });
                                        }, Text);
                                        Text.pop();
                                    };
                                    this.forEachUpdateFunction(elmtId, this.comic.tags, forEachItemGenFunction);
                                }, ForEach);
                                ForEach.pop();
                                Flex.pop();
                            });
                        }
                        // Read button
                        else {
                            this.ifElseBranchUpdateFunction(1, () => {
                            });
                        }
                    }, If);
                    If.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        // Read button
                        Button.createWithLabel('开始阅读');
                        Button.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(121:13)", "entry");
                        // Read button
                        Button.width('90%');
                        // Read button
                        Button.height(48);
                        // Read button
                        Button.fontSize(16);
                        // Read button
                        Button.fontColor('#FFFFFF');
                        // Read button
                        Button.backgroundColor(this.isDarkMode ? '#4DA6FF' : '#007AFF');
                        // Read button
                        Button.borderRadius(12);
                        // Read button
                        Button.margin({ top: 8, bottom: 24 });
                        // Read button
                        Button.onClick(() => { this.loadImages(); });
                    }, Button);
                    // Read button
                    Button.pop();
                    Column.pop();
                    Scroll.pop();
                });
            }
        }, If);
        If.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "ComicDetailPage";
    }
}
registerNamedRoute(() => new ComicDetailPage(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/ComicDetailPage", pageFullPath: "entry/src/main/ets/pages/ComicDetailPage", integratedHsp: "false", moduleType: "followWithHap" });
