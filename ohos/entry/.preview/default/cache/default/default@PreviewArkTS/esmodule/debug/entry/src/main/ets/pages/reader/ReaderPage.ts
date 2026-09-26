if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ReaderPage_Params {
    comicId?: string;
    images?: string[];
    currentIndex?: number;
    showToolbar?: boolean;
    isDarkMode?: boolean;
}
import router from "@ohos:router";
import { Logger } from "@bundle:com.picacomic.harmony/entry/ets/common/Logger";
class ReaderPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__comicId = new ObservedPropertySimplePU('', this, "comicId");
        this.__images = new ObservedPropertyObjectPU([], this, "images");
        this.__currentIndex = new ObservedPropertySimplePU(0, this, "currentIndex");
        this.__showToolbar = new ObservedPropertySimplePU(false, this, "showToolbar");
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ReaderPage_Params) {
        if (params.comicId !== undefined) {
            this.comicId = params.comicId;
        }
        if (params.images !== undefined) {
            this.images = params.images;
        }
        if (params.currentIndex !== undefined) {
            this.currentIndex = params.currentIndex;
        }
        if (params.showToolbar !== undefined) {
            this.showToolbar = params.showToolbar;
        }
    }
    updateStateVars(params: ReaderPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__comicId.purgeDependencyOnElmtId(rmElmtId);
        this.__images.purgeDependencyOnElmtId(rmElmtId);
        this.__currentIndex.purgeDependencyOnElmtId(rmElmtId);
        this.__showToolbar.purgeDependencyOnElmtId(rmElmtId);
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__comicId.aboutToBeDeleted();
        this.__images.aboutToBeDeleted();
        this.__currentIndex.aboutToBeDeleted();
        this.__showToolbar.aboutToBeDeleted();
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
    private __images: ObservedPropertyObjectPU<string[]>;
    get images() {
        return this.__images.get();
    }
    set images(newValue: string[]) {
        this.__images.set(newValue);
    }
    private __currentIndex: ObservedPropertySimplePU<number>;
    get currentIndex() {
        return this.__currentIndex.get();
    }
    set currentIndex(newValue: number) {
        this.__currentIndex.set(newValue);
    }
    private __showToolbar: ObservedPropertySimplePU<boolean>;
    get showToolbar() {
        return this.__showToolbar.get();
    }
    set showToolbar(newValue: boolean) {
        this.__showToolbar.set(newValue);
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
            const imagesStr = params['images'] ?? '';
            if (imagesStr.length > 0) {
                this.images = imagesStr.split(',');
            }
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Stack.create();
            Stack.debugLine("entry/src/main/ets/pages/reader/ReaderPage.ets(27:5)", "entry");
            Stack.width('100%');
            Stack.height('100%');
            Stack.backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF');
            Stack.onClick(() => { this.showToolbar = !this.showToolbar; });
        }, Stack);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Image swiper
            Swiper.create();
            Swiper.debugLine("entry/src/main/ets/pages/reader/ReaderPage.ets(29:7)", "entry");
            // Image swiper
            Swiper.index(this.currentIndex);
            // Image swiper
            Swiper.indicator(false);
            // Image swiper
            Swiper.onChange((index: number) => { this.currentIndex = index; });
            // Image swiper
            Swiper.width('100%');
            // Image swiper
            Swiper.height('100%');
        }, Swiper);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const url = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    If.create();
                    if (url.length > 0) {
                        this.ifElseBranchUpdateFunction(0, () => {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Image.create(url);
                                Image.debugLine("entry/src/main/ets/pages/reader/ReaderPage.ets(32:13)", "entry");
                                Image.width('100%');
                                Image.height('100%');
                                Image.objectFit(ImageFit.Contain);
                                Image.backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF');
                                Image.onError(() => { Logger.debug('ReaderPage', `Image load failed: ${url}`); });
                            }, Image);
                        });
                    }
                    else {
                        this.ifElseBranchUpdateFunction(1, () => {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Column.create({ space: 8 });
                                Column.debugLine("entry/src/main/ets/pages/reader/ReaderPage.ets(38:13)", "entry");
                                Column.width('100%');
                                Column.height('100%');
                                Column.justifyContent(FlexAlign.Center);
                                Column.backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF');
                            }, Column);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create('...');
                                Text.debugLine("entry/src/main/ets/pages/reader/ReaderPage.ets(38:36)", "entry");
                                Text.fontSize(16);
                                Text.fontColor('#FFFFFF');
                            }, Text);
                            Text.pop();
                            Column.pop();
                        });
                    }
                }, If);
                If.pop();
            };
            this.forEachUpdateFunction(elmtId, this.images, forEachItemGenFunction);
        }, ForEach);
        ForEach.pop();
        // Image swiper
        Swiper.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // Toolbar overlay
            if (this.showToolbar) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 8 });
                        Column.debugLine("entry/src/main/ets/pages/reader/ReaderPage.ets(50:9)", "entry");
                        Column.width('100%');
                        Column.height('100%');
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("entry/src/main/ets/pages/reader/ReaderPage.ets(51:11)", "entry");
                        Row.width('100%');
                        Row.height(56);
                        Row.padding({ left: 16, right: 16 });
                        Row.backgroundColor('rgba(0,0,0,0.6)');
                        Row.alignItems(VerticalAlign.Center);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Image.create({ "id": 0, "type": 30000, params: ['icons/ic_back.svg'], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
                        Image.debugLine("entry/src/main/ets/pages/reader/ReaderPage.ets(52:13)", "entry");
                        Image.width(24);
                        Image.height(24);
                        Image.objectFit(ImageFit.Contain);
                        Image.onClick(() => { router.back(); });
                    }, Image);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`${this.currentIndex + 1} / ${this.images.length}`);
                        Text.debugLine("entry/src/main/ets/pages/reader/ReaderPage.ets(54:13)", "entry");
                        Text.fontSize(14);
                        Text.fontColor('#FFFFFF');
                        Text.layoutWeight(1);
                        Text.textAlign(TextAlign.Center);
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(' ');
                        Text.debugLine("entry/src/main/ets/pages/reader/ReaderPage.ets(55:13)", "entry");
                        Text.width(24);
                    }, Text);
                    Text.pop();
                    Row.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Blank.create();
                        Blank.debugLine("entry/src/main/ets/pages/reader/ReaderPage.ets(57:11)", "entry");
                        Blank.layoutWeight(1);
                    }, Blank);
                    Blank.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Row.create();
                        Row.debugLine("entry/src/main/ets/pages/reader/ReaderPage.ets(58:11)", "entry");
                        Row.width('100%');
                        Row.height(48);
                        Row.backgroundColor('rgba(0,0,0,0.6)');
                        Row.justifyContent(FlexAlign.Center);
                    }, Row);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(`${this.currentIndex + 1} / ${this.images.length}`);
                        Text.debugLine("entry/src/main/ets/pages/reader/ReaderPage.ets(58:19)", "entry");
                        Text.fontSize(14);
                        Text.fontColor('#FFFFFF');
                    }, Text);
                    Text.pop();
                    Row.pop();
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        Stack.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "ReaderPage";
    }
}
registerNamedRoute(() => new ReaderPage(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/reader/ReaderPage", pageFullPath: "entry/src/main/ets/pages/reader/ReaderPage", integratedHsp: "false", moduleType: "followWithHap" });
