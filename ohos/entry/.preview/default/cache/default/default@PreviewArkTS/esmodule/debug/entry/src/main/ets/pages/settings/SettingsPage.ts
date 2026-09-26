if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SettingsPage_Params {
    isDarkMode?: boolean;
    darkModeOption?: number;
}
import router from "@ohos:router";
import { ThemeManager } from "@bundle:com.picacomic.harmony/entry/ets/common/ThemeManager";
import { Translations } from "@bundle:com.picacomic.harmony/entry/ets/common/Translations";
class SettingsPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.__darkModeOption = new ObservedPropertySimplePU(0, this, "darkModeOption");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SettingsPage_Params) {
        if (params.darkModeOption !== undefined) {
            this.darkModeOption = params.darkModeOption;
        }
    }
    updateStateVars(params: SettingsPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
        this.__darkModeOption.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__isDarkMode.aboutToBeDeleted();
        this.__darkModeOption.aboutToBeDeleted();
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
    private __darkModeOption: ObservedPropertySimplePU<number>;
    get darkModeOption() {
        return this.__darkModeOption.get();
    }
    set darkModeOption(newValue: number) {
        this.__darkModeOption.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(14:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(15:7)", "entry");
            Row.width('100%');
            Row.height(56);
            Row.padding({ left: 16, right: 16 });
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('<');
            Text.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(16:9)", "entry");
            Text.fontSize(20);
            Text.fontColor(this.isDarkMode ? '#4DA6FF' : '#007AFF');
            Text.onClick(() => { router.back(); });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('tab_settings'));
            Text.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(18:9)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : '#000000');
            Text.margin({ left: 16 });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(22:7)", "entry");
            Scroll.layoutWeight(1);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(23:9)", "entry");
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Appearance section
            Text.create(Translations.t('settings_appearance'));
            Text.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(25:11)", "entry");
            // Appearance section
            Text.fontSize(13);
            // Appearance section
            Text.fontColor(this.isDarkMode ? '#999999' : '#666666');
            // Appearance section
            Text.width('100%');
            // Appearance section
            Text.padding({ left: 16, top: 56, bottom: 8 });
        }, Text);
        // Appearance section
        Text.pop();
        this.settingItem.bind(this)(Translations.t('dark_mode'), this.getDarkModeLabel(), () => {
            this.cycleDarkMode();
        });
        this.settingItem.bind(this)(Translations.t('theme_color'), ThemeManager.themeColor, () => {
            this.cycleThemeColor();
        });
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Reading section
            Text.create(Translations.t('settings_reading'));
            Text.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(38:11)", "entry");
            // Reading section
            Text.fontSize(13);
            // Reading section
            Text.fontColor(this.isDarkMode ? '#999999' : '#666666');
            // Reading section
            Text.width('100%');
            // Reading section
            Text.padding({ left: 16, top: 24, bottom: 8 });
        }, Text);
        // Reading section
        Text.pop();
        this.settingItem.bind(this)(Translations.t('volume_key'), 'ON', () => { });
        this.settingItem.bind(this)(Translations.t('keep_screen_on'), 'ON', () => { });
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Comic source section
            Text.create(Translations.t('settings_comic_source'));
            Text.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(47:11)", "entry");
            // Comic source section
            Text.fontSize(13);
            // Comic source section
            Text.fontColor(this.isDarkMode ? '#999999' : '#666666');
            // Comic source section
            Text.width('100%');
            // Comic source section
            Text.padding({ left: 16, top: 24, bottom: 8 });
        }, Text);
        // Comic source section
        Text.pop();
        this.settingItem.bind(this)('JM ' + Translations.t('jm_domain_update'), '→', () => {
            router.pushUrl({ url: 'pages/settings/JmSettings' });
        });
        this.settingItem.bind(this)('HT ' + Translations.t('ht_domain_update'), '→', () => {
            router.pushUrl({ url: 'pages/settings/HtSettings' });
        });
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // System section
            Text.create(Translations.t('settings_system'));
            Text.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(60:11)", "entry");
            // System section
            Text.fontSize(13);
            // System section
            Text.fontColor(this.isDarkMode ? '#999999' : '#666666');
            // System section
            Text.width('100%');
            // System section
            Text.padding({ left: 16, top: 24, bottom: 8 });
        }, Text);
        // System section
        Text.pop();
        this.settingItem.bind(this)(Translations.t('download'), '→', () => {
            router.pushUrl({ url: 'pages/DownloadPage' });
        });
        this.settingItem.bind(this)(Translations.t('about'), '→', () => {
            router.pushUrl({ url: 'pages/settings/AboutPage' });
        });
        Column.pop();
        Scroll.pop();
        Column.pop();
    }
    settingItem(label: string, value: string, action: () => void, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(80:5)", "entry");
            Row.width('100%');
            Row.height(52);
            Row.padding({ left: 16, right: 16 });
            Row.backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF');
            Row.border({ width: { bottom: 0.5 }, color: this.isDarkMode ? '#333333' : '#E5E5EA' });
            Row.onClick(action);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(81:7)", "entry");
            Text.fontSize(15);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : '#000000');
            Text.layoutWeight(1);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(value);
            Text.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(82:7)", "entry");
            Text.fontSize(14);
            Text.fontColor(this.isDarkMode ? '#999999' : '#666666');
        }, Text);
        Text.pop();
        Row.pop();
    }
    private getDarkModeLabel(): string {
        if (this.darkModeOption === 0)
            return '跟随系统';
        if (this.darkModeOption === 1)
            return '关闭';
        return '开启';
    }
    private cycleDarkMode(): void {
        this.darkModeOption = (this.darkModeOption + 1) % 3;
        if (this.darkModeOption === 2) {
            AppStorage.setOrCreate('isDarkMode', true);
        }
        else if (this.darkModeOption === 1) {
            AppStorage.setOrCreate('isDarkMode', false);
        }
    }
    private cycleThemeColor(): void {
        const colors = ThemeManager.themePresets;
        const current = ThemeManager.themeColor;
        let idx = 0;
        for (let i = 0; i < colors.length; i++) {
            if (colors[i] === current) {
                idx = i;
                break;
            }
        }
        const next = (idx + 1) % colors.length;
        ThemeManager.setThemeColor(colors[next]);
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "SettingsPage";
    }
}
registerNamedRoute(() => new SettingsPage(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/settings/SettingsPage", pageFullPath: "entry/src/main/ets/pages/settings/SettingsPage", integratedHsp: "false", moduleType: "followWithHap" });
