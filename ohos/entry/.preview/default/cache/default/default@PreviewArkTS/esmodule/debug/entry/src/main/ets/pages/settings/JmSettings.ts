if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface JmSettings_Params {
    currentDomain?: string;
    domains?: string[];
    isChecking?: boolean;
    healthStatus?: boolean[];
    isDarkMode?: boolean;
}
import router from "@ohos:router";
import { ThemeManager } from "@bundle:com.picacomic.harmony/entry/ets/common/ThemeManager";
import { Translations } from "@bundle:com.picacomic.harmony/entry/ets/common/Translations";
import { ApiConstants } from "@bundle:com.picacomic.harmony/entry/ets/common/Constants";
import { AppData } from "@bundle:com.picacomic.harmony/entry/ets/viewmodel/AppData";
import { Logger } from "@bundle:com.picacomic.harmony/entry/ets/common/Logger";
import { Network } from "@bundle:com.picacomic.harmony/entry/ets/common/Network";
const TAG = 'JmSettings';
class JmSettings extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__currentDomain = new ObservedPropertySimplePU('', this, "currentDomain");
        this.__domains = new ObservedPropertyObjectPU([], this, "domains");
        this.__isChecking = new ObservedPropertySimplePU(false, this, "isChecking");
        this.__healthStatus = new ObservedPropertyObjectPU([], this, "healthStatus");
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: JmSettings_Params) {
        if (params.currentDomain !== undefined) {
            this.currentDomain = params.currentDomain;
        }
        if (params.domains !== undefined) {
            this.domains = params.domains;
        }
        if (params.isChecking !== undefined) {
            this.isChecking = params.isChecking;
        }
        if (params.healthStatus !== undefined) {
            this.healthStatus = params.healthStatus;
        }
    }
    updateStateVars(params: JmSettings_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__currentDomain.purgeDependencyOnElmtId(rmElmtId);
        this.__domains.purgeDependencyOnElmtId(rmElmtId);
        this.__isChecking.purgeDependencyOnElmtId(rmElmtId);
        this.__healthStatus.purgeDependencyOnElmtId(rmElmtId);
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__currentDomain.aboutToBeDeleted();
        this.__domains.aboutToBeDeleted();
        this.__isChecking.aboutToBeDeleted();
        this.__healthStatus.aboutToBeDeleted();
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
    private __domains: ObservedPropertyObjectPU<string[]>;
    get domains() {
        return this.__domains.get();
    }
    set domains(newValue: string[]) {
        this.__domains.set(newValue);
    }
    private __isChecking: ObservedPropertySimplePU<boolean>;
    get isChecking() {
        return this.__isChecking.get();
    }
    set isChecking(newValue: boolean) {
        this.__isChecking.set(newValue);
    }
    private __healthStatus: ObservedPropertyObjectPU<boolean[]>;
    get healthStatus() {
        return this.__healthStatus.get();
    }
    set healthStatus(newValue: boolean[]) {
        this.__healthStatus.set(newValue);
    }
    private __isDarkMode: ObservedPropertyAbstractPU<boolean>;
    get isDarkMode() {
        return this.__isDarkMode.get();
    }
    set isDarkMode(newValue: boolean) {
        this.__isDarkMode.set(newValue);
    }
    aboutToAppear(): void {
        this.domains = AppData.jmDomains;
        const idx = AppData.jmDomainIndex;
        if (idx >= 0 && idx < this.domains.length) {
            this.currentDomain = this.domains[idx];
        }
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/settings/JmSettings.ets(30:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(ThemeManager.colors.background);
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/settings/JmSettings.ets(31:7)", "entry");
            Row.width('100%');
            Row.height(56);
            Row.padding({ left: 16, right: 16 });
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('<');
            Text.debugLine("entry/src/main/ets/pages/settings/JmSettings.ets(32:9)", "entry");
            Text.fontSize(20);
            Text.fontColor(ThemeManager.colors.primary);
            Text.onClick(() => { router.back(); });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('JM ' + Translations.t('jm_domain_update'));
            Text.debugLine("entry/src/main/ets/pages/settings/JmSettings.ets(34:9)", "entry");
            Text.fontSize(18);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(ThemeManager.colors.textPrimary);
            Text.margin({ left: 16 });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/settings/JmSettings.ets(39:7)", "entry");
            Scroll.layoutWeight(1);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/settings/JmSettings.ets(40:9)", "entry");
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Current domain
            Text.create('当前域名');
            Text.debugLine("entry/src/main/ets/pages/settings/JmSettings.ets(42:11)", "entry");
            // Current domain
            Text.fontSize(13);
            // Current domain
            Text.fontColor(ThemeManager.colors.textSecondary);
            // Current domain
            Text.width('100%');
            // Current domain
            Text.padding({ left: 16, top: 56, bottom: 8 });
        }, Text);
        // Current domain
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(this.currentDomain);
            Text.debugLine("entry/src/main/ets/pages/settings/JmSettings.ets(44:11)", "entry");
            Text.fontSize(15);
            Text.fontColor(ThemeManager.colors.textPrimary);
            Text.width('100%');
            Text.padding({ left: 16, bottom: 16 });
        }, Text);
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Domain list
            Text.create('可用域名');
            Text.debugLine("entry/src/main/ets/pages/settings/JmSettings.ets(48:11)", "entry");
            // Domain list
            Text.fontSize(13);
            // Domain list
            Text.fontColor(ThemeManager.colors.textSecondary);
            // Domain list
            Text.width('100%');
            // Domain list
            Text.padding({ left: 16, top: 8, bottom: 8 });
        }, Text);
        // Domain list
        Text.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            ForEach.create();
            const forEachItemGenFunction = (_item, index: number) => {
                const domain = _item;
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Row.create();
                    Row.debugLine("entry/src/main/ets/pages/settings/JmSettings.ets(52:13)", "entry");
                    Row.width('100%');
                    Row.height(56);
                    Row.padding({ left: 16, right: 16 });
                    Row.backgroundColor(ThemeManager.colors.surface);
                    Row.border({ width: { bottom: 0.5 }, color: ThemeManager.colors.divider });
                    Row.onClick(() => {
                        AppData.jmDomainIndex = index;
                        this.currentDomain = domain;
                    });
                }, Row);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Column.create();
                    Column.debugLine("entry/src/main/ets/pages/settings/JmSettings.ets(53:15)", "entry");
                    Column.alignItems(HorizontalAlign.Start);
                    Column.layoutWeight(1);
                }, Column);
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    Text.create(domain);
                    Text.debugLine("entry/src/main/ets/pages/settings/JmSettings.ets(54:17)", "entry");
                    Text.fontSize(14);
                    Text.fontColor(domain === this.currentDomain ? ThemeManager.colors.primary : ThemeManager.colors.textPrimary);
                }, Text);
                Text.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    If.create();
                    if (index < this.healthStatus.length && this.healthStatus[index]) {
                        this.ifElseBranchUpdateFunction(0, () => {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create('✓ 可用');
                                Text.debugLine("entry/src/main/ets/pages/settings/JmSettings.ets(57:19)", "entry");
                                Text.fontSize(11);
                                Text.fontColor('#34C759');
                            }, Text);
                            Text.pop();
                        });
                    }
                    else if (index < this.healthStatus.length && !this.healthStatus[index]) {
                        this.ifElseBranchUpdateFunction(1, () => {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create('✗ 不可用');
                                Text.debugLine("entry/src/main/ets/pages/settings/JmSettings.ets(59:19)", "entry");
                                Text.fontSize(11);
                                Text.fontColor('#FF3B30');
                            }, Text);
                            Text.pop();
                        });
                    }
                    else {
                        this.ifElseBranchUpdateFunction(2, () => {
                        });
                    }
                }, If);
                If.pop();
                Column.pop();
                this.observeComponentCreation2((elmtId, isInitialRender) => {
                    If.create();
                    if (domain === this.currentDomain) {
                        this.ifElseBranchUpdateFunction(0, () => {
                            this.observeComponentCreation2((elmtId, isInitialRender) => {
                                Text.create('●');
                                Text.debugLine("entry/src/main/ets/pages/settings/JmSettings.ets(64:17)", "entry");
                                Text.fontSize(16);
                                Text.fontColor(ThemeManager.colors.primary);
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
            this.forEachUpdateFunction(elmtId, this.domains, forEachItemGenFunction, undefined, true, false);
        }, ForEach);
        ForEach.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Health check button
            Button.createWithLabel(this.isChecking ? '检查中...' : '检查域名健康状态');
            Button.debugLine("entry/src/main/ets/pages/settings/JmSettings.ets(77:11)", "entry");
            // Health check button
            Button.width('90%');
            // Health check button
            Button.height(44);
            // Health check button
            Button.margin({ top: 24 });
            // Health check button
            Button.fontSize(14);
            // Health check button
            Button.fontColor('#FFFFFF');
            // Health check button
            Button.backgroundColor(this.isChecking ? '#999999' : ThemeManager.colors.primary);
            // Health check button
            Button.onClick(() => { this.checkHealth(); });
        }, Button);
        // Health check button
        Button.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Refresh from remote
            Button.createWithLabel('从远程更新域名列表');
            Button.debugLine("entry/src/main/ets/pages/settings/JmSettings.ets(84:11)", "entry");
            // Refresh from remote
            Button.width('90%');
            // Refresh from remote
            Button.height(44);
            // Refresh from remote
            Button.margin({ top: 12 });
            // Refresh from remote
            Button.fontSize(14);
            // Refresh from remote
            Button.fontColor('#FFFFFF');
            // Refresh from remote
            Button.backgroundColor('#FF9500');
            // Refresh from remote
            Button.onClick(() => { this.refreshDomains(); });
        }, Button);
        // Refresh from remote
        Button.pop();
        Column.pop();
        Scroll.pop();
        Column.pop();
    }
    private async checkHealth(): Promise<void> {
        this.isChecking = true;
        this.healthStatus = [];
        for (let i = 0; i < this.domains.length; i++) {
            const domain = this.domains[i];
            const url = `https://${domain}`;
            const ok = await Network.headCheck(url, 5000);
            this.healthStatus.push(ok);
        }
        this.isChecking = false;
        Logger.info(TAG, `Health check done: ${this.healthStatus.join(', ')}`);
    }
    private async refreshDomains(): Promise<void> {
        Logger.info(TAG, 'Refreshing JM domains from remote...');
        for (const url of ApiConstants.JM_DOMAIN_URLS) {
            const data = await Network.get(url);
            if (data.length > 0) {
                Logger.info(TAG, `Got domain data from ${url}`);
                break;
            }
        }
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "JmSettings";
    }
}
registerNamedRoute(() => new JmSettings(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/settings/JmSettings", pageFullPath: "entry/src/main/ets/pages/settings/JmSettings", integratedHsp: "false", moduleType: "followWithHap" });
