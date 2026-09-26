if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ExploreSettings_Params {
    isDarkMode?: boolean;
    initialPage?: number;
    listMode?: number;
    checkClipboard?: boolean;
    sidePageTurn?: boolean;
    autoLanguageFilter?: number;
    hideReadItems?: boolean;
    hideBlockedWorks?: boolean;
    initialPages?: string[];
    listModes?: string[];
    langFilters?: string[];
}
import router from "@ohos:router";
import { SettingItem } from "@bundle:com.picacomic.harmony/entry/ets/components/SettingItem";
import { SettingSwitch } from "@bundle:com.picacomic.harmony/entry/ets/components/SettingSwitch";
import { SettingSection } from "@bundle:com.picacomic.harmony/entry/ets/components/SettingSection";
class ExploreSettings extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.__initialPage = new ObservedPropertySimplePU(0, this, "initialPage");
        this.__listMode = new ObservedPropertySimplePU(0, this, "listMode");
        this.__checkClipboard = new ObservedPropertySimplePU(true, this, "checkClipboard");
        this.__sidePageTurn = new ObservedPropertySimplePU(false, this, "sidePageTurn");
        this.__autoLanguageFilter = new ObservedPropertySimplePU(0, this, "autoLanguageFilter");
        this.__hideReadItems = new ObservedPropertySimplePU(false, this, "hideReadItems");
        this.__hideBlockedWorks = new ObservedPropertySimplePU(true, this, "hideBlockedWorks");
        this.initialPages = ['主页', '收藏夹', '探索', '分类'];
        this.listModes = ['连续模式', '分页模式'];
        this.langFilters = ['无', 'Chinese', 'English', 'Japanese'];
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ExploreSettings_Params) {
        if (params.initialPage !== undefined) {
            this.initialPage = params.initialPage;
        }
        if (params.listMode !== undefined) {
            this.listMode = params.listMode;
        }
        if (params.checkClipboard !== undefined) {
            this.checkClipboard = params.checkClipboard;
        }
        if (params.sidePageTurn !== undefined) {
            this.sidePageTurn = params.sidePageTurn;
        }
        if (params.autoLanguageFilter !== undefined) {
            this.autoLanguageFilter = params.autoLanguageFilter;
        }
        if (params.hideReadItems !== undefined) {
            this.hideReadItems = params.hideReadItems;
        }
        if (params.hideBlockedWorks !== undefined) {
            this.hideBlockedWorks = params.hideBlockedWorks;
        }
        if (params.initialPages !== undefined) {
            this.initialPages = params.initialPages;
        }
        if (params.listModes !== undefined) {
            this.listModes = params.listModes;
        }
        if (params.langFilters !== undefined) {
            this.langFilters = params.langFilters;
        }
    }
    updateStateVars(params: ExploreSettings_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
        this.__initialPage.purgeDependencyOnElmtId(rmElmtId);
        this.__listMode.purgeDependencyOnElmtId(rmElmtId);
        this.__checkClipboard.purgeDependencyOnElmtId(rmElmtId);
        this.__sidePageTurn.purgeDependencyOnElmtId(rmElmtId);
        this.__autoLanguageFilter.purgeDependencyOnElmtId(rmElmtId);
        this.__hideReadItems.purgeDependencyOnElmtId(rmElmtId);
        this.__hideBlockedWorks.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__isDarkMode.aboutToBeDeleted();
        this.__initialPage.aboutToBeDeleted();
        this.__listMode.aboutToBeDeleted();
        this.__checkClipboard.aboutToBeDeleted();
        this.__sidePageTurn.aboutToBeDeleted();
        this.__autoLanguageFilter.aboutToBeDeleted();
        this.__hideReadItems.aboutToBeDeleted();
        this.__hideBlockedWorks.aboutToBeDeleted();
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
    private __initialPage: ObservedPropertySimplePU<number>;
    get initialPage() {
        return this.__initialPage.get();
    }
    set initialPage(newValue: number) {
        this.__initialPage.set(newValue);
    }
    private __listMode: ObservedPropertySimplePU<number>;
    get listMode() {
        return this.__listMode.get();
    }
    set listMode(newValue: number) {
        this.__listMode.set(newValue);
    }
    private __checkClipboard: ObservedPropertySimplePU<boolean>;
    get checkClipboard() {
        return this.__checkClipboard.get();
    }
    set checkClipboard(newValue: boolean) {
        this.__checkClipboard.set(newValue);
    }
    private __sidePageTurn: ObservedPropertySimplePU<boolean>;
    get sidePageTurn() {
        return this.__sidePageTurn.get();
    }
    set sidePageTurn(newValue: boolean) {
        this.__sidePageTurn.set(newValue);
    }
    private __autoLanguageFilter: ObservedPropertySimplePU<number>;
    get autoLanguageFilter() {
        return this.__autoLanguageFilter.get();
    }
    set autoLanguageFilter(newValue: number) {
        this.__autoLanguageFilter.set(newValue);
    }
    private __hideReadItems: ObservedPropertySimplePU<boolean>;
    get hideReadItems() {
        return this.__hideReadItems.get();
    }
    set hideReadItems(newValue: boolean) {
        this.__hideReadItems.set(newValue);
    }
    private __hideBlockedWorks: ObservedPropertySimplePU<boolean>;
    get hideBlockedWorks() {
        return this.__hideBlockedWorks.get();
    }
    set hideBlockedWorks(newValue: boolean) {
        this.__hideBlockedWorks.set(newValue);
    }
    private initialPages: string[];
    private listModes: string[];
    private langFilters: string[];
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/settings/ExploreSettings.ets(25:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(this.isDarkMode ? '#000000' : '#F5F5F5');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/settings/ExploreSettings.ets(26:7)", "entry");
            Row.width('100%');
            Row.height(64);
            Row.padding({ left: 16, right: 16 });
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 0, "type": 30000, params: ['icons/ic_back.svg'], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Image.debugLine("entry/src/main/ets/pages/settings/ExploreSettings.ets(27:9)", "entry");
            Image.width(24);
            Image.height(24);
            Image.objectFit(ImageFit.Contain);
            Image.onClick(() => { router.back(); });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('浏览设置');
            Text.debugLine("entry/src/main/ets/pages/settings/ExploreSettings.ets(30:9)", "entry");
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : '#000000');
            Text.margin({ left: 12 });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/settings/ExploreSettings.ets(37:7)", "entry");
            Scroll.layoutWeight(1);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/settings/ExploreSettings.ets(38:9)", "entry");
            Column.width('100%');
        }, Column);
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSection(this, { title: '显示' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ExploreSettings.ets", line: 39, col: 11 });
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
                    let componentCall = new SettingItem(this, { icon: '🏠', title: '初始页面', value: this.initialPages[this.initialPage], onTap: () => {
                            this.initialPage = (this.initialPage + 1) % this.initialPages.length;
                        } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ExploreSettings.ets", line: 40, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🏠',
                            title: '初始页面',
                            value: this.initialPages[this.initialPage],
                            onTap: () => {
                                this.initialPage = (this.initialPage + 1) % this.initialPages.length;
                            }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🏠', title: '初始页面', value: this.initialPages[this.initialPage]
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📋', title: '探索页面配置', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ExploreSettings.ets", line: 43, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📋',
                            title: '探索页面配置',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📋', title: '探索页面配置'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🗂️', title: '分类页面配置', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ExploreSettings.ets", line: 44, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🗂️',
                            title: '分类页面配置',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🗂️', title: '分类页面配置'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📱', title: '漫画列表显示', value: this.listModes[this.listMode], onTap: () => {
                            this.listMode = (this.listMode + 1) % this.listModes.length;
                        } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ExploreSettings.ets", line: 45, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📱',
                            title: '漫画列表显示',
                            value: this.listModes[this.listMode],
                            onTap: () => {
                                this.listMode = (this.listMode + 1) % this.listModes.length;
                            }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📱', title: '漫画列表显示', value: this.listModes[this.listMode]
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🚫', title: '关键词屏蔽', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ExploreSettings.ets", line: 48, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🚫',
                            title: '关键词屏蔽',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🚫', title: '关键词屏蔽'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSection(this, { title: '过滤' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ExploreSettings.ets", line: 50, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '过滤'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '过滤'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSwitch(this, { icon: '👁️', title: '完全隐藏屏蔽作品', isOn: this.hideBlockedWorks, onToggle: (v: boolean) => { this.hideBlockedWorks = v; } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ExploreSettings.ets", line: 51, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '👁️',
                            title: '完全隐藏屏蔽作品',
                            isOn: this.hideBlockedWorks,
                            onToggle: (v: boolean) => { this.hideBlockedWorks = v; }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '👁️', title: '完全隐藏屏蔽作品', isOn: this.hideBlockedWorks
                    });
                }
            }, { name: "SettingSwitch" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSwitch(this, { icon: '📖', title: '隐藏已读内容', isOn: this.hideReadItems, onToggle: (v: boolean) => { this.hideReadItems = v; } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ExploreSettings.ets", line: 52, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📖',
                            title: '隐藏已读内容',
                            isOn: this.hideReadItems,
                            onToggle: (v: boolean) => { this.hideReadItems = v; }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📖', title: '隐藏已读内容', isOn: this.hideReadItems
                    });
                }
            }, { name: "SettingSwitch" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🌐', title: '自动语言筛选', value: this.langFilters[this.autoLanguageFilter], onTap: () => {
                            this.autoLanguageFilter = (this.autoLanguageFilter + 1) % this.langFilters.length;
                        } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ExploreSettings.ets", line: 53, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🌐',
                            title: '自动语言筛选',
                            value: this.langFilters[this.autoLanguageFilter],
                            onTap: () => {
                                this.autoLanguageFilter = (this.autoLanguageFilter + 1) % this.langFilters.length;
                            }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🌐', title: '自动语言筛选', value: this.langFilters[this.autoLanguageFilter]
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSection(this, { title: '搜索' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ExploreSettings.ets", line: 57, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '搜索'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '搜索'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🔎', title: '默认搜索源', value: 'NHentai', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ExploreSettings.ets", line: 58, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🔎',
                            title: '默认搜索源',
                            value: 'NHentai',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🔎', title: '默认搜索源', value: 'NHentai'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSection(this, { title: '工具' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ExploreSettings.ets", line: 60, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '工具'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '工具'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSwitch(this, { icon: '📋', title: '检查剪切板链接', isOn: this.checkClipboard, onToggle: (v: boolean) => { this.checkClipboard = v; } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ExploreSettings.ets", line: 61, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📋',
                            title: '检查剪切板链接',
                            isOn: this.checkClipboard,
                            onToggle: (v: boolean) => { this.checkClipboard = v; }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📋', title: '检查剪切板链接', isOn: this.checkClipboard
                    });
                }
            }, { name: "SettingSwitch" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSwitch(this, { icon: '📱', title: '侧边翻页栏', isOn: this.sidePageTurn, onToggle: (v: boolean) => { this.sidePageTurn = v; } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/ExploreSettings.ets", line: 62, col: 11 });
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
        Column.pop();
        Scroll.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "ExploreSettings";
    }
}
registerNamedRoute(() => new ExploreSettings(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/settings/ExploreSettings", pageFullPath: "entry/src/main/ets/pages/settings/ExploreSettings", integratedHsp: "false", moduleType: "followWithHap" });
