if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface NetworkSettings_Params {
    isDarkMode?: boolean;
    useSystemProxy?: boolean;
    enableCache?: boolean;
}
import router from "@ohos:router";
import { SettingItem } from "@bundle:com.picacomic.harmony/entry/ets/components/SettingItem";
import { SettingSwitch } from "@bundle:com.picacomic.harmony/entry/ets/components/SettingSwitch";
import { SettingSection } from "@bundle:com.picacomic.harmony/entry/ets/components/SettingSection";
class NetworkSettings extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.__useSystemProxy = new ObservedPropertySimplePU(true, this, "useSystemProxy");
        this.__enableCache = new ObservedPropertySimplePU(true, this, "enableCache");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: NetworkSettings_Params) {
        if (params.useSystemProxy !== undefined) {
            this.useSystemProxy = params.useSystemProxy;
        }
        if (params.enableCache !== undefined) {
            this.enableCache = params.enableCache;
        }
    }
    updateStateVars(params: NetworkSettings_Params) {
    }
    purgeVariableDependenciesOnElmtId(rmElmtId) {
        this.__isDarkMode.purgeDependencyOnElmtId(rmElmtId);
        this.__useSystemProxy.purgeDependencyOnElmtId(rmElmtId);
        this.__enableCache.purgeDependencyOnElmtId(rmElmtId);
    }
    aboutToBeDeleted() {
        this.__isDarkMode.aboutToBeDeleted();
        this.__useSystemProxy.aboutToBeDeleted();
        this.__enableCache.aboutToBeDeleted();
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
    private __useSystemProxy: ObservedPropertySimplePU<boolean>;
    get useSystemProxy() {
        return this.__useSystemProxy.get();
    }
    set useSystemProxy(newValue: boolean) {
        this.__useSystemProxy.set(newValue);
    }
    private __enableCache: ObservedPropertySimplePU<boolean>;
    get enableCache() {
        return this.__enableCache.get();
    }
    set enableCache(newValue: boolean) {
        this.__enableCache.set(newValue);
    }
    initialRender() {
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/settings/NetworkSettings.ets(16:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(this.isDarkMode ? '#000000' : '#F5F5F5');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/settings/NetworkSettings.ets(17:7)", "entry");
            Row.width('100%');
            Row.height(64);
            Row.padding({ left: 16, right: 16 });
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 0, "type": 30000, params: ['icons/ic_back.svg'], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Image.debugLine("entry/src/main/ets/pages/settings/NetworkSettings.ets(18:9)", "entry");
            Image.width(24);
            Image.height(24);
            Image.objectFit(ImageFit.Contain);
            Image.onClick(() => { router.back(); });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('网络设置');
            Text.debugLine("entry/src/main/ets/pages/settings/NetworkSettings.ets(21:9)", "entry");
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : '#000000');
            Text.margin({ left: 12 });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/settings/NetworkSettings.ets(28:7)", "entry");
            Scroll.layoutWeight(1);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/settings/NetworkSettings.ets(29:9)", "entry");
            Column.width('100%');
        }, Column);
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSection(this, { title: '代理' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/NetworkSettings.ets", line: 30, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '代理'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '代理'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSwitch(this, { icon: '🌐', title: '使用系统代理', isOn: this.useSystemProxy, onToggle: (v: boolean) => { this.useSystemProxy = v; } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/NetworkSettings.ets", line: 31, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🌐',
                            title: '使用系统代理',
                            isOn: this.useSystemProxy,
                            onToggle: (v: boolean) => { this.useSystemProxy = v; }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🌐', title: '使用系统代理', isOn: this.useSystemProxy
                    });
                }
            }, { name: "SettingSwitch" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🔗', title: '自定义代理', value: '未配置', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/NetworkSettings.ets", line: 32, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🔗',
                            title: '自定义代理',
                            value: '未配置',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🔗', title: '自定义代理', value: '未配置'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSection(this, { title: '缓存' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/NetworkSettings.ets", line: 34, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '缓存'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '缓存'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSwitch(this, { icon: '💾', title: '启用网络缓存', isOn: this.enableCache, onToggle: (v: boolean) => { this.enableCache = v; } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/NetworkSettings.ets", line: 35, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '💾',
                            title: '启用网络缓存',
                            isOn: this.enableCache,
                            onToggle: (v: boolean) => { this.enableCache = v; }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '💾', title: '启用网络缓存', isOn: this.enableCache
                    });
                }
            }, { name: "SettingSwitch" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '⏱️', title: '缓存超时', value: '5 分钟', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/NetworkSettings.ets", line: 36, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '⏱️',
                            title: '缓存超时',
                            value: '5 分钟',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '⏱️', title: '缓存超时', value: '5 分钟'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSection(this, { title: 'WebDAV 同步' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/NetworkSettings.ets", line: 38, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: 'WebDAV 同步'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: 'WebDAV 同步'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '☁️', title: 'WebDAV 服务器', value: '未配置', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/NetworkSettings.ets", line: 39, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '☁️',
                            title: 'WebDAV 服务器',
                            value: '未配置',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '☁️', title: 'WebDAV 服务器', value: '未配置'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🔄', title: '立即同步', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/NetworkSettings.ets", line: 40, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🔄',
                            title: '立即同步',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🔄', title: '立即同步'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📊', title: '同步状态', value: '上次同步: 无', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/NetworkSettings.ets", line: 41, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📊',
                            title: '同步状态',
                            value: '上次同步: 无',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📊', title: '同步状态', value: '上次同步: 无'
                    });
                }
            }, { name: "SettingItem" });
        }
        Column.pop();
        Scroll.pop();
        Column.pop();
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "NetworkSettings";
    }
}
registerNamedRoute(() => new NetworkSettings(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/settings/NetworkSettings", pageFullPath: "entry/src/main/ets/pages/settings/NetworkSettings", integratedHsp: "false", moduleType: "followWithHap" });
