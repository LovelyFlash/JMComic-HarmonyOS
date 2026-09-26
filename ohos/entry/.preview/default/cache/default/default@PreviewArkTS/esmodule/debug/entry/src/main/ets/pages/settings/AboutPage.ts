if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface AboutPage_Params {
    isDarkMode?: boolean;
}
import router from "@ohos:router";
import { ThemeManager } from "@bundle:com.picacomic.harmony/entry/ets/common/ThemeManager";
import { Translations } from "@bundle:com.picacomic.harmony/entry/ets/common/Translations";
import { ApiConstants } from "@bundle:com.picacomic.harmony/entry/ets/common/Constants";
class AboutPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: AboutPage_Params) {
    }
    updateStateVars(params: AboutPage_Params) {
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
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/settings/AboutPage.ets(13:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(ThemeManager.colors.background);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/settings/AboutPage.ets(14:7)", "entry");
            Row.width('100%');
            Row.height(56);
            Row.padding({ left: 16, right: 16 });
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('<');
            Text.debugLine("entry/src/main/ets/pages/settings/AboutPage.ets(15:9)", "entry");
            Text.fontSize(20);
            Text.fontColor(ThemeManager.colors.primary);
            Text.onClick(() => { router.back(); });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('about'));
            Text.debugLine("entry/src/main/ets/pages/settings/AboutPage.ets(17:9)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(ThemeManager.colors.textPrimary);
            Text.margin({ left: 16 });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/settings/AboutPage.ets(21:7)", "entry");
            Column.layoutWeight(1);
            Column.justifyContent(FlexAlign.Center);
            Column.alignItems(HorizontalAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('📚');
            Text.debugLine("entry/src/main/ets/pages/settings/AboutPage.ets(22:9)", "entry");
            Text.fontSize(64);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(ApiConstants.APP_NAME);
            Text.debugLine("entry/src/main/ets/pages/settings/AboutPage.ets(24:9)", "entry");
            Text.fontSize(24);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(ThemeManager.colors.textPrimary);
            Text.margin({ top: 56 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('HarmonyOS Version');
            Text.debugLine("entry/src/main/ets/pages/settings/AboutPage.ets(29:9)", "entry");
            Text.fontSize(14);
            Text.fontColor(ThemeManager.colors.textSecondary);
            Text.margin({ top: 4 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('v' + ApiConstants.APP_VERSION);
            Text.debugLine("entry/src/main/ets/pages/settings/AboutPage.ets(33:9)", "entry");
            Text.fontSize(14);
            Text.fontColor(ThemeManager.colors.textSecondary);
            Text.margin({ top: 4 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('基于 ArkTS/ArkUI 开发');
            Text.debugLine("entry/src/main/ets/pages/settings/AboutPage.ets(37:9)", "entry");
            Text.fontSize(13);
            Text.fontColor(ThemeManager.colors.textSecondary);
            Text.margin({ top: 56 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('原项目: ccbkv/PicaComic');
            Text.debugLine("entry/src/main/ets/pages/settings/AboutPage.ets(41:9)", "entry");
            Text.fontSize(13);
            Text.fontColor(ThemeManager.colors.textSecondary);
            Text.margin({ top: 8 });
        }, Text);
        Text.pop();
        Column.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "AboutPage";
    }
}
registerNamedRoute(() => new AboutPage(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/settings/AboutPage", pageFullPath: "entry/src/main/ets/pages/settings/AboutPage", integratedHsp: "false", moduleType: "followWithHap" });
