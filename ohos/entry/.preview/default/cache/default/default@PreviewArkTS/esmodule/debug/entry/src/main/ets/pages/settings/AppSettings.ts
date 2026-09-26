if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface AppSettings_Params {
    isDarkMode?: boolean;
}
import router from "@ohos:router";
import { SettingItem } from "@bundle:com.picacomic.harmony/entry/ets/components/SettingItem";
import { SettingSection } from "@bundle:com.picacomic.harmony/entry/ets/components/SettingSection";
import { ApiConstants } from "@bundle:com.picacomic.harmony/entry/ets/common/Constants";
class AppSettings extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: AppSettings_Params) {
    }
    updateStateVars(params: AppSettings_Params) {
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
            Column.debugLine("entry/src/main/ets/pages/settings/AppSettings.ets(14:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(this.isDarkMode ? '#000000' : '#F5F5F5');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/settings/AppSettings.ets(15:7)", "entry");
            Row.width('100%');
            Row.height(64);
            Row.padding({ left: 16, right: 16 });
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 0, "type": 30000, params: ['icons/ic_back.svg'], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Image.debugLine("entry/src/main/ets/pages/settings/AppSettings.ets(16:9)", "entry");
            Image.width(24);
            Image.height(24);
            Image.objectFit(ImageFit.Contain);
            Image.onClick(() => { router.back(); });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create('APP 设置');
            Text.debugLine("entry/src/main/ets/pages/settings/AppSettings.ets(19:9)", "entry");
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : '#000000');
            Text.margin({ left: 12 });
        }, Text);
        Text.pop();
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/settings/AppSettings.ets(26:7)", "entry");
            Scroll.layoutWeight(1);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/settings/AppSettings.ets(27:9)", "entry");
            Column.width('100%');
        }, Column);
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSection(this, { title: '数据' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/AppSettings.ets", line: 28, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '数据'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '数据'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📂', title: '下载路径', value: '默认存储', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/AppSettings.ets", line: 29, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📂',
                            title: '下载路径',
                            value: '默认存储',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📂', title: '下载路径', value: '默认存储'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '💾', title: '缓存大小', value: '0 MB', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/AppSettings.ets", line: 30, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '💾',
                            title: '缓存大小',
                            value: '0 MB',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '💾', title: '缓存大小', value: '0 MB'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🗑️', title: '清除缓存', value: '', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/AppSettings.ets", line: 31, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🗑️',
                            title: '清除缓存',
                            value: '',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🗑️', title: '清除缓存', value: ''
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📊', title: '缓存限制', value: '1000', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/AppSettings.ets", line: 32, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📊',
                            title: '缓存限制',
                            value: '1000',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📊', title: '缓存限制', value: '1000'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSection(this, { title: '更新' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/AppSettings.ets", line: 34, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '更新'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '更新'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🔄', title: '检查更新', value: 'v' + ApiConstants.APP_VERSION, onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/AppSettings.ets", line: 35, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🔄',
                            title: '检查更新',
                            value: 'v' + ApiConstants.APP_VERSION,
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🔄', title: '检查更新', value: 'v' + ApiConstants.APP_VERSION
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📜', title: '历史版本', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/AppSettings.ets", line: 36, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📜',
                            title: '历史版本',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📜', title: '历史版本'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingSection(this, { title: '数据管理' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/AppSettings.ets", line: 38, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '数据管理'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '数据管理'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📤', title: '导出数据', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/AppSettings.ets", line: 39, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📤',
                            title: '导出数据',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📤', title: '导出数据'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📥', title: '导入数据', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/AppSettings.ets", line: 40, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📥',
                            title: '导入数据',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📥', title: '导入数据'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '⚠️', title: '删除所有数据', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/AppSettings.ets", line: 41, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '⚠️',
                            title: '删除所有数据',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '⚠️', title: '删除所有数据'
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
        return "AppSettings";
    }
}
registerNamedRoute(() => new AppSettings(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/settings/AppSettings", pageFullPath: "entry/src/main/ets/pages/settings/AppSettings", integratedHsp: "false", moduleType: "followWithHap" });
