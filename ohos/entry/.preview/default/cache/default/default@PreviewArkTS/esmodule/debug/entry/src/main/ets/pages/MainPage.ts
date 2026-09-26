if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface MainPage_Params {
    currentTab?: number;
}
import router from "@ohos:router";
import hilog from "@ohos:hilog";
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
    }
    aboutToBeDeleted() {
        this.__currentTab.aboutToBeDeleted();
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
    aboutToAppear(): void {
        hilog.info(0x0000, TAG, 'MainPage aboutToAppear');
    }
    tabBuilder(title: string, iconRes: Resource, iconSelectedRes: Resource, index: number, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/MainPage.ets(20:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.justifyContent(FlexAlign.Center);
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create(this.currentTab === index ? iconSelectedRes : iconRes);
            Image.debugLine("entry/src/main/ets/pages/MainPage.ets(21:7)", "entry");
            Image.width(24);
            Image.height(24);
            Image.objectFit(ImageFit.Contain);
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(title);
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(25:7)", "entry");
            Text.fontSize(10);
            Text.fontColor(this.currentTab === index ? { "id": 125829231, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" } : { "id": 125829216, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Text.margin({ top: 2 });
        }, Text);
        Text.pop();
        Column.pop();
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/MainPage.ets(39:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor({ "id": 125829129, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Tabs.create({ barPosition: BarPosition.End, index: this.currentTab });
            Tabs.debugLine("entry/src/main/ets/pages/MainPage.ets(40:7)", "entry");
            Tabs.vertical(false);
            Tabs.barHeight(56);
            Tabs.barMode(BarMode.Fixed);
            Tabs.onChange((index: number) => {
                this.currentTab = index;
            });
        }, Tabs);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TabContent.create(() => {
                this.buildExplorePage.bind(this)();
            });
            TabContent.tabBar({ builder: () => {
                    this.tabBuilder.call(this, Translations.t('tab_explore'), $r('app.media.ic_explore'), $r('app.media.ic_explore_selected'), 0);
                } });
            TabContent.debugLine("entry/src/main/ets/pages/MainPage.ets(41:9)", "entry");
        }, TabContent);
        TabContent.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TabContent.create(() => {
                this.buildHistoryPage.bind(this)();
            });
            TabContent.tabBar({ builder: () => {
                    this.tabBuilder.call(this, Translations.t('tab_history'), $r('app.media.ic_history'), $r('app.media.ic_history_selected'), 1);
                } });
            TabContent.debugLine("entry/src/main/ets/pages/MainPage.ets(46:9)", "entry");
        }, TabContent);
        TabContent.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TabContent.create(() => {
                this.buildFavoritesPage.bind(this)();
            });
            TabContent.tabBar({ builder: () => {
                    this.tabBuilder.call(this, Translations.t('tab_favorites'), $r('app.media.ic_favorites'), $r('app.media.ic_favorites_selected'), 2);
                } });
            TabContent.debugLine("entry/src/main/ets/pages/MainPage.ets(51:9)", "entry");
        }, TabContent);
        TabContent.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            TabContent.create(() => {
                this.buildSettingsPage.bind(this)();
            });
            TabContent.tabBar({ builder: () => {
                    this.tabBuilder.call(this, Translations.t('tab_settings'), $r('app.media.ic_settings'), $r('app.media.ic_settings_selected'), 3);
                } });
            TabContent.debugLine("entry/src/main/ets/pages/MainPage.ets(56:9)", "entry");
        }, TabContent);
        TabContent.pop();
        Tabs.pop();
        Column.pop();
    }
    buildExplorePage(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/MainPage.ets(75:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor({ "id": 125829132, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('app_name'));
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(76:7)", "entry");
            Text.fontSize(28);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor({ "id": 125829210, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Text.width('100%');
            Text.textAlign(TextAlign.Start);
            Text.padding({ left: 24, top: 64, bottom: 4 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('tab_explore'));
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(84:7)", "entry");
            Text.fontSize(14);
            Text.fontColor({ "id": 125829216, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Text.width('100%');
            Text.padding({ left: 24, bottom: 20 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Grid.create();
            Grid.debugLine("entry/src/main/ets/pages/MainPage.ets(90:7)", "entry");
            Grid.columnsTemplate('1fr 1fr 1fr');
            Grid.columnsGap(12);
            Grid.rowsGap(12);
            Grid.width('100%');
            Grid.padding(16);
            Grid.layoutWeight(1);
        }, Grid);
        this.sourceItem.bind(this)('Picacg', 'picacg');
        this.sourceItem.bind(this)('EHentai', 'ehentai');
        this.sourceItem.bind(this)('JinMan', 'jm');
        this.sourceItem.bind(this)('Hitomi', 'hitomi');
        this.sourceItem.bind(this)('HT', 'htmanga');
        this.sourceItem.bind(this)('NHentai', 'nhentai');
        Grid.pop();
        Column.pop();
    }
    sourceItem(label: string, source: string, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/MainPage.ets(112:5)", "entry");
            Column.width('100%');
            Column.height(80);
            Column.justifyContent(FlexAlign.Center);
            Column.alignItems(HorizontalAlign.Center);
            Column.backgroundColor({ "id": 125829129, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Column.borderRadius(16);
            Column.shadow({ radius: 4, color: 'rgba(0,0,0,0.08)', offsetY: 2 });
            Column.onClick(() => {
                this.navigateToSource(source);
            });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(113:7)", "entry");
            Text.fontSize(15);
            Text.fontWeight(FontWeight.Medium);
            Text.fontColor({ "id": 125829210, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
        }, Text);
        Text.pop();
        Column.pop();
    }
    buildHistoryPage(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/MainPage.ets(132:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor({ "id": 125829132, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('tab_history'));
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(133:7)", "entry");
            Text.fontSize(28);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor({ "id": 125829210, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Text.width('100%');
            Text.padding({ left: 24, top: 64, bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/MainPage.ets(139:7)", "entry");
            Column.layoutWeight(1);
            Column.justifyContent(FlexAlign.Center);
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('no_data'));
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(140:9)", "entry");
            Text.fontSize(14);
            Text.fontColor({ "id": 125829216, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
        }, Text);
        Text.pop();
        Column.pop();
        Column.pop();
    }
    buildFavoritesPage(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/MainPage.ets(155:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor({ "id": 125829132, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('tab_favorites'));
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(156:7)", "entry");
            Text.fontSize(28);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor({ "id": 125829210, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Text.width('100%');
            Text.padding({ left: 24, top: 64, bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/MainPage.ets(162:7)", "entry");
            Column.layoutWeight(1);
            Column.justifyContent(FlexAlign.Center);
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('no_data'));
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(163:9)", "entry");
            Text.fontSize(14);
            Text.fontColor({ "id": 125829216, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
        }, Text);
        Text.pop();
        Column.pop();
        Column.pop();
    }
    buildSettingsPage(parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/MainPage.ets(178:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor({ "id": 125829132, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('tab_settings'));
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(179:7)", "entry");
            Text.fontSize(28);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor({ "id": 125829210, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Text.width('100%');
            Text.padding({ left: 24, top: 64, bottom: 16 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/MainPage.ets(186:7)", "entry");
            Scroll.layoutWeight(1);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/MainPage.ets(187:9)", "entry");
            Column.width('100%');
        }, Column);
        this.settingsSection.bind(this)(Translations.t('settings_appearance'));
        this.settingsItem.bind(this)(Translations.t('dark_mode'), () => {
            ThemeManager.setDarkMode(!ThemeManager.isDark);
        });
        this.settingsItem.bind(this)(Translations.t('theme_color'), () => {
            const colors = ThemeManager.themePresets;
            const current = ThemeManager.themeColor;
            let idx = 0;
            for (let i = 0; i < colors.length; i++) {
                if (colors[i] === current) {
                    idx = i;
                    break;
                }
            }
            ThemeManager.setThemeColor(colors[(idx + 1) % colors.length]);
        });
        this.settingsSection.bind(this)(Translations.t('settings_comic_source'));
        this.settingsItem.bind(this)('JM ' + Translations.t('jm_domain_update'), () => {
            router.pushUrl({ url: 'pages/settings/JmSettings' });
        });
        this.settingsItem.bind(this)('HT ' + Translations.t('ht_domain_update'), () => {
            router.pushUrl({ url: 'pages/settings/HtSettings' });
        });
        this.settingsSection.bind(this)(Translations.t('settings_system'));
        this.settingsItem.bind(this)(Translations.t('about'), () => {
            router.pushUrl({ url: 'pages/settings/AboutPage' });
        });
        Column.pop();
        Scroll.pop();
        Column.pop();
    }
    settingsSection(title: string, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(title);
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(226:5)", "entry");
            Text.fontSize(13);
            Text.fontColor({ "id": 125829216, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Text.width('100%');
            Text.padding({ left: 16, top: 24, bottom: 8 });
        }, Text);
        Text.pop();
    }
    settingsItem(label: string, action: () => void, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/MainPage.ets(235:5)", "entry");
            Row.width('100%');
            Row.height(56);
            Row.padding({ left: 16, right: 16 });
            Row.backgroundColor({ "id": 125829129, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Row.onClick(action);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(236:7)", "entry");
            Text.fontSize(16);
            Text.fontColor({ "id": 125829210, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Text.layoutWeight(1);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('>');
            Text.debugLine("entry/src/main/ets/pages/MainPage.ets(240:7)", "entry");
            Text.fontSize(16);
            Text.fontColor({ "id": 125829216, "type": 10001, params: [], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
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
