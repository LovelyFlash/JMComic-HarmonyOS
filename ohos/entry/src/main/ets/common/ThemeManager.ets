// common/ThemeManager.ets - 主题管理（深色策略 + 主题色）
// 颜色一律通过 $r('app.color.*') 资源令牌（base/dark 目录）引用，深浅切换由系统自动完成；
// 本类只管理：深色策略（跟随系统/强制深色/强制浅色）、用户主题色、系统表面（状态栏/窗口底色）。
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { Settings } from '../data/preferences/Settings';
import { SettingsKeys, DEFAULT_THEME_COLOR } from './Constants';
import { Logger } from './Logger';

const TAG = 'ThemeManager';

export class ThemeManager {
  private static _isDark: boolean = false;
  private static _themeColor: string = DEFAULT_THEME_COLOR;
  private static _darkMode: string = 'system'; // 'system' | 'enabled' | 'disabled'
  private static appContext: common.ApplicationContext | null = null;

  /** 深色模式变化通知（EntryAbility 注册，用于联动系统状态栏字色） */
  static systemBarNotifier: ((dark: boolean) => void) | null = null;

  /** 绑定应用级 Context（用于 setColorMode），应在 loadContent 前调用 */
  static attachApplicationContext(ctx: common.ApplicationContext): void {
    ThemeManager.appContext = ctx;
  }

  /** 将应用级颜色模式同步到系统（弹窗/半模态/toast 等系统表面随之切换，$r 资源同步生效） */
  static applyColorModeToSystem(): void {
    if (ThemeManager.appContext === null) {
      return;
    }
    try {
      if (ThemeManager._darkMode === 'enabled') {
        ThemeManager.appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
      } else if (ThemeManager._darkMode === 'disabled') {
        ThemeManager.appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
      } else {
        // system：恢复跟随系统
        ThemeManager.appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      }
      // setColorMode 可能重置系统栏样式，联动刷新状态栏字色
      if (ThemeManager.systemBarNotifier !== null) {
        ThemeManager.systemBarNotifier(ThemeManager._isDark);
      }
    } catch (e) {
      Logger.warn(TAG, `applyColorModeToSystem failed: ${Logger.describe(e)}`);
    }
  }

  /** 预设主题色（与 base/dark 色板同一色系） */
  static readonly themePresets: string[] = [
    '#2563EB', '#16A34A', '#EA580C', '#DC2626', '#9333EA',
    '#4F46E5', '#DB2777', '#0D9488', '#D97706'
  ];

  static get isDark(): boolean {
    return ThemeManager._isDark;
  }

  static get themeColor(): string {
    return ThemeManager._themeColor;
  }

  static get darkMode(): string {
    return ThemeManager._darkMode;
  }

  /** 系统 API（setWindowBackgroundColor）只接受具体色值字符串，UI 层禁用此接口 */
  static get windowBackground(): string {
    return ThemeManager._isDark ? '#111827' : '#F8F9FA';
  }

  /** 从持久化设置恢复主题（应用启动时调用） */
  static async restore(): Promise<void> {
    try {
      const darkMode = await Settings.getString(SettingsKeys.DARK_MODE, 'system');
      const themeColor = await Settings.getString(SettingsKeys.THEME_COLOR, DEFAULT_THEME_COLOR);
      ThemeManager._darkMode = darkMode;
      ThemeManager._themeColor = themeColor;
      if (darkMode === 'enabled') {
        ThemeManager.setDarkMode(true);
      } else if (darkMode === 'disabled') {
        ThemeManager.setDarkMode(false);
      }
      // 'system' 时由 applySystemDark 由 EntryAbility 注入
      AppStorage.setOrCreate('themeColor', themeColor);
      AppStorage.setOrCreate('darkModePolicy', darkMode);
      Logger.info(TAG, `restored darkMode=${darkMode} themeColor=${themeColor}`);
    } catch (e) {
      Logger.error(TAG, `restore failed: ${Logger.describe(e)}`);
    }
  }

  /** 设置深色生效状态（资源目录自动切换，无需刷新 UI 状态） */
  static setDarkMode(dark: boolean, persistMode: string = ''): void {
    ThemeManager._isDark = dark;
    AppStorage.setOrCreate('isDarkMode', dark);
    if (ThemeManager.systemBarNotifier !== null) {
      ThemeManager.systemBarNotifier(dark);
    }
    if (persistMode.length > 0) {
      ThemeManager._darkMode = persistMode;
    }
  }

  /** 设置深色模式策略：'system' | 'enabled' | 'disabled' */
  static async setDarkModePolicy(mode: string, systemDark: boolean): Promise<void> {
    ThemeManager._darkMode = mode;
    AppStorage.setOrCreate('darkModePolicy', mode);
    await Settings.putString(SettingsKeys.DARK_MODE, mode);
    if (mode === 'enabled') {
      ThemeManager.setDarkMode(true);
    } else if (mode === 'disabled') {
      ThemeManager.setDarkMode(false);
    } else {
      // system 模式：使用传入的系统状态
      ThemeManager.setDarkMode(systemDark);
    }
    ThemeManager.applyColorModeToSystem();
  }

  /** 系统深色模式变化时调用（仅 policy=system 生效） */
  static applySystemDark(systemDark: boolean): void {
    if (ThemeManager._darkMode === 'system') {
      ThemeManager.setDarkMode(systemDark);
    }
  }

  /** 设置主题色（并持久化 + 同步 AppStorage，组件经 @StorageProp('themeColor') 响应） */
  static async setThemeColor(color: string): Promise<void> {
    ThemeManager._themeColor = color;
    AppStorage.setOrCreate('themeColor', color);
    await Settings.putString(SettingsKeys.THEME_COLOR, color);
  }
}
