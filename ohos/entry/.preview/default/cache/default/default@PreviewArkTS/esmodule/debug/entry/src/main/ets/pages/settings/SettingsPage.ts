if (!("finalizeConstruction" in ViewPU.prototype)) {
    Reflect.set(ViewPU.prototype, "finalizeConstruction", () => { });
}
interface SettingsPage_Params {
    isDarkMode?: boolean;
}
import router from "@ohos:router";
import { ThemeManager } from "@bundle:com.picacomic.harmony/entry/ets/common/ThemeManager";
import { Translations } from "@bundle:com.picacomic.harmony/entry/ets/common/Translations";
import { SettingItem } from "@bundle:com.picacomic.harmony/entry/ets/components/SettingItem";
import { SettingSection } from "@bundle:com.picacomic.harmony/entry/ets/components/SettingSection";
class SettingsPage extends ViewPU {
    constructor(parent, params, __localStorage, elmtId = -1, paramsLambda = undefined, extraInfo) {
        super(parent, __localStorage, elmtId, extraInfo);
        if (typeof paramsLambda === "function") {
            this.paramsGenerator_ = paramsLambda;
        }
        this.__isDarkMode = this.createStorageLink('isDarkMode', false, "isDarkMode");
        this.setInitiallyProvidedValue(params);
        this.finalizeConstruction();
    }
    setInitiallyProvidedValue(params: SettingsPage_Params) {
    }
    updateStateVars(params: SettingsPage_Params) {
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
            Column.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(14:5)", "entry");
            Column.width('100%');
            Column.height('100%');
            Column.backgroundColor(this.isDarkMode ? '#000000' : '#F5F5F5');
        }, Column);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            // Header
            Row.create();
            Row.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(16:7)", "entry");
            // Header
            Row.width('100%');
            // Header
            Row.height(64);
            // Header
            Row.padding({ left: 16, right: 16 });
            // Header
            Row.alignItems(VerticalAlign.Center);
        }, Row);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Image.create({ "id": 0, "type": 30000, params: ['icons/ic_back.svg'], "bundleName": "com.picacomic.harmony", "moduleName": "entry" });
            Image.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(17:9)", "entry");
            Image.width(24);
            Image.height(24);
            Image.objectFit(ImageFit.Contain);
            Image.onClick(() => { router.back(); });
        }, Image);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Text.create(Translations.t('tab_settings'));
            Text.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(20:9)", "entry");
            Text.fontSize(22);
            Text.fontWeight(FontWeight.Bold);
            Text.fontColor(this.isDarkMode ? '#FFFFFF' : '#000000');
            Text.margin({ left: 12 });
        }, Text);
        Text.pop();
        // Header
        Row.pop();
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Scroll.create();
            Scroll.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(30:7)", "entry");
            Scroll.layoutWeight(1);
        }, Scroll);
        this.observeComponentCreation2((elmtId, isInitialRender) => {
            Column.create();
            Column.debugLine("entry/src/main/ets/pages/settings/SettingsPage.ets(31:9)", "entry");
            Column.width('100%');
        }, Column);
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new 
                    // === 浏览 ===
                    SettingSection(this, { title: '浏览' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 33, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '浏览'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '浏览'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🔍', title: '初始页面', value: '主页', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 34, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🔍',
                            title: '初始页面',
                            value: '主页',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🔍', title: '初始页面', value: '主页'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📋', title: '探索页面配置', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 35, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📋',
                            title: '探索页面配置',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📋', title: '探索页面配置'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🚫', title: '关键词屏蔽', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 36, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🚫',
                            title: '关键词屏蔽',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🚫', title: '关键词屏蔽'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🔎', title: '默认搜索源', value: 'NHentai', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 37, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🔎',
                            title: '默认搜索源',
                            value: 'NHentai',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🔎', title: '默认搜索源', value: 'NHentai'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📱', title: '漫画列表显示', value: '连续模式', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 38, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📱',
                            title: '漫画列表显示',
                            value: '连续模式',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📱', title: '漫画列表显示', value: '连续模式'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new 
                    // === 阅读 ===
                    SettingSection(this, { title: '阅读' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 41, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '阅读'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '阅读'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📖', title: '阅读模式', value: '从上至下', onTap: () => {
                            router.pushUrl({ url: 'pages/settings/ReadingSettings' });
                        } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 42, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📖',
                            title: '阅读模式',
                            value: '从上至下',
                            onTap: () => {
                                router.pushUrl({ url: 'pages/settings/ReadingSettings' });
                            }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📖', title: '阅读模式', value: '从上至下'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '👆', title: '点按翻页', value: 'ON', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 45, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '👆',
                            title: '点按翻页',
                            value: 'ON',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '👆', title: '点按翻页', value: 'ON'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🔊', title: '音量键翻页', value: 'ON', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 46, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🔊',
                            title: '音量键翻页',
                            value: 'ON',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🔊', title: '音量键翻页', value: 'ON'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🔆', title: '屏幕常亮', value: 'ON', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 47, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🔆',
                            title: '屏幕常亮',
                            value: 'ON',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🔆', title: '屏幕常亮', value: 'ON'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📝', title: '显示章节评论', value: 'ON', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 48, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📝',
                            title: '显示章节评论',
                            value: 'ON',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📝', title: '显示章节评论', value: 'ON'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '💾', title: '图片质量', value: 'Original', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 49, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '💾',
                            title: '图片质量',
                            value: 'Original',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '💾', title: '图片质量', value: 'Original'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🔤', title: '字体大小', value: '16', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 50, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🔤',
                            title: '字体大小',
                            value: '16',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🔤', title: '字体大小', value: '16'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new 
                    // === 外观 ===
                    SettingSection(this, { title: '外观' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 53, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '外观'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '外观'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🌙', title: Translations.t('dark_mode'), value: this.getDarkModeLabel(), onTap: () => {
                            this.cycleDarkMode();
                        } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 54, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🌙',
                            title: Translations.t('dark_mode'),
                            value: this.getDarkModeLabel(),
                            onTap: () => {
                                this.cycleDarkMode();
                            }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🌙', title: Translations.t('dark_mode'), value: this.getDarkModeLabel()
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🎨', title: Translations.t('theme_color'), value: '', onTap: () => {
                            this.cycleThemeColor();
                        } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 57, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🎨',
                            title: Translations.t('theme_color'),
                            value: '',
                            onTap: () => {
                                this.cycleThemeColor();
                            }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🎨', title: Translations.t('theme_color'), value: ''
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new 
                    // === 本地收藏 ===
                    SettingSection(this, { title: '本地收藏' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 62, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '本地收藏'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '本地收藏'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '⭐', title: '收藏夹设置', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 63, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '⭐',
                            title: '收藏夹设置',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '⭐', title: '收藏夹设置'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new 
                    // === APP ===
                    SettingSection(this, { title: 'APP' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 66, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: 'APP'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: 'APP'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📂', title: '下载路径', value: '默认', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 67, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📂',
                            title: '下载路径',
                            value: '默认',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📂', title: '下载路径', value: '默认'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🗑️', title: '清除缓存', value: '', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 68, col: 11 });
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
                    let componentCall = new SettingItem(this, { icon: '🔄', title: '检查更新', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 69, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🔄',
                            title: '检查更新',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🔄', title: '检查更新'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new 
                    // === 漫画源 ===
                    SettingSection(this, { title: '漫画源' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 72, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '漫画源'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '漫画源'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📕', title: 'JM 禁漫', value: '→', onTap: () => {
                            router.pushUrl({ url: 'pages/settings/JmSettings' });
                        } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 73, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📕',
                            title: 'JM 禁漫',
                            value: '→',
                            onTap: () => {
                                router.pushUrl({ url: 'pages/settings/JmSettings' });
                            }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📕', title: 'JM 禁漫', value: '→'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📚', title: 'HT 绅士漫画', value: '→', onTap: () => {
                            router.pushUrl({ url: 'pages/settings/HtSettings' });
                        } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 76, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📚',
                            title: 'HT 绅士漫画',
                            value: '→',
                            onTap: () => {
                                router.pushUrl({ url: 'pages/settings/HtSettings' });
                            }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📚', title: 'HT 绅士漫画', value: '→'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📘', title: 'NHentai 设置', value: '→', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 79, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📘',
                            title: 'NHentai 设置',
                            value: '→',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📘', title: 'NHentai 设置', value: '→'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '📖', title: 'EHentai 设置', value: '→', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 80, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '📖',
                            title: 'EHentai 设置',
                            value: '→',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '📖', title: 'EHentai 设置', value: '→'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🐱', title: 'Picacg 设置', value: '→', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 81, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🐱',
                            title: 'Picacg 设置',
                            value: '→',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🐱', title: 'Picacg 设置', value: '→'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🎨', title: 'Hitomi 设置', value: '→', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 82, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🎨',
                            title: 'Hitomi 设置',
                            value: '→',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🎨', title: 'Hitomi 设置', value: '→'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new 
                    // === 网络 ===
                    SettingSection(this, { title: '网络' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 85, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '网络'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '网络'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '🌐', title: '代理设置', value: '系统代理', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 86, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '🌐',
                            title: '代理设置',
                            value: '系统代理',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '🌐', title: '代理设置', value: '系统代理'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: '☁️', title: 'WebDAV 同步', value: '未配置', onTap: () => { } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 87, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: '☁️',
                            title: 'WebDAV 同步',
                            value: '未配置',
                            onTap: () => { }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: '☁️', title: 'WebDAV 同步', value: '未配置'
                    });
                }
            }, { name: "SettingItem" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new 
                    // === 关于 ===
                    SettingSection(this, { title: '关于' }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 90, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            title: '关于'
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        title: '关于'
                    });
                }
            }, { name: "SettingSection" });
        }
        {
            this.observeComponentCreation2((elmtId, isInitialRender) => {
                if (isInitialRender) {
                    let componentCall = new SettingItem(this, { icon: 'ℹ️', title: Translations.t('about'), value: 'v' + '1.0.0', onTap: () => {
                            router.pushUrl({ url: 'pages/settings/AboutPage' });
                        } }, undefined, elmtId, () => { }, { page: "entry/src/main/ets/pages/settings/SettingsPage.ets", line: 91, col: 11 });
                    ViewPU.create(componentCall);
                    let paramsLambda = () => {
                        return {
                            icon: 'ℹ️',
                            title: Translations.t('about'),
                            value: 'v' + '1.0.0',
                            onTap: () => {
                                router.pushUrl({ url: 'pages/settings/AboutPage' });
                            }
                        };
                    };
                    componentCall.paramsGenerator_ = paramsLambda;
                }
                else {
                    this.updateStateVarsOfChildByElmtId(elmtId, {
                        icon: 'ℹ️', title: Translations.t('about'), value: 'v' + '1.0.0'
                    });
                }
            }, { name: "SettingItem" });
        }
        Column.pop();
        Scroll.pop();
        Column.pop();
    }
    private getDarkModeLabel(): string {
        return ThemeManager.isDark ? '开启' : '关闭';
    }
    private cycleDarkMode(): void {
        ThemeManager.setDarkMode(!ThemeManager.isDark);
    }
    private cycleThemeColor(): void {
        const colors = ThemeManager.themePresets;
        const current = ThemeManager.themeColor;
        let idx = 0;
        for (let i = 0; i < colors.length; i++) {
            if (colors[i] === current) {
                idx = i;
                break;
            }
        }
        ThemeManager.setThemeColor(colors[(idx + 1) % colors.length]);
    }
    rerender() {
        this.updateDirtyElements();
    }
    static getEntryName(): string {
        return "SettingsPage";
    }
}
registerNamedRoute(() => new SettingsPage(undefined, {}), "", { bundleName: "com.picacomic.harmony", moduleName: "entry", pagePath: "pages/settings/SettingsPage", pageFullPath: "entry/src/main/ets/pages/settings/SettingsPage", integratedHsp: "false", moduleType: "followWithHap" });
