// pages/MainPage.ets - 主页面（Tabs + SVG 图标 + 系统颜色 + 深色模式）
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';

const TAG = 'MainPage';

@Entry
@Component
struct MainPage {
  @State currentTab: number = 0
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  aboutToAppear(): void {
    hilog.info(0x0000, TAG, 'MainPage aboutToAppear');
  }

  @Builder
  tabBuilder(title: string, iconRes: string, iconSelectedRes: string, index: number) {
    Column() {
      Image(this.currentTab === index ? $rawfile(`icons/${iconSelectedRes}`) : $rawfile(`icons/${iconRes}`))
        .width(24)
        .height(24)
        .objectFit(ImageFit.Contain)
      Text(title)
        .fontSize(10)
        .fontColor(this.currentTab === index ?
          $r('sys.color.ohos_id_color_text_primary_activated') :
          $r('sys.color.ohos_id_color_text_secondary'))
        .margin({ top: 2 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {
        TabContent() { this.buildExplorePage() }
          .tabBar(this.tabBuilder(Translations.t('tab_explore'), 'ic_explore.svg', 'ic_explore_selected.svg', 0))

        TabContent() { this.buildHistoryPage() }
          .tabBar(this.tabBuilder(Translations.t('tab_history'), 'ic_history.svg', 'ic_history_selected.svg', 1))

        TabContent() { this.buildFavoritesPage() }
          .tabBar(this.tabBuilder(Translations.t('tab_favorites'), 'ic_favorites.svg', 'ic_favorites_selected.svg', 2))

        TabContent() { this.buildSettingsPage() }
          .tabBar(this.tabBuilder(Translations.t('tab_settings'), 'ic_settings.svg', 'ic_settings_selected.svg', 3))
      }
      .vertical(false)
      .barHeight(56)
      .barMode(BarMode.Fixed)
      .onChange((index: number) => { this.currentTab = index; })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
  }

  @Builder
  buildExplorePage() {
    Column() {
      Text(Translations.t('app_name'))
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000')
        .width('100%')
        .textAlign(TextAlign.Start)
        .padding({ left: 24, top: 64, bottom: 4 })

      Text(Translations.t('tab_explore'))
        .fontSize(14)
        .fontColor(this.isDarkMode ? '#999999' : '#666666')
        .width('100%')
        .padding({ left: 24, bottom: 20 })

      Grid() {
        this.sourceItem('Picacg', 'picacg')
        this.sourceItem('EHentai', 'ehentai')
        this.sourceItem('JinMan', 'jm')
        this.sourceItem('Hitomi', 'hitomi')
        this.sourceItem('HT', 'htmanga')
        this.sourceItem('NHentai', 'nhentai')
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width('100%')
      .padding(16)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDarkMode ? '#000000' : '#F5F5F5')
  }

  @Builder
  sourceItem(label: string, source: string) {
    Column() {
      Text(label)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000')
    }
    .width('100%')
    .height(80)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF')
    .borderRadius(16)
    .shadow({ radius: 4, color: this.isDarkMode ? 'rgba(0,0,0,0.3)' : 'rgba(0,0,0,0.08)', offsetY: 2 })
    .onClick(() => { this.navigateToSource(source); })
  }

  @Builder
  buildHistoryPage() {
    Column() {
      Text(Translations.t('tab_history'))
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000')
        .width('100%')
        .padding({ left: 24, top: 64, bottom: 8 })
      Column() {
        Text(Translations.t('no_data'))
          .fontSize(14)
          .fontColor(this.isDarkMode ? '#999999' : '#666666')
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDarkMode ? '#000000' : '#F5F5F5')
  }

  @Builder
  buildFavoritesPage() {
    Column() {
      Text(Translations.t('tab_favorites'))
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000')
        .width('100%')
        .padding({ left: 24, top: 64, bottom: 8 })
      Column() {
        Text(Translations.t('no_data'))
          .fontSize(14)
          .fontColor(this.isDarkMode ? '#999999' : '#666666')
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDarkMode ? '#000000' : '#F5F5F5')
  }

  @Builder
  buildSettingsPage() {
    Column() {
      Text(Translations.t('tab_settings'))
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000')
        .width('100%')
        .padding({ left: 24, top: 64, bottom: 16 })

      Scroll() {
        Column() {
          this.settingsSection(Translations.t('settings_appearance'))
          this.settingsItem(Translations.t('dark_mode'), () => { ThemeManager.setDarkMode(!ThemeManager.isDark); })
          this.settingsItem(Translations.t('theme_color'), () => {
            const colors = ThemeManager.themePresets;
            const current = ThemeManager.themeColor;
            let idx = 0;
            for (let i = 0; i < colors.length; i++) { if (colors[i] === current) { idx = i; break; } }
            ThemeManager.setThemeColor(colors[(idx + 1) % colors.length]);
          })

          this.settingsSection(Translations.t('settings_comic_source'))
          this.settingsItem('JM ' + Translations.t('jm_domain_update'), () => { router.pushUrl({ url: 'pages/settings/JmSettings' }); })
          this.settingsItem('HT ' + Translations.t('ht_domain_update'), () => { router.pushUrl({ url: 'pages/settings/HtSettings' }); })

          this.settingsSection(Translations.t('settings_system'))
          this.settingsItem(Translations.t('about'), () => { router.pushUrl({ url: 'pages/settings/AboutPage' }); })
        }.width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDarkMode ? '#000000' : '#F5F5F5')
  }

  @Builder
  settingsSection(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor(this.isDarkMode ? '#999999' : '#666666')
      .width('100%')
      .padding({ left: 16, top: 24, bottom: 8 })
  }

  @Builder
  settingsItem(label: string, action: () => void) {
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000')
        .layoutWeight(1)
      Image($rawfile('icons/ic_arrow_right.svg'))
        .width(16).height(16)
        .objectFit(ImageFit.Contain)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF')
    .border({ width: { bottom: 0.5 }, color: this.isDarkMode ? '#333333' : '#E5E5EA' })
    .onClick(action)
  }

  private navigateToSource(source: string): void {
    const pageMap: Record<string, string> = {
      'picacg': 'pages/picacg/PicacgHome', 'ehentai': 'pages/ehentai/EhHome',
      'jm': 'pages/jm/JmHome', 'hitomi': 'pages/hitomi/HitomiHome',
      'htmanga': 'pages/htcomic/HtHome', 'nhentai': 'pages/nhentai/NhHome'
    };
    const page = pageMap[source];
    if (page !== undefined) { router.pushUrl({ url: page }); }
  }
}
