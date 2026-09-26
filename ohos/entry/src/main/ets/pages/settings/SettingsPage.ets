// pages/settings/SettingsPage.ets - 设置主页
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../../common/ThemeManager';
import { Translations } from '../../common/Translations';
import { AppData } from '../../viewmodel/AppData';

@Entry
@Component
struct SettingsPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State darkModeOption: number = 0

  build() {
    Column() {
      Row() {
        Text('<').fontSize(20).fontColor(this.isDarkMode ? '#4DA6FF' : '#007AFF')
          .onClick(() => { router.back(); })
        Text(Translations.t('tab_settings')).fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000').margin({ left: 16 })
      }.width('100%').height(56).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          // Appearance section
          Text(Translations.t('settings_appearance')).fontSize(13)
            .fontColor(this.isDarkMode ? '#999999' : '#666666').width('100%')
            .padding({ left: 16, top: 56, bottom: 8 })

          this.settingItem(Translations.t('dark_mode'), this.getDarkModeLabel(), () => {
            this.cycleDarkMode();
          })

          this.settingItem(Translations.t('theme_color'), ThemeManager.themeColor, () => {
            this.cycleThemeColor();
          })

          // Reading section
          Text(Translations.t('settings_reading')).fontSize(13)
            .fontColor(this.isDarkMode ? '#999999' : '#666666').width('100%')
            .padding({ left: 16, top: 24, bottom: 8 })

          this.settingItem(Translations.t('volume_key'), 'ON', () => {})

          this.settingItem(Translations.t('keep_screen_on'), 'ON', () => {})

          // Comic source section
          Text(Translations.t('settings_comic_source')).fontSize(13)
            .fontColor(this.isDarkMode ? '#999999' : '#666666').width('100%')
            .padding({ left: 16, top: 24, bottom: 8 })

          this.settingItem('JM ' + Translations.t('jm_domain_update'), '→', () => {
            router.pushUrl({ url: 'pages/settings/JmSettings' });
          })

          this.settingItem('HT ' + Translations.t('ht_domain_update'), '→', () => {
            router.pushUrl({ url: 'pages/settings/HtSettings' });
          })

          // System section
          Text(Translations.t('settings_system')).fontSize(13)
            .fontColor(this.isDarkMode ? '#999999' : '#666666').width('100%')
            .padding({ left: 16, top: 24, bottom: 8 })

          this.settingItem(Translations.t('download'), '→', () => {
            router.pushUrl({ url: 'pages/DownloadPage' });
          })

          this.settingItem(Translations.t('about'), '→', () => {
            router.pushUrl({ url: 'pages/settings/AboutPage' });
          })
        }
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
  }

  @Builder
  settingItem(label: string, value: string, action: () => void) {
    Row() {
      Text(label).fontSize(15).fontColor(this.isDarkMode ? '#FFFFFF' : '#000000').layoutWeight(1)
      Text(value).fontSize(14).fontColor(this.isDarkMode ? '#999999' : '#666666')
    }
    .width('100%').height(52).padding({ left: 16, right: 16 })
    .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: this.isDarkMode ? '#333333' : '#E5E5EA' })
    .onClick(action)
  }

  private getDarkModeLabel(): string {
    if (this.darkModeOption === 0) return '跟随系统';
    if (this.darkModeOption === 1) return '关闭';
    return '开启';
  }

  private cycleDarkMode(): void {
    this.darkModeOption = (this.darkModeOption + 1) % 3;
    if (this.darkModeOption === 2) {
      AppStorage.setOrCreate('isDarkMode', true);
    } else if (this.darkModeOption === 1) {
      AppStorage.setOrCreate('isDarkMode', false);
    }
  }

  private cycleThemeColor(): void {
    const colors = ThemeManager.themePresets;
    const current = ThemeManager.themeColor;
    let idx = 0;
    for (let i = 0; i < colors.length; i++) {
      if (colors[i] === current) { idx = i; break; }
    }
    const next = (idx + 1) % colors.length;
    ThemeManager.setThemeColor(colors[next]);
  }
}
