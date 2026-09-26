if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SettingSwitch_Params {
    icon?: string;
    title?: string;
    isOn?: boolean;
    isDarkMode?: boolean;
    onToggle?: (value: boolean) => void;
}
export class SettingSwitch extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__icon = new SynchedPropertySimpleOneWayPU(params.icon, this, "icon");
        this.__title = new SynchedPropertySimpleOneWayPU(params.title, this, "title");
        this.__isOn = new SynchedPropertySimpleOneWayPU(params.isOn, this, "isOn");
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.onToggle = () => { };
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SettingSwitch_Params) {
        if (params.icon === undefined) {
            this.__icon.set('');
        }
        if (params.title === undefined) {
            this.__title.set('');
        }
        if (params.isOn === undefined) {
            this.__isOn.set(false);
        }
        if (params.onToggle !== undefined) {
            this.onToggle = params.onToggle;
        }
    }
    updateStateVars(params: SettingSwitch_Params) {
        this.__icon.reset(params.icon);
        this.__title.reset(params.title);
        this.__isOn.reset(params.isOn);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__icon.purgeDependencyOnElmtId(rmElmtId);
        this.__title.purgeDependencyOnElmtId(rmElmtId);
        this.__isOn.purgeDependencyOnElmtId(rmElmtId);
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__icon.aboutToBeDeleted();
        this.__title.aboutToBeDeleted();
        this.__isOn.aboutToBeDeleted();
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
    private __isOn: SynchedPropertySimpleOneWayPU<boolean>;
    get isOn() {
        return this.__isOn.get();
    }
    set isOn(newValue: boolean) {
        this.__isOn.set(newValue);
    }
    private __isDarkMode: ObservedPropertyAbstractPU<boolean>;
    get isDarkMode() {
        return this.__isDarkMode.get();
    }
    set isDarkMode(newValue: boolean) {
        this.__isDarkMode.set(newValue);
    }
    private onToggle: (value: boolean) => void;
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/components/SettingSwitch.ets(11:5)", "entry");
            Row.width('100%');
            Row.height(56);
            Row.padding({ left: 16, right: 16 });
            Row.backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF');
            Row.border({ width: { bottom: 0.5 }, color: this.isDarkMode ? '#38383A' : '#E5E5EA' });
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            if (this.icon.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create(this.icon);
                        Text.debugLine("entry/src/main/ets/components/SettingSwitch.ets(13:9)", "entry");
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
            Text.debugLine("entry/src/main/ets/components/SettingSwitch.ets(15:7)", "entry");
            Text.fontSize(16);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF');
            Text.layoutWeight(1);
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Toggle.create({ type: ToggleType.Switch, isOn: this.isOn });
            Toggle.debugLine("entry/src/main/ets/components/SettingSwitch.ets(19:7)", "entry");
            Toggle.selectedColor(this.isDarkMode ? '#4DA6FF' : '#007AFF');
            Toggle.switchPointColor('#FFFFFF');
            Toggle.onChange((isOn: boolean) => {
                this.onToggle(isOn);
            });
        }, Toggle);
        Toggle.pop();
        Row.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
