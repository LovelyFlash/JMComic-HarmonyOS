// common/ThemeManager.ets - 主题管理

export interface ThemeColorSet {
  primary: string;
  background: string;
  surface: string;
  textPrimary: string;
  textSecondary: string;
  divider: string;
  border: string;
}

export class ThemeManager {
  private static _isDark: boolean = false;
  private static _themeColor: string = '#007AFF';

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

  static setDarkMode(dark: boolean): void {
    ThemeManager._isDark = dark;
    AppStorage.setOrCreate('isDarkMode', dark);
  }

  static setThemeColor(color: string): void {
    ThemeManager._themeColor = color;
  }

  static get colors(): ThemeColorSet {
    if (ThemeManager._isDark) {
      return {
        primary: ThemeManager._themeColor,
        background: '#000000',
        surface: '#1C1C1E',
        textPrimary: '#FFFFFF',
        textSecondary: '#8E8E93',
        divider: '#38383A',
        border: '#38383A'
      };
    }
    return {
      primary: ThemeManager._themeColor,
      background: '#FFFFFF',
      surface: '#F2F2F7',
      textPrimary: '#000000DE',
      textSecondary: '#00000073',
      divider: '#E5E5EA',
      border: '#E5E5EA'
    };
  }
}
