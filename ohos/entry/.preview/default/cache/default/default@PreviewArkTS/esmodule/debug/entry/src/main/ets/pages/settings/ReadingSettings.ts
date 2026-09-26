if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ReadingSettings_Params {
    isDarkMode?: boolean;
    readMode?: number;
    tapTurnPage?: boolean;
    volumeKeyTurnPage?: boolean;
    keepScreenOn?: boolean;
    showChapterComments?: boolean;
    showCommentsAtEnd?: boolean;
    fontSize?: number;
    imageQuality?: number;
    pageAnimation?: boolean;
    autoPageTime?: number;
    imageLayout?: number;
    invertTap?: boolean;
    doubleTapZoom?: boolean;
    longPressZoom?: boolean;
    sidePageTurn?: boolean;
    showPageInfo?: boolean;
    readModes?: string[];
    imageQualities?: string[];
    imageLayouts?: string[];
    fontSizes?: number[];
    autoPageTimes?: number[];
}
import router from "@ohos:router";
import { SettingItem } from "@bundle:com.picacomic.harmony/entry/ets/components/SettingItem";
import { SettingSwitch } from "@bundle:com.picacomic.harmony/entry/ets/components/SettingSwitch";
import { SettingSection } from "@bundle:com.picacomic.harmony/entry/ets/components/SettingSection";
class ReadingSettings extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.__readMode = new ObservedPropertySimplePU(2 // 0=左→右 1=右→左 2=上→下 3=连续 4=双页 5=双页反向
        , this, "readMode");
        this.__tapTurnPage = new ObservedPropertySimplePU(true, this, "tapTurnPage");
        this.__volumeKeyTurnPage = new ObservedPropertySimplePU(true, this, "volumeKeyTurnPage");
        this.__keepScreenOn = new ObservedPropertySimplePU(true, this, "keepScreenOn");
        this.__showChapterComments = new ObservedPropertySimplePU(true, this, "showChapterComments");
        this.__showCommentsAtEnd = new ObservedPropertySimplePU(false, this, "showCommentsAtEnd");
        this.__fontSize = new ObservedPropertySimplePU(16, this, "fontSize");
        this.__imageQuality = new ObservedPropertySimplePU(0 // 0=original 1=high 2=medium
        , this, "imageQuality");
        this.__pageAnimation = new ObservedPropertySimplePU(true, this, "pageAnimation");
        this.__autoPageTime = new ObservedPropertySimplePU(5, this, "autoPageTime");
        this.__imageLayout = new ObservedPropertySimplePU(0 // 0=contain 1=fitWidth 2=fitHeight
        , this, "imageLayout");
        this.__invertTap = new ObservedPropertySimplePU(false, this, "invertTap");
        this.__doubleTapZoom = new ObservedPropertySimplePU(true, this, "doubleTapZoom");
        this.__longPressZoom = new ObservedPropertySimplePU(true, this, "longPressZoom");
        this.__sidePageTurn = new ObservedPropertySimplePU(false, this, "sidePageTurn");
        this.__showPageInfo = new ObservedPropertySimplePU(true, this, "showPageInfo");
        this.readModes = ['从左至右', '从右至左', '从上至下', '从上至下(连续)', '双页', '双页(反向)'];
        this.imageQualities = ['Original', 'High', 'Medium'];
        this.imageLayouts = ['自适应', '适应宽度', '适应高度'];
        this.fontSizes = [12, 14, 16, 18, 20, 22, 24];
        this.autoPageTimes = [3, 5, 8, 10, 15];
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ReadingSettings_Params) {
        if (params.readMode !== undefined) {
            this.readMode = params.readMode;
        }
        if (params.tapTurnPage !== undefined) {
            this.tapTurnPage = params.tapTurnPage;
        }
        if (params.volumeKeyTurnPage !== undefined) {
            this.volumeKeyTurnPage = params.volumeKeyTurnPage;
        }
        if (params.keepScreenOn !== undefined) {
            this.keepScreenOn = params.keepScreenOn;
        }
        if (params.showChapterComments !== undefined) {
            this.showChapterComments = params.showChapterComments;
        }
        if (params.showCommentsAtEnd !== undefined) {
            this.showCommentsAtEnd = params.showCommentsAtEnd;
        }
        if (params.fontSize !== undefined) {
            this.fontSize = params.fontSize;
        }
        if (params.imageQuality !== undefined) {
            this.imageQuality = params.imageQuality;
        }
        if (params.pageAnimation !== undefined) {
            this.pageAnimation = params.pageAnimation;
        }
        if (params.autoPageTime !== undefined) {
            this.autoPageTime = params.autoPageTime;
        }
        if (params.imageLayout !== undefined) {
            this.imageLayout = params.imageLayout;
        }
        if (params.invertTap !== undefined) {
            this.invertTap = params.invertTap;
        }
        if (params.doubleTapZoom !== undefined) {
            this.doubleTapZoom = params.doubleTapZoom;
        }
        if (params.longPressZoom !== undefined) {
            this.longPressZoom = params.longPressZoom;
        }
        if (params.sidePageTurn !== undefined) {
            this.sidePageTurn = params.sidePageTurn;
        }
        if (params.showPageInfo !== undefined) {
            this.showPageInfo = params.showPageInfo;
        }
        if (params.readModes !== undefined) {
            this.readModes = params.readModes;
        }
        if (params.imageQualities !== undefined) {
            this.imageQualities = params.imageQualities;
        }
        if (params.imageLayouts !== undefined) {
            this.imageLayouts = params.imageLayouts;
        }
        if (params.fontSizes !== undefined) {
            this.fontSizes = params.fontSizes;
        }
        if (params.autoPageTimes !== undefined) {
            this.autoPageTimes = params.autoPageTimes;
        }
    }
    updateStateVars(params: ReadingSettings_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
        this.__readMode.purgeDependencyOnElmtId(rmElmtId);
        this.__tapTurnPage.purgeDependencyOnElmtId(rmElmtId);
        this.__volumeKeyTurnPage.purgeDependencyOnElmtId(rmElmtId);
        this.__keepScreenOn.purgeDependencyOnElmtId(rmElmtId);
        this.__showChapterComments.purgeDependencyOnElmtId(rmElmtId);
        this.__showCommentsAtEnd.purgeDependencyOnElmtId(rmElmtId);
        this.__fontSize.purgeDependencyOnElmtId(rmElmtId);
        this.__imageQuality.purgeDependencyOnElmtId(rmElmtId);
        this.__pageAnimation.purgeDependencyOnElmtId(rmElmtId);
        this.__autoPageTime.purgeDependencyOnElmtId(rmElmtId);
        this.__imageLayout.purgeDependencyOnElmtId(rmElmtId);
        this.__invertTap.purgeDependencyOnElmtId(rmElmtId);
        this.__doubleTapZoom.purgeDependencyOnElmtId(rmElmtId);
        this.__longPressZoom.purgeDependencyOnElmtId(rmElmtId);
        this.__sidePageTurn.purgeDependencyOnElmtId(rmElmtId);
        this.__showPageInfo.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__isDarkMode.aboutToBeDeleted();
        this.__readMode.aboutToBeDeleted();
        this.__tapTurnPage.aboutToBeDeleted();
        this.__volumeKeyTurnPage.aboutToBeDeleted();
        this.__keepScreenOn.aboutToBeDeleted();
        this.__showChapterComments.aboutToBeDeleted();
        this.__showCommentsAtEnd.aboutToBeDeleted();
        this.__fontSize.aboutToBeDeleted();
        this.__imageQuality.aboutToBeDeleted();
        this.__pageAnimation.aboutToBeDeleted();
        this.__autoPageTime.aboutToBeDeleted();
        this.__imageLayout.aboutToBeDeleted();
        this.__invertTap.aboutToBeDeleted();
        this.__doubleTapZoom.aboutToBeDeleted();
        this.__longPressZoom.aboutToBeDeleted();
        this.__sidePageTurn.aboutToBeDeleted();
        this.__showPageInfo.aboutToBeDeleted();
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
    private __readMode: ObservedPropertySimplePU<number>; // 0=左→右 1=右→左 2=上→下 3=连续 4=双页 5=双页反向
    get readMode() {
        return this.__readMode.get();
    }
    set readMode(newValue: number) {
        this.__readMode.set(newValue);
    }
    private __tapTurnPage: ObservedPropertySimplePU<boolean>;
    get tapTurnPage() {
        return this.__tapTurnPage.get();
    }
    set tapTurnPage(newValue: boolean) {
        this.__tapTurnPage.set(newValue);
    }
    private __volumeKeyTurnPage: ObservedPropertySimplePU<boolean>;
    get volumeKeyTurnPage() {
        return this.__volumeKeyTurnPage.get();
    }
    set volumeKeyTurnPage(newValue: boolean) {
        this.__volumeKeyTurnPage.set(newValue);
    }
    private __keepScreenOn: ObservedPropertySimplePU<boolean>;
    get keepScreenOn() {
        return this.__keepScreenOn.get();
    }
    set keepScreenOn(newValue: boolean) {
        this.__keepScreenOn.set(newValue);
    }
    private __showChapterComments: ObservedPropertySimplePU<boolean>;
    get showChapterComments() {
        return this.__showChapterComments.get();
    }
    set showChapterComments(newValue: boolean) {
        this.__showChapterComments.set(newValue);
    }
    private __showCommentsAtEnd: ObservedPropertySimplePU<boolean>;
    get showCommentsAtEnd() {
        return this.__showCommentsAtEnd.get();
    }
    set showCommentsAtEnd(newValue: boolean) {
        this.__showCommentsAtEnd.set(newValue);
    }
    private __fontSize: ObservedPropertySimplePU<number>;
    get fontSize() {
        return this.__fontSize.get();
    }
    set fontSize(newValue: number) {
        this.__fontSize.set(newValue);
    }
    private __imageQuality: ObservedPropertySimplePU<number>; // 0=original 1=high 2=medium
    get imageQuality() {
        return this.__imageQuality.get();
    }
    set imageQuality(newValue: number) {
        this.__imageQuality.set(newValue);
    }
    private __pageAnimation: ObservedPropertySimplePU<boolean>;
    get pageAnimation() {
        return this.__pageAnimation.get();
    }
    set pageAnimation(newValue: boolean) {
        this.__pageAnimation.set(newValue);
    }
    private __autoPageTime: ObservedPropertySimplePU<number>;
    get autoPageTime() {
        return this.__autoPageTime.get();
    }
    set autoPageTime(newValue: number) {
        this.__autoPageTime.set(newValue);
    }
    private __imageLayout: ObservedPropertySimplePU<number>; // 0=contain 1=fitWidth 2=fitHeight
    get imageLayout() {
        return this.__imageLayout.get();
    }
    set imageLayout(newValue: number) {
        this.__imageLayout.set(newValue);
    }
    private __invertTap: ObservedPropertySimplePU<boolean>;
    get invertTap() {
        return this.__invertTap.get();
    }
    set invertTap(newValue: boolean) {
        this.__invertTap.set(newValue);
    }
    private __doubleTapZoom: ObservedPropertySimplePU<boolean>;
    get doubleTapZoom() {
        return this.__doubleTapZoom.get();
    }
    set doubleTapZoom(newValue: boolean) {
        this.__doubleTapZoom.set(newValue);
    }
    private __longPressZoom: ObservedPropertySimplePU<boolean>;
    get longPressZoom() {
        return this.__longPressZoom.get();
    }
    set longPressZoom(newValue: boolean) {
        this.__longPressZoom.set(newValue);
    }
    private __sidePageTurn: ObservedPropertySimplePU<boolean>;
    get sidePageTurn() {
        return this.__sidePageTurn.get();
    }
    set sidePageTurn(newValue: boolean) {
        this.__sidePageTurn.set(newValue);
    }
    private __showPageInfo: ObservedPropertySimplePU<boolean>;
    get showPageInfo() {
        return this.__showPageInfo.get();
    }
    set showPageInfo(newValue: boolean) {
        this.__showPageInfo.set(newValue);
    }
    private readModes: string[];
    private imageQualities: string[];
    private imageLayouts: string[];
    private fontSizes: number[];
    private autoPageTimes: number[];
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 8 });
            Column.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(36:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(37:7)", "entry");
            Row.width('100%');
            Row.height(64);
            Row.padding({ left: 16, right: 16 });
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 0, "type": 30000, params: ['icons/ic_back.svg'], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Image.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(38:9)", "entry");
            Image.width(24);
            Image.height(24);
            Image.objectFit(ImageFit.Contain);
            Image.onClick(() => { router.back(); });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('阅读设置');
            Text.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(41:9)", "entry");
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF');
            Text.margin({ left: 12 });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(48:7)", "entry");
            Scroll.layoutWeight(1);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 8 });
            Column.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(49:9)", "entry");
            Column.width('100%');
        }, Column);
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSection(this, { title: '翻页方式' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 50, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '翻页方式'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '翻页方式'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📖', title: '阅读模式', value: this.readModes[this.readMode], onTap: () => {
                            this.readMode = (this.readMode + 1) % this.readModes.length;
                        } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 51, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📖',
                            title: '阅读模式',
                            value: this.readModes[this.readMode],
                            onTap: () => {
                                this.readMode = (this.readMode + 1) % this.readModes.length;
                            }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📖', title: '阅读模式', value: this.readModes[this.readMode]
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSection(this, { title: '翻页控制' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 55, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '翻页控制'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '翻页控制'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSwitch(this, { icon: '👆', title: '点按翻页', isOn: this.tapTurnPage, onToggle: (v: boolean) => { this.tapTurnPage = v; } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 56, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '👆',
                            title: '点按翻页',
                            isOn: this.tapTurnPage,
                            onToggle: (v: boolean) => { this.tapTurnPage = v; }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '👆', title: '点按翻页', isOn: this.tapTurnPage
                    });
                }
            }, { name: "SettingSwitch" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSwitch(this, { icon: '↕️', title: '反转点按翻页', isOn: this.invertTap, onToggle: (v: boolean) => { this.invertTap = v; } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 57, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '↕️',
                            title: '反转点按翻页',
                            isOn: this.invertTap,
                            onToggle: (v: boolean) => { this.invertTap = v; }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '↕️', title: '反转点按翻页', isOn: this.invertTap
                    });
                }
            }, { name: "SettingSwitch" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSwitch(this, { icon: '🔊', title: '音量键翻页', isOn: this.volumeKeyTurnPage, onToggle: (v: boolean) => { this.volumeKeyTurnPage = v; } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 58, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🔊',
                            title: '音量键翻页',
                            isOn: this.volumeKeyTurnPage,
                            onToggle: (v: boolean) => { this.volumeKeyTurnPage = v; }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🔊', title: '音量键翻页', isOn: this.volumeKeyTurnPage
                    });
                }
            }, { name: "SettingSwitch" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSwitch(this, { icon: '📱', title: '侧边翻页栏', isOn: this.sidePageTurn, onToggle: (v: boolean) => { this.sidePageTurn = v; } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 59, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📱',
                            title: '侧边翻页栏',
                            isOn: this.sidePageTurn,
                            onToggle: (v: boolean) => { this.sidePageTurn = v; }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📱', title: '侧边翻页栏', isOn: this.sidePageTurn
                    });
                }
            }, { name: "SettingSwitch" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSection(this, { title: '显示' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 61, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '显示'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '显示'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSwitch(this, { icon: '🔆', title: '屏幕常亮', isOn: this.keepScreenOn, onToggle: (v: boolean) => { this.keepScreenOn = v; } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 62, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🔆',
                            title: '屏幕常亮',
                            isOn: this.keepScreenOn,
                            onToggle: (v: boolean) => { this.keepScreenOn = v; }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🔆', title: '屏幕常亮', isOn: this.keepScreenOn
                    });
                }
            }, { name: "SettingSwitch" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSwitch(this, { icon: '✨', title: '翻页动画', isOn: this.pageAnimation, onToggle: (v: boolean) => { this.pageAnimation = v; } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 63, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '✨',
                            title: '翻页动画',
                            isOn: this.pageAnimation,
                            onToggle: (v: boolean) => { this.pageAnimation = v; }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '✨', title: '翻页动画', isOn: this.pageAnimation
                    });
                }
            }, { name: "SettingSwitch" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSwitch(this, { icon: 'ℹ️', title: '显示页码', isOn: this.showPageInfo, onToggle: (v: boolean) => { this.showPageInfo = v; } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 64, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: 'ℹ️',
                            title: '显示页码',
                            isOn: this.showPageInfo,
                            onToggle: (v: boolean) => { this.showPageInfo = v; }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: 'ℹ️', title: '显示页码', isOn: this.showPageInfo
                    });
                }
            }, { name: "SettingSwitch" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSwitch(this, { icon: '💬', title: '显示章节评论', isOn: this.showChapterComments, onToggle: (v: boolean) => { this.showChapterComments = v; } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 65, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '💬',
                            title: '显示章节评论',
                            isOn: this.showChapterComments,
                            onToggle: (v: boolean) => { this.showChapterComments = v; }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '💬', title: '显示章节评论', isOn: this.showChapterComments
                    });
                }
            }, { name: "SettingSwitch" });
        }
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.showChapterComments) {
                this.ifElseBranchUpdateFunction(0, () => {
                    {
                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                            if (isInitialRender) {
                                let componentCall = new SettingSwitch(this, { icon: '📝', title: '章节末尾显示评论', isOn: this.showCommentsAtEnd, onToggle: (v: boolean) => { this.showCommentsAtEnd = v; } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 67, col: 13 });
                                ViewPU.create(componentCall);
                                let paramsLambda = () => {
                                    return {
                                        icon: '📝',
                                        title: '章节末尾显示评论',
                                        isOn: this.showCommentsAtEnd,
                                        onToggle: (v: boolean) => { this.showCommentsAtEnd = v; }
                                    };
                                };
                                componentCall.paramsGenerator_ = paramsLambda;
                            }
                            else {
                                this.updateStateVarsOfChildByElmtId(elmtId, {
                                    icon: '📝', title: '章节末尾显示评论', isOn: this.showCommentsAtEnd
                                });
                            }
                        }, { name: "SettingSwitch" });
                    }
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSection(this, { title: '缩放' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 70, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '缩放'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '缩放'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSwitch(this, { icon: '🔍', title: '双击缩放', isOn: this.doubleTapZoom, onToggle: (v: boolean) => { this.doubleTapZoom = v; } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 71, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🔍',
                            title: '双击缩放',
                            isOn: this.doubleTapZoom,
                            onToggle: (v: boolean) => { this.doubleTapZoom = v; }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🔍', title: '双击缩放', isOn: this.doubleTapZoom
                    });
                }
            }, { name: "SettingSwitch" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSwitch(this, { icon: '✋', title: '长按缩放', isOn: this.longPressZoom, onToggle: (v: boolean) => { this.longPressZoom = v; } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 72, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '✋',
                            title: '长按缩放',
                            isOn: this.longPressZoom,
                            onToggle: (v: boolean) => { this.longPressZoom = v; }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '✋', title: '长按缩放', isOn: this.longPressZoom
                    });
                }
            }, { name: "SettingSwitch" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSection(this, { title: '图片' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 74, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '图片'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '图片'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🖼️', title: '图片质量', value: this.imageQualities[this.imageQuality], onTap: () => {
                            this.imageQuality = (this.imageQuality + 1) % this.imageQualities.length;
                        } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 75, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🖼️',
                            title: '图片质量',
                            value: this.imageQualities[this.imageQuality],
                            onTap: () => {
                                this.imageQuality = (this.imageQuality + 1) % this.imageQualities.length;
                            }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🖼️', title: '图片质量', value: this.imageQualities[this.imageQuality]
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📐', title: '图片布局', value: this.imageLayouts[this.imageLayout], onTap: () => {
                            this.imageLayout = (this.imageLayout + 1) % this.imageLayouts.length;
                        } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 78, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📐',
                            title: '图片布局',
                            value: this.imageLayouts[this.imageLayout],
                            onTap: () => {
                                this.imageLayout = (this.imageLayout + 1) % this.imageLayouts.length;
                            }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📐', title: '图片布局', value: this.imageLayouts[this.imageLayout]
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSection(this, { title: '字体' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 82, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '字体'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '字体'
                    });
                }
            }, { name: "SettingSection" });
        }
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(83:11)", "entry");
            Row.width('100%');
            Row.height(56);
            Row.padding({ left: 16, right: 16 });
            Row.backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF');
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('A');
            Text.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(84:13)", "entry");
            Text.fontSize(12);
            Text.fontColor(this.isDarkMode ? '#8E8E93' : '#666666');
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Slider.create({
                value: this.fontSize,
                min: 12,
                max: 24,
                step: 2,
                style: SliderStyle.OutSet
            });
            Slider.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(85:13)", "entry");
            Slider.layoutWeight(1);
            Slider.onChange((value: number) => { this.fontSize = value; });
        }, Slider);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('A');
            Text.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(94:13)", "entry");
            Text.fontSize(24);
            Text.fontColor(this.isDarkMode ? '#8E8E93' : '#666666');
        }, Text);
        Text.pop();
        Row.pop();
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSection(this, { title: '自动翻页' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 99, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '自动翻页'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '自动翻页'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '⏱️', title: '自动翻页间隔', value: this.autoPageTime.toString() + '秒', onTap: () => {
                            let idx = this.autoPageTimes.indexOf(this.autoPageTime);
                            idx = (idx + 1) % this.autoPageTimes.length;
                            this.autoPageTime = this.autoPageTimes[idx];
                        } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ReadingSettings.ets", line: 100, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '⏱️',
                            title: '自动翻页间隔',
                            value: this.autoPageTime.toString() + '秒',
                            onTap: () => {
                                let idx = this.autoPageTimes.indexOf(this.autoPageTime);
                                idx = (idx + 1) % this.autoPageTimes.length;
                                this.autoPageTime = this.autoPageTimes[idx];
                            }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '⏱️', title: '自动翻页间隔', value: this.autoPageTime.toString() + '秒'
                    });
                }
            }, { name: "SettingItem" });
        }
        Column.pop();
        Scroll.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "ReadingSettings";
    }
}
registerNamedRoute(() => new ReadingSettings(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/settings/ReadingSettings", pageFullPath: "entry/src/main/ets/pages/settings/ReadingSettings", integratedHsp: "false", moduleType: "followWithHap" });
