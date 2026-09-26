if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SettingItem_Params {
    icon?: string;
    title?: string;
    value?: string;
    showArrow?: boolean;
    isDarkMode?: boolean;
    onTap?: () => void;
}
export class SettingItem extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__icon = new SynchedPropertySimpleOneWayPU(params.icon, this, "icon");
        this.__title = new SynchedPropertySimpleOneWayPU(params.title, this, "title");
        this.__value = new SynchedPropertySimpleOneWayPU(params.value, this, "value");
        this.__showArrow = new SynchedPropertySimpleOneWayPU(params.showArrow, this, "showArrow");
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.onTap = () => { };
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SettingItem_Params) {
        if (params.icon === undefined) {
            this.__icon.set('');
        }
        if (params.title === undefined) {
            this.__title.set('');
        }
        if (params.value === undefined) {
            this.__value.set('');
        }
        if (params.showArrow === undefined) {
            this.__showArrow.set(true);
        }
        if (params.onTap !== undefined) {
            this.onTap = params.onTap;
        }
    }
    updateStateVars(params: SettingItem_Params) {
        this.__icon.reset(params.icon);
        this.__title.reset(params.title);
        this.__value.reset(params.value);
        this.__showArrow.reset(params.showArrow);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__icon.purgeDependencyOnElmtId(rmElmtId);
        this.__title.purgeDependencyOnElmtId(rmElmtId);
        this.__value.purgeDependencyOnElmtId(rmElmtId);
        this.__showArrow.purgeDependencyOnElmtId(rmElmtId);
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__icon.aboutToBeDeleted();
        this.__title.aboutToBeDeleted();
        this.__value.aboutToBeDeleted();
        this.__showArrow.aboutToBeDeleted();
        this.__isDarkMode.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __icon: SynchedPropertySimpleOneWayPU<string>;
    get icon() {
        return this.__icon.get();
    }
    set icon(newValue: string) {
        this.__icon.set(newValue);
    }
    private __title: SynchedPropertySimpleOneWayPU<string>;
    get title() {
        return this.__title.get();
    }
    set title(newValue: string) {
        this.__title.set(newValue);
    }
    private __value: SynchedPropertySimpleOneWayPU<string>;
    get value() {
        return this.__value.get();
    }
    set value(newValue: string) {
        this.__value.set(newValue);
    }
    private __showArrow: SynchedPropertySimpleOneWayPU<boolean>;
    get showArrow() {
        return this.__showArrow.get();
    }
    set showArrow(newValue: boolean) {
        this.__showArrow.set(newValue);
    }
    private __isDarkMode: ObservedPropertyAbstractPU<boolean>;
    get isDarkMode() {
        return this.__isDarkMode.get();
    }
    set isDarkMode(newValue: boolean) {
        this.__isDarkMode.set(newValue);
    }
    private onTap: () => void;
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/components/SettingItem.ets(12:5)", "entry");
            Row.width('100%');
            Row.height(56);
            Row.padding({ left: 16, right: 16 });
            Row.backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF');
            Row.border({ width: { bottom: 0.5 }, color: this.isDarkMode ? '#38383A' : '#E5E5EA' });
            Row.onClick(() => { this.onTap(); });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.icon.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.icon);
                        Text.debugLine("entry/src/main/ets/components/SettingItem.ets(14:9)", "entry");
                        Text.fontSize(20);
                        Text.margin({ right: 12 });
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
            Text.create(this.title);
            Text.debugLine("entry/src/main/ets/components/SettingItem.ets(16:7)", "entry");
            Text.fontSize(16);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF');
            Text.layoutWeight(1);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.value.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.value);
                        Text.debugLine("entry/src/main/ets/components/SettingItem.ets(21:9)", "entry");
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
            If.create();
            if (this.showArrow) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Image.create({ "id": 0, "type": 30000, params: ['icons/ic_arrow_right.svg'], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
                        Image.debugLine("entry/src/main/ets/components/SettingItem.ets(27:9)", "entry");
                        Image.width(16);
                        Image.height(16);
                        Image.objectFit(ImageFit.Contain);
                    }, Image);
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        Row.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
