if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface FloatingTabBar_Params {
    selectedIndex?: number;
    onTap?: (index: number) => void;
    isDarkMode?: boolean;
}
import { ThemeManager } from "@bundle:com.picacomic.harmony/entry/ets/common/ThemeManager";
import { Translations } from "@bundle:com.picacomic.harmony/entry/ets/common/Translations";
export class FloatingTabBar extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__selectedIndex = new SynchedPropertySimpleOneWayPU(params.selectedIndex, this, "selectedIndex");
        this.onTap = () => { };
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: FloatingTabBar_Params) {
        if (params.selectedIndex === undefined) {
            this.__selectedIndex.set(0);
        }
        if (params.onTap !== undefined) {
            this.onTap = params.onTap;
        }
    }
    updateStateVars(params: FloatingTabBar_Params) {
        this.__selectedIndex.reset(params.selectedIndex);
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__selectedIndex.purgeDependencyOnElmtId(rmElmtId);
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__selectedIndex.aboutToBeDeleted();
        this.__isDarkMode.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __selectedIndex: SynchedPropertySimpleOneWayPU<number>;
    get selectedIndex() {
        return this.__selectedIndex.get();
    }
    set selectedIndex(newValue: number) {
        this.__selectedIndex.set(newValue);
    }
    private onTap: (index: number) => void;
    private __isDarkMode: ObservedPropertyAbstractPU<boolean>;
    get isDarkMode() {
        return this.__isDarkMode.get();
    }
    set isDarkMode(newValue: boolean) {
        this.__isDarkMode.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/components/FloatingTabBar.ets(12:5)", "entry");
            Row.width('100%');
            Row.height(52);
            Row.backgroundColor(ThemeManager.colors.surface);
            Row.border({ width: { top: 0.5 }, color: ThemeManager.colors.divider });
        }, Row);
        this.tabItem.bind(this)(0, Translations.t('tab_explore'));
        this.tabItem.bind(this)(1, Translations.t('tab_history'));
        this.tabItem.bind(this)(2, Translations.t('tab_favorites'));
        this.tabItem.bind(this)(3, Translations.t('tab_settings'));
        Row.pop();
    }
    tabItem(index: number, label: string, parent = null) {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/components/FloatingTabBar.ets(26:5)", "entry");
            Column.layoutWeight(1);
            Column.height('100%');
            Column.justifyContent(FlexAlign.Center);
            Column.alignItems(HorizontalAlign.Center);
            Column.onClick(() => {
                this.onTap(index);
            });
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(label);
            Text.debugLine("entry/src/main/ets/components/FloatingTabBar.ets(27:7)", "entry");
            Text.fontSize(11);
            Text.fontColor(this.selectedIndex === index ? ThemeManager.colors.primary : ThemeManager.colors.textSecondary);
            Text.fontWeight(this.selectedIndex === index ? FontWeight.Medium : FontWeight.Normal);
        }, Text);
        Text.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
}
