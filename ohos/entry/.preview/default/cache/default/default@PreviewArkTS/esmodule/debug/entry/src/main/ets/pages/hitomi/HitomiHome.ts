if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface HitomiHome_Params {
    isDarkMode?: boolean;
    comics?: Comic[];
}
import router from "@ohos:router";
import { Comic } from "@bundle:com.picacomic.harmony/entry/ets/data/model/Comic";
import { NetworkImage } from "@bundle:com.picacomic.harmony/entry/ets/components/NetworkImage";
class HitomiHome extends ViewPU {
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
    setInitiallyProvidedValue(params: HitomiHome_Params) {
        if (params.comics !== undefined) {
            this.comics = params.comics;
        }
    }
    updateStateVars(params: HitomiHome_Params) {
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
            Column.debugLine("entry/src/main/ets/pages/hitomi/HitomiHome.ets(18:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Header
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/hitomi/HitomiHome.ets(20:7)", "entry");
            // Header
            Row.width('100%');
            // Header
            Row.padding({ left: 16, right: 16, top: 56, bottom: 12 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('<');
            Text.debugLine("entry/src/main/ets/pages/hitomi/HitomiHome.ets(21:9)", "entry");
            Text.fontSize(20);
            Text.fontColor(this.isDarkMode ? '#4DA6FF' : '#007AFF');
            Text.margin({ right: 12 });
            Text.onClick(() => { router.back(); });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('Hitomi');
            Text.debugLine("entry/src/main/ets/pages/hitomi/HitomiHome.ets(26:9)", "entry");
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : '#000000');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Blank.create();
            Blank.debugLine("entry/src/main/ets/pages/hitomi/HitomiHome.ets(30:9)", "entry");
        }, Blank);
        Blank.pop();
        // Header
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Divider.create();
            Divider.debugLine("entry/src/main/ets/pages/hitomi/HitomiHome.ets(35:7)", "entry");
            Divider.color(this.isDarkMode ? '#333333' : '#E5E5EA');
            Divider.width('100%');
        }, Divider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Comic Grid
            Grid.create();
            Grid.debugLine("entry/src/main/ets/pages/hitomi/HitomiHome.ets(40:7)", "entry");
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
                        GridItem.debugLine("entry/src/main/ets/pages/hitomi/HitomiHome.ets(42:11)", "entry");
                    };
                    const observedDeepRender = () => {
                        this.observeComponentCreation2(itemCreation2, GridItem);
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Column.create();
                            Column.debugLine("entry/src/main/ets/pages/hitomi/HitomiHome.ets(43:13)", "entry");
                            Column.width('100%');
                            Column.padding(6);
                            Column.backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF');
                            Column.borderRadius(8);
                            Column.onClick(() => {
                                router.pushUrl({ url: 'pages/hitomi/HitomiDetail' });
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
                                    }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/hitomi/HitomiHome.ets", line: 44, col: 15 });
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
                            Text.debugLine("entry/src/main/ets/pages/hitomi/HitomiHome.ets(50:15)", "entry");
                            Text.fontSize(12);
                            Text.fontColor(this.isDarkMode ? '#FFFFFF' : '#000000');
                            Text.maxLines(2);
                            Text.textOverflow({ overflow: TextOverflow.Ellipsis });
                            Text.width('100%');
                            Text.margin({ top: 6 });
                        }, Text);
                        Text.pop();
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            Text.create(comic.subTitle);
                            Text.debugLine("entry/src/main/ets/pages/hitomi/HitomiHome.ets(57:15)", "entry");
                            Text.fontSize(10);
                            Text.fontColor(this.isDarkMode ? '#999999' : '#666666');
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
            comic.id = `hitomi_${i}`;
            comic.title = `Hitomi Artwork ${i}`;
            comic.subTitle = 'Illustration';
            comic.author = 'Artist';
            comic.coverUrl = '';
            comic.source = 'hitomi';
            comic.language = 'Japanese';
            comic.tags = ['Art', 'Gallery'];
            items.push(comic);
        }
        return items;
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "HitomiHome";
    }
}
registerNamedRoute(() => new HitomiHome(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/hitomi/HitomiHome", pageFullPath: "entry/src/main/ets/pages/hitomi/HitomiHome", integratedHsp: "false", moduleType: "followWithHap" });
