if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SearchPage_Params {
    keyword?: string;
    comics?: Comic[];
    isDarkMode?: boolean;
}
import router from "@ohos:router";
import type { Comic } from '../data/model/Comic';
import { SearchBar } from "@bundle:com.picacomic.harmony/entry/ets/components/SearchBar";
import { ComicGrid } from "@bundle:com.picacomic.harmony/entry/ets/components/ComicGrid";
class SearchPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__keyword = new ObservedPropertySimplePU('', this, "keyword");
        this.__comics = new ObservedPropertyObjectPU([], this, "comics");
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
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
    }
    updateStateVars(params: SearchPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__keyword.purgeDependencyOnElmtId(rmElmtId);
        this.__comics.purgeDependencyOnElmtId(rmElmtId);
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__keyword.aboutToBeDeleted();
        this.__comics.aboutToBeDeleted();
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
    private __isDarkMode: ObservedPropertyAbstractPU<boolean>;
    get isDarkMode() {
        return this.__isDarkMode.get();
    }
    set isDarkMode(newValue: boolean) {
        this.__isDarkMode.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/SearchPage.ets(16:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Top bar
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/SearchPage.ets(18:7)", "entry");
            // Top bar
            Row.width('100%');
            // Top bar
            Row.height(56);
            // Top bar
            Row.padding({ left: 16, right: 16 });
            // Top bar
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('<');
            Text.debugLine("entry/src/main/ets/pages/SearchPage.ets(19:9)", "entry");
            Text.fontSize(20);
            Text.fontColor(this.isDarkMode ? '#4DA6FF' : '#007AFF');
            Text.onClick(() => { router.back(); });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('搜索');
            Text.debugLine("entry/src/main/ets/pages/SearchPage.ets(23:9)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : '#000000');
            Text.margin({ left: 16 });
        }, Text);
        Text.pop();
        // Top bar
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            __Common__.create();
            __Common__.margin({ left: 16, right: 16, bottom: 8 });
        }, __Common__);
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new 
                    // Search bar
                    SearchBar(this, {
                        keyword: this.keyword,
                        onSearch: (kw: string) => { this.keyword = kw; },
                        onTextChanged: (text: string) => { this.keyword = text; }
                    }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/SearchPage.ets", line: 35, col: 7 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            keyword: this.keyword,
                            onSearch: (kw: string) => { this.keyword = kw; },
                            onTextChanged: (text: string) => { this.keyword = text; }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        keyword: this.keyword
                    });
                }
            }, { name: "SearchBar" });
        }
        __Common__.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // Results
            if (this.comics.length === 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Column.create();
                        Column.debugLine("entry/src/main/ets/pages/SearchPage.ets(44:9)", "entry");
                        Column.layoutWeight(1);
                        Column.justifyContent(FlexAlign.Center);
                    }, Column);
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('输入关键词搜索漫画');
                        Text.debugLine("entry/src/main/ets/pages/SearchPage.ets(45:11)", "entry");
                        Text.fontSize(14);
                        Text.fontColor(this.isDarkMode ? '#999999' : '#666666');
                    }, Text);
                    Text.pop();
                    Column.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new ComicGrid(this, { comics: this.comics, columns: 3 }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/SearchPage.ets", line: 52, col: 9 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        comics: this.comics,
                                        columns: 3
                                    };
                                };
                                componentCall.paramsGenerator_ = paramsLambda;
                            }
                            else {
                                this.updateStateVarsOfChildByElmtId(elmtId, {
                                    comics: this.comics, columns: 3
                                });
                            }
                        }, { name: "ComicGrid" });
                    }
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
        return "SearchPage";
    }
}
registerNamedRoute(() => new SearchPage(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/SearchPage", pageFullPath: "entry/src/main/ets/pages/SearchPage", integratedHsp: "false", moduleType: "followWithHap" });
