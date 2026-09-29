// pages/settings/SettingsPage.ets - 设置主页（深色/主题色选择器 + 子设置）- NavDestination
import { ThemeManager } from '../../common/ThemeManager';
import { Translations } from '../../common/Translations';
import { NavUtil } from '../../common/NavUtil';
import { SettingItem } from '../../components/SettingItem';
import { SettingsGroup } from '../../components/SettingsGroup';
import { SettingOptions } from '../../components/SettingOptions';
import { NavTitleBar } from '../../components/NavTitleBar';

@Builder
export function SettingsPageBuilder(name: string, param: object) {
  SettingsPage()
}

@Component
export struct SettingsPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @StorageLink('themeVersion') themeVersion: number = 0
  @State showColorSheet: boolean = false
  @State title: string = '设置'

  private darkModeIndex(): number {
    const mode = ThemeManager.darkMode;
    if (mode === 'enabled') {
      return 1;
    }
    if (mode === 'disabled') {
      return 2;
    }
    return 0;
  }

  private setDarkMode(mode: string): void {
    if (mode === 'system') {
      const isSysDark = AppStorage.get<boolean>('systemIsDark') ?? false;
      ThemeManager.setDarkModePolicy('system', isSysDark);
    } else if (mode === 'enabled') {
      ThemeManager.setDarkModePolicy('enabled', false);
    } else {
      ThemeManager.setDarkModePolicy('disabled', false);
    }
  }

  @Builder
  colorSheetContent() {
    ForEach([this.themeVersion], (v: number) => {
      Column({ space: 16 }) {
        Text(Translations.t('select_theme_color'))
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(ThemeManager.textPrimary)
          .width('100%')
          .padding({ left: 20, top: 8 })
        Grid() {
          ForEach(ThemeManager.themePresets, (color: string) => {
            GridItem() {
              Column() {
                if (ThemeManager.themeColor === color) {
                  SymbolGlyph($r('sys.symbol.checkmark'))
                    .fontSize(20)
                    .fontColor(['#FFFFFF'])
                }
              }
              .width(44).height(44)
              .borderRadius(22)
              .backgroundColor(color)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                ThemeManager.setThemeColor(color);
                this.showColorSheet = false;
              })
            }
          }, (color: string) => color)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(16)
        .rowsGap(16)
        .width('100%')
        .height(168)
        .padding({ left: 20, right: 20 })
      }
      .width('100%')
      .padding({ bottom: 32 })
      .id('colorSheet')
    }, (v: number) => `theme-${v}`)
  }

  build() {
    NavDestination() {
      ForEach([this.themeVersion], (v: number) => {
        Column() {
          Scroll() {
            Column({ space: 0 }) {
              SettingsGroup({ title: Translations.t('settings_appearance') }) {
                SettingOptions({
                  label: Translations.t('dark_mode'),
                  options: [Translations.t('dark_mode_system'), Translations.t('dark_mode_dark'), Translations.t('dark_mode_light')],
                  selectedIndex: this.darkModeIndex(),
                  onSelect: (index: number) => {
                    if (index === 0) {
                      this.setDarkMode('system');
                    } else if (index === 1) {
                      this.setDarkMode('enabled');
                    } else {
                      this.setDarkMode('disabled');
                    }
                  }
                })
                SettingItem({
                  icon: $r('sys.symbol.brightness'),
                  title: Translations.t('theme_color'),
                  showDivider: false,
                  onTap: () => {
                    this.showColorSheet = true;
                  }
                })
              }
              SettingsGroup({ title: Translations.t('settings_reading') }) {
                SettingItem({
                  icon: $r('sys.symbol.list_bullet'),
                  title: Translations.t('reading_settings'),
                  showDivider: false,
                  onTap: () => {
                    NavUtil.push('readingSettings');
                  }
                })
              }
              SettingsGroup({ title: Translations.t('settings_comic_source') }) {
                SettingItem({
                  icon: $r('sys.symbol.arrow_clockwise'),
                  title: Translations.t('jm_name'),
                  showDivider: false,
                  onTap: () => {
                    NavUtil.push('jmSettings');
                  }
                })
              }
              SettingsGroup({ title: Translations.t('settings_system') }) {
                SettingItem({
                  icon: $r('sys.symbol.questionmark_circle'),
                  title: Translations.t('about'),
                  value: 'v1.0.0',
                  showDivider: false,
                  onTap: () => {
                    NavUtil.push('about');
                  }
                })
              }
            }
            .width('100%')
            .padding({ bottom: 24 })
          }
          .width('100%').layoutWeight(1)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .width('100%').height('100%')
      }, (v: number) => `theme-${v}`)
    }
    .hideTitleBar(true)
    .backgroundColor(this.themeVersion >= 0 ? ThemeManager.pageBackground : '')
    .bindSheet($$this.showColorSheet, this.colorSheetContent(), {
      detents: [SheetSize.MEDIUM],
      blurStyle: BlurStyle.COMPONENT_THICK,
      showClose: false,
      width: '100%'
    })
    .title(this.title)                    // 设置标题文本
    .hideTitleBar(false)
  }
}

