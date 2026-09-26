if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ComicDetailPage_Params {
    comicId?: string;
    comic?: Comic;
    isDarkMode?: boolean;
}
import router from "@ohos:router";
import { Comic } from "@bundle:com.picacomic.harmony/entry/ets/data/model/Comic";
import { NetworkImage } from "@bundle:com.picacomic.harmony/entry/ets/components/NetworkImage";
class ComicDetailPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__comicId = new ObservedPropertySimplePU('', this, "comicId");
        this.__comic = new ObservedPropertyObjectPU(new Comic(), this, "comic");
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ComicDetailPage_Params) {
        if (params.comicId !== undefined) {
            this.comicId = params.comicId;
        }
        if (params.comic !== undefined) {
            this.comic = params.comic;
        }
    }
    updateStateVars(params: ComicDetailPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__comicId.purgeDependencyOnElmtId(rmElmtId);
        this.__comic.purgeDependencyOnElmtId(rmElmtId);
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__comicId.aboutToBeDeleted();
        this.__comic.aboutToBeDeleted();
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
    private __comic: ObservedPropertyObjectPU<Comic>;
    get comic() {
        return this.__comic.get();
    }
    set comic(newValue: Comic) {
        this.__comic.set(newValue);
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
            this.comic.id = this.comicId;
            this.comic.title = params['title'] ?? '未知漫画';
            this.comic.source = params['source'] ?? '';
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(25:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Top bar
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(27:7)", "entry");
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
            Text.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(28:9)", "entry");
            Text.fontSize(20);
            Text.fontColor(this.isDarkMode ? '#4DA6FF' : '#007AFF');
            Text.onClick(() => { router.back(); });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.comic.title);
            Text.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(32:9)", "entry");
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : '#000000');
            Text.layoutWeight(1);
            Text.margin({ left: 12 });
            Text.maxLines(1);
            Text.textOverflow({ overflow: TextOverflow.Ellipsis });
        }, Text);
        Text.pop();
        // Top bar
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(46:7)", "entry");
            Scroll.layoutWeight(1);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(47:9)", "entry");
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Cover + Info
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(49:11)", "entry");
            // Cover + Info
            Row.width('100%');
            // Cover + Info
            Row.padding(16);
        }, Row);
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new NetworkImage(this, { url: this.comic.coverUrl, imgWidth: 130, imgHeight: 180, imgBorderRadius: 8 }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/ComicDetailPage.ets", line: 50, col: 13 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            url: this.comic.coverUrl,
                            imgWidth: 130,
                            imgHeight: 180,
                            imgBorderRadius: 8
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        url: this.comic.coverUrl, imgWidth: 130, imgHeight: 180, imgBorderRadius: 8
                    });
                }
            }, { name: "NetworkImage" });
        }
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(51:13)", "entry");
            Column.layoutWeight(1);
            Column.alignItems(HorizontalAlign.Start);
            Column.margin({ left: 16 });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.comic.title);
            Text.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(52:15)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : '#000000');
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
                        Text.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(59:17)", "entry");
                        Text.fontSize(13);
                        Text.fontColor(this.isDarkMode ? '#999999' : '#666666');
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
                        Text.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(65:17)", "entry");
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
                        Text.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(80:13)", "entry");
                        Text.fontSize(14);
                        Text.fontColor(this.isDarkMode ? '#FFFFFF' : '#000000');
                        Text.width('100%');
                        Text.padding({ left: 16, right: 16, bottom: 16 });
                    }, Text);
                    Text.pop();
                });
            }
            // Chapters placeholder
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Chapters placeholder
            Text.create('章节列表');
            Text.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(88:11)", "entry");
            // Chapters placeholder
            Text.fontSize(16);
            // Chapters placeholder
            Text.fontWeight(FontWeight.Medium);
            // Chapters placeholder
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : '#000000');
            // Chapters placeholder
            Text.width('100%');
            // Chapters placeholder
            Text.padding({ left: 16, top: 56, bottom: 8 });
        }, Text);
        // Chapters placeholder
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('暂无章节数据');
            Text.debugLine("entry/src/main/ets/pages/ComicDetailPage.ets(95:11)", "entry");
            Text.fontSize(14);
            Text.fontColor(this.isDarkMode ? '#999999' : '#666666');
            Text.width('100%');
            Text.padding({ left: 16, bottom: 16 });
        }, Text);
        Text.pop();
        Column.pop();
        Scroll.pop();
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
