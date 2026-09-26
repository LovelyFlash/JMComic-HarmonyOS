if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SettingsPage_Params {
    isDarkMode?: boolean;
}
import router from "@ohos:router";
import promptAction from "@ohos:promptAction";
import { ThemeManager } from "@bundle:com.picacomic.harmony/entry/ets/common/ThemeManager";
import { Translations } from "@bundle:com.picacomic.harmony/entry/ets/common/Translations";
class SettingsPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SettingsPage_Params) {
    }
    updateStateVars(params: SettingsPage_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__isDarkMode.aboutToBeDeleted();
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
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 8 });
            Column.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(12:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(13:7)", "entry");
            Row.width('100%');
            Row.height(64);
            Row.padding({ left: 16, right: 16 });
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 0, "type": 30000, params: ['icons/ic_back.svg'], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Image.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(14:9)", "entry");
            Image.width(24);
            Image.height(24);
            Image.objectFit(ImageFit.Contain);
            Image.onClick(() => { router.back(); });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('tab_settings'));
            Text.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(17:9)", "entry");
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF');
            Text.margin({ left: 12 });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(23:7)", "entry");
            Scroll.layoutWeight(1);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create({ space: 8 });
            Column.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(24:9)", "entry");
            Column.width('100%');
        }, Column);
        this.section.bind(this)('外观');
        this.item.bind(this)(Translations.t('dark_mode'), ThemeManager.isDark ? '开启' : '关闭', () => {
            ThemeManager.setDarkMode(!ThemeManager.isDark);
            promptAction.showToast({ message: this.isDarkMode ? '已切换深色模式' : '已切换浅色模式', duration: 2000 });
        });
        this.item.bind(this)(Translations.t('theme_color'), '', () => {
            const colors = ThemeManager.themePresets;
            const cur = ThemeManager.themeColor;
            let idx = 0;
            for (let i = 0; i < colors.length; i++) {
                if (colors[i] === cur) {
                    idx = i;
                    break;
                }
            }
            ThemeManager.setThemeColor(colors[(idx + 1) % colors.length]);
        });
        this.section.bind(this)('漫画源');
        this.item.bind(this)('JM 禁漫 域名更新', '→', () => { router.pushUrl({ url: 'pages/settings/JmSettings' }); });
        this.item.bind(this)('HT 绅士漫画 域名更新', '→', () => { router.pushUrl({ url: 'pages/settings/HtSettings' }); });
        this.section.bind(this)('系统');
        this.item.bind(this)(Translations.t('about'), 'v' + '1.0.0', () => { router.pushUrl({ url: 'pages/settings/AboutPage' }); });
        Column.pop();
        Scroll.pop();
        Column.pop();
    }
    section(title: string, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(title);
            Text.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(50:5)", "entry");
            Text.fontSize(13);
            Text.fontColor(this.isDarkMode ? '#8E8E93' : '#666666');
            Text.width('100%');
            Text.padding({ left: 16, top: 24, bottom: 8 });
        }, Text);
        Text.pop();
    }
    item(label: string, value: string, action: () => void, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(54:5)", "entry");
            Row.width('100%');
            Row.height(56);
            Row.padding({ left: 16, right: 16 });
            Row.backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF');
            Row.border({ width: { bottom: 0.5 }, color: this.isDarkMode ? '#38383A' : '#E5E5EA' });
            Row.onClick(action);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(55:7)", "entry");
            Text.fontSize(16);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : '#000000');
            Text.layoutWeight(1);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (value.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(value);
                        Text.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(56:31)", "entry");
                        Text.fontSize(14);
                        Text.fontColor(this.isDarkMode ? '#8E8E93' : '#666666');
                        Text.margin({ right: 4 });
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
            Image.create({ "id": 0, "type": 30000, params: ['icons/ic_arrow_right.svg'], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Image.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(57:7)", "entry");
            Image.width(16);
            Image.height(16);
            Image.objectFit(ImageFit.Contain);
        }, Image);
        Row.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "SettingsPage";
    }
}
registerNamedRoute(() => new SettingsPage(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/settings/SettingsPage", pageFullPath: "entry/src/main/ets/pages/settings/SettingsPage", integratedHsp: "false", moduleType: "followWithHap" });
