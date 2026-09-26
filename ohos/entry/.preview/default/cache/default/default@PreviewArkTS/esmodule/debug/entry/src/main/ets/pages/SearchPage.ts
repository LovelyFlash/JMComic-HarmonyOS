if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SearchPage_Params {
    keyword?: string;
    comics?: Comic[];
    loading?: boolean;
    error?: string;
    selectedSource?: number;
    isDarkMode?: boolean;
    sources?: string[];
}
import router from "@ohos:router";
import { Translations } from "@bundle:com.picacomic.harmony/entry/ets/common/Translations";
import { Comic } from "@bundle:com.picacomic.harmony/entry/ets/data/model/Comic";
import type { ComicBrief } from "@bundle:com.picacomic.harmony/entry/ets/data/model/Comic";
import { NhentaiApi } from "@bundle:com.picacomic.harmony/entry/ets/data/api/NhentaiApi";
import { JmApi } from "@bundle:com.picacomic.harmony/entry/ets/data/api/JmApi";
import { HtcomicApi } from "@bundle:com.picacomic.harmony/entry/ets/data/api/HtcomicApi";
class SearchPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__keyword = new ObservedPropertySimplePU('', this, "keyword");
        this.__comics = new ObservedPropertyObjectPU([], this, "comics");
        this.__loading = new ObservedPropertySimplePU(false, this, "loading");
        this.__error = new ObservedPropertySimplePU('', this, "error");
        this.__selectedSource = new ObservedPropertySimplePU(0, this, "selectedSource");
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.sources = ['NHentai', 'JinMan', 'HT'];
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SearchPage_Params) {
        if (params.keyword !== undefined) {
            this.keyword = params.keyword;
        }
        if (params.comics !== undefined) {
            this.comics = params.comics;
        }
        if (params.loading !== undefined) {
            this.loading = params.loading;
        }
        if (params.error !== undefined) {
            this.error = params.error;
        }
        if (params.selectedSource !== undefined) {
            this.selectedSource = params.selectedSource;
        }
        if (params.sources !== undefined) {
            this.sources = params.sources;
        }
    }
    updateStateVars(params: SearchPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__keyword.purgeDependencyOnElmtId(rmElmtId);
        this.__comics.purgeDependencyOnElmtId(rmElmtId);
        this.__loading.purgeDependencyOnElmtId(rmElmtId);
        this.__error.purgeDependencyOnElmtId(rmElmtId);
        this.__selectedSource.purgeDependencyOnElmtId(rmElmtId);
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__keyword.aboutToBeDeleted();
        this.__comics.aboutToBeDeleted();
        this.__loading.aboutToBeDeleted();
        this.__error.aboutToBeDeleted();
        this.__selectedSource.aboutToBeDeleted();
        this.__isDarkMode.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __keyword: ObservedPropertySimplePU<string>;
    get keyword() {
        return this.__keyword.get();
    }
    set keyword(newValue: string) {
        this.__keyword.set(newValue);
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
    pageTransition() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            PageTransition.create();
        }, null);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            PageTransitionEnter.create({ duration: 250, curve: Curve.FastOutSlowIn });
        }, null);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            PageTransitionExit.create({ duration: 200, curve: Curve.FastOutSlowIn });
        }, null);
        PageTransition.pop();
    }
    private __error: ObservedPropertySimplePU<string>;
    get error() {
        return this.__error.get();
    }
    set error(newValue: string) {
        this.__error.set(newValue);
    }
    private __selectedSource: ObservedPropertySimplePU<number>;
    get selectedSource() {
        return this.__selectedSource.get();
    }
    set selectedSource(newValue: number) {
        this.__selectedSource.set(newValue);
    }
    private __isDarkMode: ObservedPropertyAbstractPU<boolean>;
    get isDarkMode() {
        return this.__isDarkMode.get();
    }
    set isDarkMode(newValue: boolean) {
        this.__isDarkMode.set(newValue);
    }
    private sources: string[];
    header(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/SearchPage.ets(28:5)", "entry");
            Row.width('100%');
            Row.height(64);
            Row.padding({ left: 16, right: 16 });
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 0, "type": 30000, params: ['icons/ic_back.svg'], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Image.debugLine("entry/src/main/ets/pages/SearchPage.ets(29:7)", "entry");
            Image.width(24);
            Image.height(24);
            Image.objectFit(ImageFit.Contain);
            Image.onClick(() => { router.back(); });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('search_hint'));
            Text.debugLine("entry/src/main/ets/pages/SearchPage.ets(31:7)", "entry");
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : '#000000');
            Text.margin({ left: 12 });
        }, Text);
        Text.pop();
        Row.pop();
    }
    sourceTabs(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create({ space: 8 });
            Row.debugLine("entry/src/main/ets/pages/SearchPage.ets(38:5)", "entry");
            Row.width('100%');
            Row.padding({ left: 16, right: 16, bottom: 8 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, idx: number) => {
                const src = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(src);
                    Text.debugLine("entry/src/main/ets/pages/SearchPage.ets(40:9)", "entry");
                    Text.fontSize(13);
                    Text.padding({ left: 12, right: 12, top: 6, bottom: 6 });
                    Text.borderRadius(16);
                    Text.fontColor(this.selectedSource === idx ? '#FFFFFF' : (this.isDarkMode ? '#999999' : '#666666'));
                    Text.backgroundColor(this.selectedSource === idx ? (this.isDarkMode ? '#4DA6FF' : '#007AFF') : 'transparent');
                    Text.onClick(() => { this.selectedSource = idx; });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, this.sources, forEachItemGenFunction, undefined, true, false);
        }, ForEach);
        ForEach.pop();
        Row.pop();
    }
    results(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.loading) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 8 });
                        Column.debugLine("entry/src/main/ets/pages/SearchPage.ets(52:7)", "entry");
                        Column.layoutWeight(1);
                        Column.justifyContent(FlexAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        LoadingProgress.create();
                        LoadingProgress.debugLine("entry/src/main/ets/pages/SearchPage.ets(52:30)", "entry");
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
                        Column.debugLine("entry/src/main/ets/pages/SearchPage.ets(54:7)", "entry");
                        Column.layoutWeight(1);
                        Column.justifyContent(FlexAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.error);
                        Text.debugLine("entry/src/main/ets/pages/SearchPage.ets(54:30)", "entry");
                        Text.fontSize(14);
                        Text.fontColor('#FF3B30');
                    }, Text);
                    Text.pop();
                    Column.pop();
                });
            }
            else if (this.comics.length === 0) {
                this.ifElseBranchUpdateFunction(2, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create({ space: 8 });
                        Column.debugLine("entry/src/main/ets/pages/SearchPage.ets(56:7)", "entry");
                        Column.layoutWeight(1);
                        Column.justifyContent(FlexAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(Translations.t('search_hint'));
                        Text.debugLine("entry/src/main/ets/pages/SearchPage.ets(56:30)", "entry");
                        Text.fontSize(14);
                        Text.fontColor(this.isDarkMode ? '#999999' : '#666666');
                    }, Text);
                    Text.pop();
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(3, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        List.create({ space: 1 });
                        List.debugLine("entry/src/main/ets/pages/SearchPage.ets(59:7)", "entry");
                        List.layoutWeight(1);
                        List.divider({ strokeWidth: 0.5, color: this.isDarkMode ? '#333333' : '#E5E5EA' });
                        List.edgeEffect(EdgeEffect.Spring);
                    }, List);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const comic = _item;
                            {
                                const itemCreation = (elmtId, isInitialRender) => {
                                    ViewStackProcessor.StartGetAccessRecordingFor(elmtId);
                                    ListItem.create(deepRenderFunction, true);
                                    if (!isInitialRender) {
                                        ListItem.pop();
                                    }
                                    ViewStackProcessor.StopGetAccessRecording();
                                };
                                const itemCreation2 = (elmtId, isInitialRender) => {
                                    ListItem.create(deepRenderFunction, true);
                                    ListItem.debugLine("entry/src/main/ets/pages/SearchPage.ets(61:11)", "entry");
                                };
                                const deepRenderFunction = (elmtId, isInitialRender) => {
                                    itemCreation(elmtId, isInitialRender);
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Row.create();
                                        Row.debugLine("entry/src/main/ets/pages/SearchPage.ets(62:13)", "entry");
                                        Row.width('100%');
                                        Row.padding(12);
                                        Row.onClick(() => {
                                            router.pushUrl({ url: 'pages/ComicDetailPage', params: { comicId: comic.id, title: comic.title, source: comic.source } });
                                        });
                                    }, Row);
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Image.create(comic.coverUrl);
                                        Image.debugLine("entry/src/main/ets/pages/SearchPage.ets(63:15)", "entry");
                                        Image.width(80);
                                        Image.height(110);
                                        Image.objectFit(ImageFit.Cover);
                                        Image.borderRadius(6);
                                        Image.backgroundColor(this.isDarkMode ? '#2C2C2E' : '#F0F0F0');
                                    }, Image);
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Column.create({ space: 8 });
                                        Column.debugLine("entry/src/main/ets/pages/SearchPage.ets(65:15)", "entry");
                                        Column.layoutWeight(1);
                                        Column.alignItems(HorizontalAlign.Start);
                                        Column.margin({ left: 12 });
                                    }, Column);
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        Text.create(comic.title);
                                        Text.debugLine("entry/src/main/ets/pages/SearchPage.ets(66:17)", "entry");
                                        Text.fontSize(15);
                                        Text.fontWeight(FontWeight.Medium);
                                        Text.fontColor(this.isDarkMode ? '#FFFFFF' : '#000000');
                                        Text.maxLines(2);
                                        Text.textOverflow({ overflow: TextOverflow.Ellipsis });
                                        Text.width('100%');
                                    }, Text);
                                    Text.pop();
                                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                                        If.create();
                                        if (comic.author.length > 0) {
                                            this.ifElseBranchUpdateFunction(0, () => {
                                                this.observeComponentCreation2((elmtId, isInitialRender) => {
                                                    Text.create(comic.author);
                                                    Text.debugLine("entry/src/main/ets/pages/SearchPage.ets(70:19)", "entry");
                                                    Text.fontSize(12);
                                                    Text.fontColor(this.isDarkMode ? '#999999' : '#666666');
                                                    Text.margin({ top: 4 });
                                                    Text.maxLines(1);
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
                                    Column.pop();
                                    Row.pop();
                                    ListItem.pop();
                                };
                                this.observeComponentCreation2(itemCreation2, ListItem);
                                ListItem.pop();
                            }
                        };
                        this.forEachUpdateFunction(elmtId, this.comics, forEachItemGenFunction);
                    }, ForEach);
                    ForEach.pop();
                    List.pop();
                });
            }
        }, If);
        If.pop();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 8 });
            Column.debugLine("entry/src/main/ets/pages/SearchPage.ets(85:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(this.isDarkMode ? '#000000' : '#F5F5F5');
        }, Column);
        this.header.bind(this)();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Search.create({ value: { value: this.keyword, changeEvent: newValue => { this.keyword = newValue; } }, placeholder: Translations.t('search_hint') });
            Search.debugLine("entry/src/main/ets/pages/SearchPage.ets(87:7)", "entry");
            Search.layoutWeight(1);
            Search.height(40);
            Search.margin({ left: 16, right: 16, bottom: 8 });
            Search.backgroundColor(this.isDarkMode ? '#1C1C1E' : '#F5F5F5');
            Search.borderRadius(20);
            Search.onChange((value: string) => { this.keyword = value; });
            Search.onSubmit(() => { this.doSearch(); });
        }, Search);
        Search.pop();
        this.sourceTabs.bind(this)();
        this.results.bind(this)();
        Column.pop();
    }
    async doSearch(): Promise<void> {
        if (this.keyword.length === 0)
            return;
        this.loading = true;
        this.error = '';
        this.comics = [];
        try {
            if (this.selectedSource === 0) {
                const result = await NhentaiApi.search(this.keyword, 1);
                this.comics = result.comics.map((b: ComicBrief) => {
                    const c = new Comic();
                    c.id = b.id;
                    c.title = b.title;
                    c.coverUrl = b.cover;
                    c.source = 'nhentai';
                    return c;
                });
            }
            else if (this.selectedSource === 1) {
                this.comics = await JmApi.search(this.keyword, 1);
            }
            else {
                const result = await HtcomicApi.search(this.keyword, 1);
                this.comics = result.comics.map((b: ComicBrief) => {
                    const c = new Comic();
                    c.id = b.id;
                    c.title = b.title;
                    c.coverUrl = b.cover;
                    c.source = 'htcomic';
                    return c;
                });
            }
        }
        catch (e) {
            this.error = String(e);
        }
        this.loading = false;
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "SearchPage";
    }
}
registerNamedRoute(() => new SearchPage(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/SearchPage", pageFullPath: "entry/src/main/ets/pages/SearchPage", integratedHsp: "false", moduleType: "followWithHap" });
