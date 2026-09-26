if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SettingSection_Params {
    title?: string;
    isDarkMode?: boolean;
}
export class SettingSection extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__title = new SynchedPropertySimpleOneWayPU(params.title, this, "title");
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SettingSection_Params) {
        if (params.title === undefined) {
            this.__title.set('');
        }
    }
    updateStateVars(params: SettingSection_Params) {
        this.__title.reset(params.title);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__title.purgeDependencyOnElmtId(rmElmtId);
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__title.aboutToBeDeleted();
        this.__isDarkMode.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __title: SynchedPropertySimpleOneWayPU<string>;
    get title() {
        return this.__title.get();
    }
    set title(newValue: string) {
        this.__title.set(newValue);
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
            Text.create(this.title);
            Text.debugLine("entry/src/main/ets/components/SettingSection.ets(8:5)", "entry");
            Text.fontSize(13);
            Text.fontColor(this.isDarkMode ? '#999999' : '#666666');
            Text.width('100%');
            Text.padding({ left: 16, top: 24, bottom: 8 });
        }, Text);
        Text.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
