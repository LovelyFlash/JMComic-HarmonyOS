if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface NhHome_Params {
    isDarkMode?: boolean;
    comics?: Comic[];
    loading?: boolean;
    error?: string;
    page?: number;
}
import router from "@ohos:router";
import { Comic } from "@bundle:com.picacomic.harmony/entry/ets/data/model/Comic";
import type { ComicBrief } from "@bundle:com.picacomic.harmony/entry/ets/data/model/Comic";
import { NhentaiApi } from "@bundle:com.picacomic.harmony/entry/ets/data/api/NhentaiApi";
class NhHome extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.__comics = new ObservedPropertyObjectPU([], this, "comics");
        this.__loading = new ObservedPropertySimplePU(true, this, "loading");
        this.__error = new ObservedPropertySimplePU('', this, "error");
        this.__page = new ObservedPropertySimplePU(1, this, "page");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: NhHome_Params) {
        if (params.comics !== undefined) {
            this.comics = params.comics;
        }
        if (params.loading !== undefined) {
            this.loading = params.loading;
        }
        if (params.error !== undefined) {
            this.error = params.error;
        }
        if (params.page !== undefined) {
            this.page = params.page;
        }
    }
    updateStateVars(params: NhHome_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
        this.__comics.purgeDependencyOnElmtId(rmElmtId);
        this.__loading.purgeDependencyOnElmtId(rmElmtId);
        this.__error.purgeDependencyOnElmtId(rmElmtId);
        this.__page.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__isDarkMode.aboutToBeDeleted();
        this.__comics.aboutToBeDeleted();
        this.__loading.aboutToBeDeleted();
        this.__error.aboutToBeDeleted();
        this.__page.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __isDarkMode: ObservedPropertyAbstractPU<boolean>;
    get isDarkMode() {
        return this.__isDarkMode.get();
    }
    set isDarkMode(newValue: boolean) {
        this.__isDarkMode.set(newValue);
    }
    private __comics: ObservedPropertyObjectPU<Comic[]>;
    get comics() {
        return this.__comics.get();
    }
    set comics(newValue: Comic[]) {
        this.__comics.set(newValue);
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
    private __page: ObservedPropertySimplePU<number>;
    get page() {
        return this.__page.get();
    }
    set page(newValue: number) {
        this.__page.set(newValue);
    }
    aboutToAppear(): void { this.loadData(); }
    async loadData(): Promise<void> {
        this.loading = true;
        this.error = '';
        try {
            const result = await NhentaiApi.getHomePage(this.page);
            this.comics = result.comics.map((b: ComicBrief) => { const c = new Comic(); c.id = b.id; c.title = b.title; c.coverUrl = b.cover; c.source = 'nhentai'; return c; });
        }
        catch (e) {
            this.error = String(e);
        }
        this.loading = false;
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 8 });
            Column.debugLine("entry/src/main/ets/pages/nhentai/NhHome.ets(30:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/nhentai/NhHome.ets(31:7)", "entry");
            Row.width('100%');
            Row.height(64);
            Row.padding({ left: 16, right: 16 });
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 0, "type": 30000, params: ['icons/ic_back.svg'], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Image.debugLine("entry/src/main/ets/pages/nhentai/NhHome.ets(32:9)", "entry");
            Image.width(24);
            Image.height(24);
            Image.objectFit(ImageFit.Contain);
            Image.onClick(() => { router.back(); });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('NHentai');
            Text.debugLine("entry/src/main/ets/pages/nhentai/NhHome.ets(34:9)", "entry");
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF');
            Text.margin({ left: 12 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/nhentai/NhHome.ets(36:9)", "entry");
        }, Blank);
        Blank.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.loading) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 8 });
                        Column.debugLine("entry/src/main/ets/pages/nhentai/NhHome.ets(40:9)", "entry");
                        Column.layoutWeight(1);
                        Column.justifyContent(FlexAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        LoadingProgress.create();
                        LoadingProgress.debugLine("entry/src/main/ets/pages/nhentai/NhHome.ets(40:32)", "entry");
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
                        Column.debugLine("entry/src/main/ets/pages/nhentai/NhHome.ets(42:9)", "entry");
                        Column.layoutWeight(1);
                        Column.justifyContent(FlexAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.error);
                        Text.debugLine("entry/src/main/ets/pages/nhentai/NhHome.ets(42:32)", "entry");
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
                        Grid.create();
                        Grid.debugLine("entry/src/main/ets/pages/nhentai/NhHome.ets(44:9)", "entry");
                        Grid.columnsTemplate('1fr 1fr 1fr');
                        Grid.columnsGap(8);
                        Grid.rowsGap(10);
                        Grid.width('100%');
                        Grid.padding(12);
                        Grid.layoutWeight(1);
                    }, Grid);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const comic = _item;
                            {
                                const itemCreation2 = (elmtId, isInitialRender) => {
                                    GridItem.create(() => { }, false);
                                    GridItem.debugLine("entry/src/main/ets/pages/nhentai/NhHome.ets(46:13)", "entry");
                                };
                                const observedDeepRender = () => {
                                    this.observeComponentCreation2(itemCreation2, GridItem);
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Column.create({ space: 8 });
                                        Column.debugLine("entry/src/main/ets/pages/nhentai/NhHome.ets(47:15)", "entry");
                                        Column.width('100%');
                                        Column.padding(6);
                                        Column.backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF');
                                        Column.borderRadius(8);
                                        Column.shadow({ radius: 8, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.08)', offsetX: 0, offsetY: 2 });
                                        Column.onClick(() => { router.pushUrl({ url: 'pages/ComicDetailPage', params: { comicId: comic.id, title: comic.title, source: 'nhentai' } }); });
                                    }, Column);
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Image.create(comic.coverUrl);
                                        Image.debugLine("entry/src/main/ets/pages/nhentai/NhHome.ets(48:17)", "entry");
                                        Image.width('100%');
                                        Image.height(180);
                                        Image.objectFit(ImageFit.Cover);
                                        Image.borderRadius(6);
                                        Image.backgroundColor('#F0F0F0');
                                    }, Image);
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Text.create(comic.title);
                                        Text.debugLine("entry/src/main/ets/pages/nhentai/NhHome.ets(49:17)", "entry");
                                        Text.fontSize(12);
                                        Text.fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF');
                                        Text.maxLines(2);
                                        Text.textOverflow({ overflow: TextOverflow.Ellipsis });
                                        Text.width('100%');
                                        Text.margin({ top: 6 });
                                    }, Text);
                                    Text.pop();
                                    Column.pop();
                                    GridItem.pop();
                                };
                                observedDeepRender();
                            }
                        };
                        this.forEachUpdateFunction(elmtId, this.comics, forEachItemGenFunction);
                    }, ForEach);
                    ForEach.pop();
                    Grid.pop();
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
        return "NhHome";
    }
}
registerNamedRoute(() => new NhHome(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/nhentai/NhHome", pageFullPath: "entry/src/main/ets/pages/nhentai/NhHome", integratedHsp: "false", moduleType: "followWithHap" });
