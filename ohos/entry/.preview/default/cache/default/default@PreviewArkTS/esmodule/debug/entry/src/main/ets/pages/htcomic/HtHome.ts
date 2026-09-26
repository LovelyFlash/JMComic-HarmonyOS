if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface HtHome_Params {
    isDarkMode?: boolean;
    comics?: Comic[];
}
import router from "@ohos:router";
import { ThemeManager } from "@bundle:com.picacomic.harmony/entry/ets/common/ThemeManager";
import { Comic } from "@bundle:com.picacomic.harmony/entry/ets/data/model/Comic";
import { NetworkImage } from "@bundle:com.picacomic.harmony/entry/ets/components/NetworkImage";
class HtHome extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.__comics = new ObservedPropertyObjectPU([], this, "comics");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: HtHome_Params) {
        if (params.comics !== undefined) {
            this.comics = params.comics;
        }
    }
    updateStateVars(params: HtHome_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
        this.__comics.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__isDarkMode.aboutToBeDeleted();
        this.__comics.aboutToBeDeleted();
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
    aboutToAppear(): void {
        this.comics = this.buildPlaceholderComics();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/htcomic/HtHome.ets(18:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(ThemeManager.colors.background);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Header
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/htcomic/HtHome.ets(20:7)", "entry");
            // Header
            Row.width('100%');
            // Header
            Row.padding({ left: 16, right: 16, top: 56, bottom: 12 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('<');
            Text.debugLine("entry/src/main/ets/pages/htcomic/HtHome.ets(21:9)", "entry");
            Text.fontSize(20);
            Text.fontColor(ThemeManager.colors.primary);
            Text.margin({ right: 12 });
            Text.onClick(() => { router.back(); });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('缁呭＋婕敾');
            Text.debugLine("entry/src/main/ets/pages/htcomic/HtHome.ets(26:9)", "entry");
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(ThemeManager.colors.textPrimary);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/htcomic/HtHome.ets(30:9)", "entry");
        }, Blank);
        Blank.pop();
        // Header
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/htcomic/HtHome.ets(35:7)", "entry");
            Divider.color(ThemeManager.colors.border);
            Divider.width('100%');
        }, Divider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Comic Grid
            Grid.create();
            Grid.debugLine("entry/src/main/ets/pages/htcomic/HtHome.ets(40:7)", "entry");
            // Comic Grid
            Grid.columnsTemplate('1fr 1fr 1fr');
            // Comic Grid
            Grid.columnsGap(8);
            // Comic Grid
            Grid.rowsGap(10);
            // Comic Grid
            Grid.width('100%');
            // Comic Grid
            Grid.padding(12);
            // Comic Grid
            Grid.layoutWeight(1);
        }, Grid);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const comic = _item;
                {
                    const itemCreation2 = (elmtId, isInitialRender) => {
                        GridItem.create(() => { }, false);
                        GridItem.debugLine("entry/src/main/ets/pages/htcomic/HtHome.ets(42:11)", "entry");
                    };
                    const observedDeepRender = () => {
                        this.observeComponentCreation2(itemCreation2, GridItem);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Column.create();
                            Column.debugLine("entry/src/main/ets/pages/htcomic/HtHome.ets(43:13)", "entry");
                            Column.width('100%');
                            Column.padding(6);
                            Column.backgroundColor(ThemeManager.colors.surface);
                            Column.borderRadius(8);
                            Column.onClick(() => {
                                router.pushUrl({ url: 'pages/htcomic/HtDetail' });
                            });
                        }, Column);
                        {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                if (isInitialRender) {
                                    let componentCall = new NetworkImage(this, {
                                        url: comic.coverUrl,
                                        imgWidth: 100,
                                        imgHeight: 180,
                                        imgBorderRadius: 8
                                    }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/htcomic/HtHome.ets", line: 44, col: 15 });
                                    ViewPU.create(componentCall);
                                    let paramsLambda = () => {
                                        return {
                                            url: comic.coverUrl,
                                            imgWidth: 100,
                                            imgHeight: 180,
                                            imgBorderRadius: 8
                                        };
                                    };
                                    componentCall.paramsGenerator_ = paramsLambda;
                                }
                                else {
                                    this.updateStateVarsOfChildByElmtId(elmtId, {
                                        url: comic.coverUrl,
                                        imgWidth: 100,
                                        imgHeight: 180,
                                        imgBorderRadius: 8
                                    });
                                }
                            }, { name: "NetworkImage" });
                        }
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create(comic.title);
                            Text.debugLine("entry/src/main/ets/pages/htcomic/HtHome.ets(50:15)", "entry");
                            Text.fontSize(12);
                            Text.fontColor(ThemeManager.colors.textPrimary);
                            Text.maxLines(2);
                            Text.textOverflow({ overflow: TextOverflow.Ellipsis });
                            Text.width('100%');
                            Text.margin({ top: 6 });
                        }, Text);
                        Text.pop();
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create(comic.subTitle);
                            Text.debugLine("entry/src/main/ets/pages/htcomic/HtHome.ets(57:15)", "entry");
                            Text.fontSize(10);
                            Text.fontColor(ThemeManager.colors.textSecondary);
                            Text.maxLines(1);
                            Text.width('100%');
                            Text.margin({ top: 2 });
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
        // Comic Grid
        Grid.pop();
        Column.pop();
    }
    private buildPlaceholderComics(): Comic[] {
        const items: Comic[] = [];
        for (let i = 1; i <= 6; i++) {
            const comic: Comic = new Comic();
            comic.id = `ht_${i}`;
            comic.title = `缁呭＋婕敾 ${i}`;
            comic.subTitle = 'Manga';
            comic.author = 'Artist';
            comic.coverUrl = '';
            comic.source = 'htmanga';
            comic.language = 'Chinese';
            comic.tags = ['Manga', 'Chinese'];
            items.push(comic);
        }
        return items;
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "HtHome";
    }
}
registerNamedRoute(() => new HtHome(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/htcomic/HtHome", pageFullPath: "entry/src/main/ets/pages/htcomic/HtHome", integratedHsp: "false", moduleType: "followWithHap" });
