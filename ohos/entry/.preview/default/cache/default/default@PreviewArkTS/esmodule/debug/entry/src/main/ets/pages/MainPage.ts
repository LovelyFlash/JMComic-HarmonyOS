if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface MainPage_Params {
    currentTab?: number;
    isDarkMode?: boolean;
}
import router from "@ohos:router";
import hilog from "@ohos:hilog";
import { FloatingTabBar } from "@bundle:com.picacomic.harmony/entry/ets/components/FloatingTabBar";
import { ThemeManager } from "@bundle:com.picacomic.harmony/entry/ets/common/ThemeManager";
import { Translations } from "@bundle:com.picacomic.harmony/entry/ets/common/Translations";
const TAG = 'MainPage';
class MainPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__currentTab = new ObservedPropertySimplePU(0, this, "currentTab");
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: MainPage_Params) {
        if (params.currentTab !== undefined) {
            this.currentTab = params.currentTab;
        }
    }
    updateStateVars(params: MainPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__currentTab.purgeDependencyOnElmtId(rmElmtId);
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__currentTab.aboutToBeDeleted();
        this.__isDarkMode.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __currentTab: ObservedPropertySimplePU<number>;
    get currentTab() {
        return this.__currentTab.get();
    }
    set currentTab(newValue: number) {
        this.__currentTab.set(newValue);
    }
    private __isDarkMode: ObservedPropertyAbstractPU<boolean>;
    get isDarkMode() {
        return this.__isDarkMode.get();
    }
    set isDarkMode(newValue: boolean) {
        this.__isDarkMode.set(newValue);
    }
    aboutToAppear(): void {
        hilog.info(0x0000, TAG, 'MainPage aboutToAppear');
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/MainPage.ets(21:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(ThemeManager.colors.background);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // Content area — layoutWeight(1) 让它填充剩余空间
            if (this.currentTab === 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.buildExplorePage.bind(this)();
                });
            }
            else if (this.currentTab === 1) {
                this.ifElseBranchUpdateFunction(1, () => {
                    this.buildHistoryPage.bind(this)();
                });
            }
            else if (this.currentTab === 2) {
                this.ifElseBranchUpdateFunction(2, () => {
                    this.buildFavoritesPage.bind(this)();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(3, () => {
                    this.buildSettingsPage.bind(this)();
                });
            }
        }, If);
        If.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Bottom Tab Bar
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/MainPage.ets(34:7)", "entry");
            // Bottom Tab Bar
            Column.width('100%');
            // Bottom Tab Bar
            Column.padding({ bottom: 12 });
            // Bottom Tab Bar
            Column.backgroundColor(ThemeManager.colors.background);
        }, Column);
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new FloatingTabBar(this, {
                        selectedIndex: this.currentTab,
                        onTap: (index: number) => {
                            this.currentTab = index;
                        }
                    }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/MainPage.ets", line: 35, col: 9 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            selectedIndex: this.currentTab,
                            onTap: (index: number) => {
                                this.currentTab = index;
                            }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        selectedIndex: this.currentTab
                    });
                }
            }, { name: "FloatingTabBar" });
        }
        // Bottom Tab Bar
        Column.pop();
        Column.pop();
    }
    buildExplorePage(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/MainPage.ets(53:5)", "entry");
            Column.width('100%');
            Column.layoutWeight(1);
            Column.backgroundColor(ThemeManager.colors.background);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('app_name'));
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(54:7)", "entry");
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(ThemeManager.colors.textPrimary);
            Text.width('100%');
            Text.textAlign(TextAlign.Start);
            Text.padding({ left: 16, top: 56, bottom: 4 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('tab_explore'));
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(62:7)", "entry");
            Text.fontSize(14);
            Text.fontColor(ThemeManager.colors.textSecondary);
            Text.width('100%');
            Text.padding({ left: 16, bottom: 16 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Source grid
            Grid.create();
            Grid.debugLine("entry/src/main/ets/pages/MainPage.ets(69:7)", "entry");
            // Source grid
            Grid.columnsTemplate('1fr 1fr 1fr');
            // Source grid
            Grid.columnsGap(12);
            // Source grid
            Grid.rowsGap(12);
            // Source grid
            Grid.width('100%');
            // Source grid
            Grid.padding(16);
            // Source grid
            Grid.layoutWeight(1);
        }, Grid);
        this.sourceItem.bind(this)('Picacg', 'picacg');
        this.sourceItem.bind(this)('EHentai', 'ehentai');
        this.sourceItem.bind(this)('JinMan', 'jm');
        this.sourceItem.bind(this)('Hitomi', 'hitomi');
        this.sourceItem.bind(this)('HT', 'htmanga');
        this.sourceItem.bind(this)('NHentai', 'nhentai');
        // Source grid
        Grid.pop();
        Column.pop();
    }
    sourceItem(label: string, source: string, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/MainPage.ets(91:5)", "entry");
            Column.width('100%');
            Column.height(80);
            Column.justifyContent(FlexAlign.Center);
            Column.alignItems(HorizontalAlign.Center);
            Column.backgroundColor(ThemeManager.colors.surface);
            Column.borderRadius(12);
            Column.onClick(() => {
                this.navigateToSource(source);
            });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(92:7)", "entry");
            Text.fontSize(16);
            Text.fontWeight(FontWeight.Medium);
        }, Text);
        Text.pop();
        Column.pop();
    }
    buildHistoryPage(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/MainPage.ets(109:5)", "entry");
            Column.width('100%');
            Column.layoutWeight(1);
            Column.backgroundColor(ThemeManager.colors.background);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('tab_history'));
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(110:7)", "entry");
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(ThemeManager.colors.textPrimary);
            Text.width('100%');
            Text.padding({ left: 16, top: 56, bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('no_data'));
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(116:7)", "entry");
            Text.fontSize(14);
            Text.fontColor(ThemeManager.colors.textSecondary);
            Text.layoutWeight(1);
            Text.textAlign(TextAlign.Center);
            Text.width('100%');
        }, Text);
        Text.pop();
        Column.pop();
    }
    buildFavoritesPage(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/MainPage.ets(130:5)", "entry");
            Column.width('100%');
            Column.layoutWeight(1);
            Column.backgroundColor(ThemeManager.colors.background);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('tab_favorites'));
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(131:7)", "entry");
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(ThemeManager.colors.textPrimary);
            Text.width('100%');
            Text.padding({ left: 16, top: 56, bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('no_data'));
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(137:7)", "entry");
            Text.fontSize(14);
            Text.fontColor(ThemeManager.colors.textSecondary);
            Text.layoutWeight(1);
            Text.textAlign(TextAlign.Center);
            Text.width('100%');
        }, Text);
        Text.pop();
        Column.pop();
    }
    buildSettingsPage(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/MainPage.ets(151:5)", "entry");
            Column.width('100%');
            Column.layoutWeight(1);
            Column.backgroundColor(ThemeManager.colors.background);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('tab_settings'));
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(152:7)", "entry");
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(ThemeManager.colors.textPrimary);
            Text.width('100%');
            Text.padding({ left: 16, top: 56, bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Settings items
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/MainPage.ets(160:7)", "entry");
            // Settings items
            Column.width('100%');
            // Settings items
            Column.layoutWeight(1);
        }, Column);
        this.settingsItem.bind(this)(Translations.t('dark_mode'), () => {
            ThemeManager.setDarkMode(!ThemeManager.isDark);
        });
        this.settingsItem.bind(this)(Translations.t('theme_color'), () => { });
        this.settingsItem.bind(this)('JM ' + Translations.t('jm_domain_update'), () => {
            router.pushUrl({ url: 'pages/settings/JmSettings' });
        });
        this.settingsItem.bind(this)('HT ' + Translations.t('ht_domain_update'), () => {
            router.pushUrl({ url: 'pages/settings/HtSettings' });
        });
        this.settingsItem.bind(this)(Translations.t('about'), () => {
            router.pushUrl({ url: 'pages/settings/AboutPage' });
        });
        // Settings items
        Column.pop();
        Column.pop();
    }
    settingsItem(label: string, action: () => void, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/MainPage.ets(185:5)", "entry");
            Row.width('100%');
            Row.height(52);
            Row.padding({ left: 16, right: 16 });
            Row.backgroundColor(ThemeManager.colors.surface);
            Row.border({ width: { bottom: 0.5 }, color: ThemeManager.colors.divider });
            Row.onClick(action);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(186:7)", "entry");
            Text.fontSize(15);
            Text.fontColor(ThemeManager.colors.textPrimary);
            Text.layoutWeight(1);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('>');
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(190:7)", "entry");
            Text.fontSize(14);
            Text.fontColor(ThemeManager.colors.textSecondary);
        }, Text);
        Text.pop();
        Row.pop();
    }
    private navigateToSource(source: string): void {
        const pageMap: Record<string, string> = {
            'picacg': 'pages/picacg/PicacgHome',
            'ehentai': 'pages/ehentai/EhHome',
            'jm': 'pages/jm/JmHome',
            'hitomi': 'pages/hitomi/HitomiHome',
            'htmanga': 'pages/htcomic/HtHome',
            'nhentai': 'pages/nhentai/NhHome'
        };
        const page = pageMap[source];
        if (page !== undefined) {
            router.pushUrl({ url: page });
        }
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "MainPage";
    }
}
registerNamedRoute(() => new MainPage(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/MainPage", pageFullPath: "entry/src/main/ets/pages/MainPage", integratedHsp: "false", moduleType: "followWithHap" });
