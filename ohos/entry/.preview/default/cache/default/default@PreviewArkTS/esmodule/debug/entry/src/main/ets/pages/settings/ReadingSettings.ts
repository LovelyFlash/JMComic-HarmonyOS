if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface ReadingSettings_Params {
    isDarkMode?: boolean;
    fontSize?: number;
    imageQuality?: number;
}
import router from "@ohos:router";
import { ThemeManager } from "@bundle:com.picacomic.harmony/entry/ets/common/ThemeManager";
import { Translations } from "@bundle:com.picacomic.harmony/entry/ets/common/Translations";
class ReadingSettings extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.__fontSize = new ObservedPropertySimplePU(16, this, "fontSize");
        this.__imageQuality = new ObservedPropertySimplePU(0, this, "imageQuality");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: ReadingSettings_Params) {
        if (params.fontSize !== undefined) {
            this.fontSize = params.fontSize;
        }
        if (params.imageQuality !== undefined) {
            this.imageQuality = params.imageQuality;
        }
    }
    updateStateVars(params: ReadingSettings_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
        this.__fontSize.purgeDependencyOnElmtId(rmElmtId);
        this.__imageQuality.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__isDarkMode.aboutToBeDeleted();
        this.__fontSize.aboutToBeDeleted();
        this.__imageQuality.aboutToBeDeleted();
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
    private __fontSize: ObservedPropertySimplePU<number>;
    get fontSize() {
        return this.__fontSize.get();
    }
    set fontSize(newValue: number) {
        this.__fontSize.set(newValue);
    }
    private __imageQuality: ObservedPropertySimplePU<number>;
    get imageQuality() {
        return this.__imageQuality.get();
    }
    set imageQuality(newValue: number) {
        this.__imageQuality.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(14:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(ThemeManager.colors.background);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(15:7)", "entry");
            Row.width('100%');
            Row.height(56);
            Row.padding({ left: 16, right: 16 });
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('<');
            Text.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(16:9)", "entry");
            Text.fontSize(20);
            Text.fontColor(ThemeManager.colors.primary);
            Text.onClick(() => { router.back(); });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('settings_reading'));
            Text.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(18:9)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(ThemeManager.colors.textPrimary);
            Text.margin({ left: 16 });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(23:7)", "entry");
            Column.layoutWeight(1);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('font_size'));
            Text.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(24:9)", "entry");
            Text.fontSize(13);
            Text.fontColor(ThemeManager.colors.textSecondary);
            Text.width('100%');
            Text.padding({ left: 16, top: 56, bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(27:9)", "entry");
            Row.width('100%');
            Row.padding({ left: 16, right: 16 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = _item => {
                const size = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(size.toString());
                    Text.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(29:13)", "entry");
                    Text.fontSize(size);
                    Text.fontColor(size === this.fontSize ? ThemeManager.colors.primary : ThemeManager.colors.textPrimary);
                    Text.padding({ left: 12, right: 12, top: 8, bottom: 8 });
                    Text.borderRadius(8);
                    Text.backgroundColor(size === this.fontSize ? '#F0F8FF' : 'transparent');
                    Text.onClick(() => { this.fontSize = size; });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, [12, 14, 16, 18, 20, 22], forEachItemGenFunction);
        }, ForEach);
        ForEach.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('image_quality'));
            Text.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(39:9)", "entry");
            Text.fontSize(13);
            Text.fontColor(ThemeManager.colors.textSecondary);
            Text.width('100%');
            Text.padding({ left: 16, top: 24, bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(42:9)", "entry");
            Row.width('100%');
            Row.padding({ left: 16, right: 16 });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, index: number) => {
                const quality = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(quality);
                    Text.debugLine("entry/src/main/ets/pages/settings/ReadingSettings.ets(44:13)", "entry");
                    Text.fontSize(14);
                    Text.fontColor(index === this.imageQuality ? ThemeManager.colors.primary : ThemeManager.colors.textPrimary);
                    Text.padding({ left: 12, right: 12, top: 8, bottom: 8 });
                    Text.borderRadius(8);
                    Text.backgroundColor(index === this.imageQuality ? '#F0F8FF' : 'transparent');
                    Text.onClick(() => { this.imageQuality = index; });
                }, Text);
                Text.pop();
            };
            this.forEachUpdateFunction(elmtId, ['original', 'high', 'medium'], forEachItemGenFunction, undefined, true, false);
        }, ForEach);
        ForEach.pop();
        Row.pop();
        Column.pop();
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
