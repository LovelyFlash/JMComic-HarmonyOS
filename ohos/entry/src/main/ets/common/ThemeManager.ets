// common/ThemeManager.ets - 主题管理（设计令牌 + 深色模式 + 主题色）
import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { Settings } from '../data/preferences/Settings';
import { SettingsKeys } from './Constants';
import { Logger } from './Logger';

const TAG = 'ThemeManager';

export interface ThemeColorSet {
  primary: string;
  background: string;
  pageBackground: string;
  card: string;
  surface: string;
  surfaceSecondary: string;
  textPrimary: string;
  textSecondary: string;
  textTertiary: string;
  divider: string;
  border: string;
  danger: string;
  success: string;
  warning: string;
  overlay: string;
  shadow: string;
}

const LightColors: ThemeColorSet = {
  primary: '#007AFF',
  background: '#FFFFFF',
  pageBackground: '#F1F3F5',
  card: '#FFFFFF',
  surface: '#F2F2F7',
  surfaceSecondary: '#FFFFFF',
  textPrimary: '#DE000000',
  textSecondary: '#73000000',
  textTertiary: '#42000000',
  divider: '#E5E5EA',
  border: '#E5E5EA',
  danger: '#FF3B30',
  success: '#34C759',
  warning: '#FF9500',
  overlay: '#66000000',
  shadow: '#14000000'
};

const DarkColors: ThemeColorSet = {
  primary: '#0A84FF',
  background: '#000000',
  pageBackground: '#000000',
  card: '#1C1C1E',
  surface: '#1C1C1E',
  surfaceSecondary: '#2C2C2E',
  textPrimary: '#DEFFFFFF',
  textSecondary: '#73FFFFFF',
  textTertiary: '#42FFFFFF',
  divider: '#38383A',
  border: '#38383A',
  danger: '#FF453A',
  success: '#30D158',
  warning: '#FF9F0A',
  overlay: '#99000000',
  shadow: '#4D000000'
};

export class ThemeManager {
  private static _isDark: boolean = false;
  private static _themeColor: string = '#007AFF';
  private static _darkMode: string = 'system'; // 'system' | 'enabled' | 'disabled'
  private static appContext: common.ApplicationContext | null = null;

  /** 深色模式变化通知（EntryAbility 注册，用于联动系统状态栏字色） */
  static systemBarNotifier: ((dark: boolean) => void) | null = null;

  /** 绑定应用级 Context（须在窗口 loadContent 完成后调用），用于 setColorMode */
  static attachApplicationContext(ctx: common.ApplicationContext): void {
    ThemeManager.appContext = ctx;
  }

  /** 将应用级颜色模式同步到系统（弹窗/半模态/toast 等系统表面随之切换） */
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
      Logger.warn(TAG, `applyColorModeToSystem failed: ${String(e)}`);
    }
  }

  static readonly themePresets: string[] = [
    '#007AFF', '#34C759', '#FF9500', '#FF3B30', '#AF52DE',
    '#5856D6', '#FF2D55', '#00C7BE', '#FFD60A'
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

  /** 从持久化设置恢复主题（应用启动时调用） */
  static async restore(): Promise<void> {
    try {
      const darkMode = await Settings.getString(SettingsKeys.DARK_MODE, 'system');
      const themeColor = await Settings.getString(SettingsKeys.THEME_COLOR, '#007AFF');
      ThemeManager._darkMode = darkMode;
      ThemeManager._themeColor = themeColor;
      if (darkMode === 'enabled') {
        ThemeManager.setDarkMode(true);
      } else if (darkMode === 'disabled') {
        ThemeManager.setDarkMode(false);
      }
      // 'system' 时由 applySystemDark 由 EntryAbility 注入
      AppStorage.setOrCreate('themeColor', themeColor);
      Logger.info(TAG, `restored darkMode=${darkMode} themeColor=${themeColor}`);
    } catch (e) {
      Logger.error(TAG, `restore failed: ${String(e)}`);
    }
  }

  /** 设置深色模式（并持久化） */
  static async setDarkMode(dark: boolean, persistMode: string = ''): Promise<void> {
    const changed: boolean = ThemeManager._isDark !== dark;
    ThemeManager._isDark = dark;
    AppStorage.setOrCreate('isDarkMode', dark);
    // 统一递增 themeVersion：仅挂 isDarkMode 或仅挂 themeVersion 的组件都能刷新
    if (changed) {
      AppStorage.setOrCreate('themeVersion', (AppStorage.get<number>('themeVersion') ?? 0) + 1);
    }
    if (ThemeManager.systemBarNotifier !== null) {
      ThemeManager.systemBarNotifier(dark);
    }
    if (persistMode.length > 0) {
      ThemeManager._darkMode = persistMode;
      await Settings.putString(SettingsKeys.DARK_MODE, persistMode);
    }
  }

  /** 设置深色模式策略：'system' | 'enabled' | 'disabled' */
  static async setDarkModePolicy(mode: string, systemDark: boolean): Promise<void> {
    ThemeManager._darkMode = mode;
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

  /** 设置主题色（并持久化 + 同步 AppStorage） */
  static async setThemeColor(color: string): Promise<void> {
    ThemeManager._themeColor = color;
    AppStorage.setOrCreate('themeColor', color);
    // 触发重渲染
    AppStorage.setOrCreate('themeVersion', (AppStorage.get<number>('themeVersion') ?? 0) + 1);
    await Settings.putString(SettingsKeys.THEME_COLOR, color);
  }

  /** 当前主题色集合（isDark 由 AppStorage/内部状态决定） */
  static get colors(): ThemeColorSet {
    const isDark = AppStorage.get<boolean>('isDarkMode') ?? ThemeManager._isDark;
    const base = isDark ? DarkColors : LightColors;
    const primary = AppStorage.get<string>('themeColor') ?? ThemeManager._themeColor;
    return {
      primary: primary,
      background: base.background,
      pageBackground: base.pageBackground,
      card: base.card,
      surface: base.surface,
      surfaceSecondary: base.surfaceSecondary,
      textPrimary: base.textPrimary,
      textSecondary: base.textSecondary,
      textTertiary: base.textTertiary,
      divider: base.divider,
      border: base.border,
      danger: base.danger,
      success: base.success,
      warning: base.warning,
      overlay: base.overlay,
      shadow: base.shadow
    };
  }

  // —— 快捷访问（build() 内直接用，随 @StorageLink('isDarkMode') 重渲染） ——
  static get primary(): string { return ThemeManager.colors.primary; }
  static get background(): string { return ThemeManager.colors.background; }
  static get pageBackground(): string { return ThemeManager.colors.pageBackground; }
  static get card(): string { return ThemeManager.colors.card; }
  static get surface(): string { return ThemeManager.colors.surface; }
  static get surfaceSecondary(): string { return ThemeManager.colors.surfaceSecondary; }
  static get textPrimary(): string { return ThemeManager.colors.textPrimary; }
  static get textSecondary(): string { return ThemeManager.colors.textSecondary; }
  static get textTertiary(): string { return ThemeManager.colors.textTertiary; }
  static get divider(): string { return ThemeManager.colors.divider; }
  static get danger(): string { return ThemeManager.colors.danger; }
  static get success(): string { return ThemeManager.colors.success; }
}
