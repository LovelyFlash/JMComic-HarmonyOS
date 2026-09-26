if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface HtSettings_Params {
    currentDomain?: string;
    availableDomains?: string[];
    isLoading?: boolean;
    isDarkMode?: boolean;
}
import router from "@ohos:router";
import { Translations } from "@bundle:com.picacomic.harmony/entry/ets/common/Translations";
import { ApiConstants } from "@bundle:com.picacomic.harmony/entry/ets/common/Constants";
import { AppData } from "@bundle:com.picacomic.harmony/entry/ets/viewmodel/AppData";
import { Logger } from "@bundle:com.picacomic.harmony/entry/ets/common/Logger";
import { Network } from "@bundle:com.picacomic.harmony/entry/ets/common/Network";
const TAG = 'HtSettings';
class HtSettings extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__currentDomain = new ObservedPropertySimplePU('', this, "currentDomain");
        this.__availableDomains = new ObservedPropertyObjectPU([], this, "availableDomains");
        this.__isLoading = new ObservedPropertySimplePU(false, this, "isLoading");
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: HtSettings_Params) {
        if (params.currentDomain !== undefined) {
            this.currentDomain = params.currentDomain;
        }
        if (params.availableDomains !== undefined) {
            this.availableDomains = params.availableDomains;
        }
        if (params.isLoading !== undefined) {
            this.isLoading = params.isLoading;
        }
    }
    updateStateVars(params: HtSettings_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__currentDomain.purgeDependencyOnElmtId(rmElmtId);
        this.__availableDomains.purgeDependencyOnElmtId(rmElmtId);
        this.__isLoading.purgeDependencyOnElmtId(rmElmtId);
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__currentDomain.aboutToBeDeleted();
        this.__availableDomains.aboutToBeDeleted();
        this.__isLoading.aboutToBeDeleted();
        this.__isDarkMode.aboutToBeDeleted();
        SubscriberManager.Get().delete(this.id__());
        this.aboutToBeDeletedInternal();
    }
    private __currentDomain: ObservedPropertySimplePU<string>;
    get currentDomain() {
        return this.__currentDomain.get();
    }
    set currentDomain(newValue: string) {
        this.__currentDomain.set(newValue);
    }
    private __availableDomains: ObservedPropertyObjectPU<string[]>;
    get availableDomains() {
        return this.__availableDomains.get();
    }
    set availableDomains(newValue: string[]) {
        this.__availableDomains.set(newValue);
    }
    private __isLoading: ObservedPropertySimplePU<boolean>;
    get isLoading() {
        return this.__isLoading.get();
    }
    set isLoading(newValue: boolean) {
        this.__isLoading.set(newValue);
    }
    private __isDarkMode: ObservedPropertyAbstractPU<boolean>;
    get isDarkMode() {
        return this.__isDarkMode.get();
    }
    set isDarkMode(newValue: boolean) {
        this.__isDarkMode.set(newValue);
    }
    aboutToAppear(): void {
        this.currentDomain = AppData.htBaseUrl;
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/settings/HtSettings.ets(25:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/settings/HtSettings.ets(26:7)", "entry");
            Row.width('100%');
            Row.height(56);
            Row.padding({ left: 16, right: 16 });
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('<');
            Text.debugLine("entry/src/main/ets/pages/settings/HtSettings.ets(27:9)", "entry");
            Text.fontSize(20);
            Text.fontColor(this.isDarkMode ? '#4DA6FF' : '#007AFF');
            Text.onClick(() => { router.back(); });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('HT ' + Translations.t('ht_domain_update'));
            Text.debugLine("entry/src/main/ets/pages/settings/HtSettings.ets(29:9)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : '#000000');
            Text.margin({ left: 16 });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/settings/HtSettings.ets(34:7)", "entry");
            Scroll.layoutWeight(1);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/settings/HtSettings.ets(35:9)", "entry");
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('当前域名');
            Text.debugLine("entry/src/main/ets/pages/settings/HtSettings.ets(36:11)", "entry");
            Text.fontSize(13);
            Text.fontColor(this.isDarkMode ? '#999999' : '#666666');
            Text.width('100%');
            Text.padding({ left: 16, top: 56, bottom: 8 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.currentDomain);
            Text.debugLine("entry/src/main/ets/pages/settings/HtSettings.ets(38:11)", "entry");
            Text.fontSize(15);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : '#000000');
            Text.width('100%');
            Text.padding({ left: 16, bottom: 16 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Fetch remote domains
            Button.createWithLabel(this.isLoading ? '加载中...' : '获取远程域名列表');
            Button.debugLine("entry/src/main/ets/pages/settings/HtSettings.ets(42:11)", "entry");
            // Fetch remote domains
            Button.width('90%');
            // Fetch remote domains
            Button.height(44);
            // Fetch remote domains
            Button.margin({ top: 12 });
            // Fetch remote domains
            Button.fontSize(14);
            // Fetch remote domains
            Button.fontColor('#FFFFFF');
            // Fetch remote domains
            Button.backgroundColor(this.isLoading ? '#999999' : this.isDarkMode ? '#FFB340' : '#FF9500');
            // Fetch remote domains
            Button.onClick(() => { this.fetchDomains(); });
        }, Button);
        // Fetch remote domains
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            If.create();
            // Available domains
            if (this.availableDomains.length > 0) {
                this.ifElseBranchUpdateFunction(0, () => {
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        Text.create('可用域名');
                        Text.debugLine("entry/src/main/ets/pages/settings/HtSettings.ets(50:13)", "entry");
                        Text.fontSize(13);
                        Text.fontColor(this.isDarkMode ? '#999999' : '#666666');
                        Text.width('100%');
                        Text.padding({ left: 16, top: 24, bottom: 8 });
                    }, Text);
                    Text.pop();
                    this.observeComponentCreation2((elmtId, isInitialRender) => {
                        ForEach.create();
                        const forEachItemGenFunction = _item => {
                            const domain = _item;
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Row.create();
                                Row.debugLine("entry/src/main/ets/pages/settings/HtSettings.ets(54:15)", "entry");
                                Row.width('100%');
                                Row.height(52);
                                Row.padding({ left: 16, right: 16 });
                                Row.backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF');
                                Row.border({ width: { bottom: 0.5 }, color: this.isDarkMode ? '#333333' : '#E5E5EA' });
                                Row.onClick(() => {
                                    AppData.htBaseUrl = domain;
                                    this.currentDomain = domain;
                                });
                            }, Row);
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create(domain);
                                Text.debugLine("entry/src/main/ets/pages/settings/HtSettings.ets(55:17)", "entry");
                                Text.fontSize(14);
                                Text.fontColor(domain === this.currentDomain ? this.isDarkMode ? '#4DA6FF' : '#007AFF' : this.isDarkMode ? '#FFFFFF' : '#000000');
                                Text.layoutWeight(1);
                            }, Text);
                            Text.pop();
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                If.create();
                                if (domain === this.currentDomain) {
                                    this.ifElseBranchUpdateFunction(0, () => {
                                        this.observeComponentCreation2((elmtId, isInitialRender) => {
                                            Text.create('●');
                                            Text.debugLine("entry/src/main/ets/pages/settings/HtSettings.ets(59:19)", "entry");
                                            Text.fontSize(16);
                                            Text.fontColor(this.isDarkMode ? '#4DA6FF' : '#007AFF');
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
                            Row.pop();
                        };
                        this.forEachUpdateFunction(elmtId, this.availableDomains, forEachItemGenFunction);
                    }, ForEach);
                    ForEach.pop();
                });
            }
            else {
                this.ifElseBranchUpdateFunction(1, () => {
                });
            }
        }, If);
        If.pop();
        Column.pop();
        Scroll.pop();
        Column.pop();
    }
    private async fetchDomains(): Promise<void> {
        this.isLoading = true;
        const data = await Network.get(ApiConstants.HT_DOMAIN_URL);
        if (data.length > 0) {
            const lines = data.split('\n');
            const domains: string[] = [];
            for (const line of lines) {
                const trimmed = line.trim();
                if (trimmed.length > 0) {
                    try {
                        const decoded = decodeURIComponent(trimmed);
                        if (decoded.startsWith('http')) {
                            domains.push(decoded);
                        }
                        else {
                            domains.push(trimmed);
                        }
                    }
                    catch (e) {
                        domains.push(trimmed);
                    }
                }
            }
            this.availableDomains = domains;
            Logger.info(TAG, `Fetched ${domains.length} HT domains`);
        }
        this.isLoading = false;
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "HtSettings";
    }
}
registerNamedRoute(() => new HtSettings(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/settings/HtSettings", pageFullPath: "entry/src/main/ets/pages/settings/HtSettings", integratedHsp: "false", moduleType: "followWithHap" });
