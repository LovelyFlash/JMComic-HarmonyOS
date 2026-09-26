if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface DownloadPage_Params {
    isDarkMode?: boolean;
}
import router from "@ohos:router";
import { ThemeManager } from "@bundle:com.picacomic.harmony/entry/ets/common/ThemeManager";
import { Translations } from "@bundle:com.picacomic.harmony/entry/ets/common/Translations";
class DownloadPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: DownloadPage_Params) {
    }
    updateStateVars(params: DownloadPage_Params) {
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
            Column.debugLine("entry/src/main/ets/pages/DownloadPage.ets(12:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(ThemeManager.colors.background);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/DownloadPage.ets(13:7)", "entry");
            Row.width('100%');
            Row.height(56);
            Row.padding({ left: 16, right: 16 });
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('<');
            Text.debugLine("entry/src/main/ets/pages/DownloadPage.ets(14:9)", "entry");
            Text.fontSize(20);
            Text.fontColor(ThemeManager.colors.primary);
            Text.onClick(() => { router.back(); });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('download'));
            Text.debugLine("entry/src/main/ets/pages/DownloadPage.ets(16:9)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(ThemeManager.colors.textPrimary);
            Text.margin({ left: 16 });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/DownloadPage.ets(20:7)", "entry");
            Column.layoutWeight(1);
            Column.justifyContent(FlexAlign.Center);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('no_data'));
            Text.debugLine("entry/src/main/ets/pages/DownloadPage.ets(21:9)", "entry");
            Text.fontSize(14);
            Text.fontColor(ThemeManager.colors.textSecondary);
        }, Text);
        Text.pop();
        Column.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "DownloadPage";
    }
}
registerNamedRoute(() => new DownloadPage(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/DownloadPage", pageFullPath: "entry/src/main/ets/pages/DownloadPage", integratedHsp: "false", moduleType: "followWithHap" });
