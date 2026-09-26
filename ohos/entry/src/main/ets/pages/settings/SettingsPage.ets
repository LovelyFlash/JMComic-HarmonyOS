// pages/settings/SettingsPage.ets - 设置主页
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../../common/ThemeManager';
import { Translations } from '../../common/Translations';

@Entry
@Component
struct SettingsPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  build() {
    Column() {
      Row() {
        Image($rawfile('icons/ic_back.svg'))
          .width(24).height(24).objectFit(ImageFit.Contain)
          .onClick(() => { router.back(); })
        Text(Translations.t('tab_settings'))
          .fontSize(22).fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000')
          .margin({ left: 12 })
      }.width('100%').height(64).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          this.section('外观')
          this.item(Translations.t('dark_mode'), ThemeManager.isDark ? '开启' : '关闭', () => { ThemeManager.setDarkMode(!ThemeManager.isDark); })
          this.item(Translations.t('theme_color'), '', () => {
            const colors = ThemeManager.themePresets;
            const cur = ThemeManager.themeColor;
            let idx = 0;
            for (let i = 0; i < colors.length; i++) { if (colors[i] === cur) { idx = i; break; } }
            ThemeManager.setThemeColor(colors[(idx + 1) % colors.length]);
          })

          this.section('漫画源')
          this.item('JM 禁漫 域名更新', '→', () => { router.pushUrl({ url: 'pages/settings/JmSettings' }); })
          this.item('HT 绅士漫画 域名更新', '→', () => { router.pushUrl({ url: 'pages/settings/HtSettings' }); })

          this.section('系统')
          this.item(Translations.t('about'), 'v' + '1.0.0', () => { router.pushUrl({ url: 'pages/settings/AboutPage' }); })
        }.width('100%')
      }.layoutWeight(1)
    }.width('100%').height('100%').backgroundColor(this.isDarkMode ? '#000000' : '#F5F5F5')
  }

  @Builder section(title: string) {
    Text(title).fontSize(13).fontColor(this.isDarkMode ? '#999999' : '#666666').width('100%').padding({ left: 16, top: 24, bottom: 8 })
  }

  @Builder item(label: string, value: string, action: () => void) {
    Row() {
      Text(label).fontSize(16).fontColor(this.isDarkMode ? '#FFFFFF' : '#000000').layoutWeight(1)
      if (value.length > 0) { Text(value).fontSize(14).fontColor(this.isDarkMode ? '#999999' : '#666666').margin({ right: 4 }) }
      Image($rawfile('icons/ic_arrow_right.svg')).width(16).height(16).objectFit(ImageFit.Contain)
    }.width('100%').height(56).padding({ left: 16, right: 16 })
    .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: this.isDarkMode ? '#333333' : '#E5E5EA' })
    .onClick(action)
  }
}
