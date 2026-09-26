// pages/MainPage.ets - 主页面（含底部导航 + 初始化）
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FloatingTabBar } from '../components/FloatingTabBar';
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

  build() {
    Column() {
      // Content area — layoutWeight(1) 让它填充剩余空间
      if (this.currentTab === 0) {
        this.buildExplorePage()
      } else if (this.currentTab === 1) {
        this.buildHistoryPage()
      } else if (this.currentTab === 2) {
        this.buildFavoritesPage()
      } else {
        this.buildSettingsPage()
      }

      // Bottom Tab Bar
      Column() {
        FloatingTabBar({
          selectedIndex: this.currentTab,
          onTap: (index: number) => {
            this.currentTab = index;
          }
        })
      }
      .width('100%')
      .padding({ bottom: 12 })
      .backgroundColor(ThemeManager.colors.background)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeManager.colors.background)
  }

  @Builder
  buildExplorePage() {
    Column() {
      Text(Translations.t('app_name'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeManager.colors.textPrimary)
        .width('100%')
        .textAlign(TextAlign.Start)
        .padding({ left: 16, top: 56, bottom: 4 })

      Text(Translations.t('tab_explore'))
        .fontSize(14)
        .fontColor(ThemeManager.colors.textSecondary)
        .width('100%')
        .padding({ left: 16, bottom: 16 })

      // Source grid
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
    .layoutWeight(1)
    .backgroundColor(ThemeManager.colors.background)
  }

  @Builder
  sourceItem(label: string, source: string) {
    Column() {
      Text(label)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .height(80)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(ThemeManager.colors.surface)
    .borderRadius(12)
    .onClick(() => {
      this.navigateToSource(source);
    })
  }

  @Builder
  buildHistoryPage() {
    Column() {
      Text(Translations.t('tab_history'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeManager.colors.textPrimary)
        .width('100%')
        .padding({ left: 16, top: 56, bottom: 8 })
      Text(Translations.t('no_data'))
        .fontSize(14)
        .fontColor(ThemeManager.colors.textSecondary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor(ThemeManager.colors.background)
  }

  @Builder
  buildFavoritesPage() {
    Column() {
      Text(Translations.t('tab_favorites'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeManager.colors.textPrimary)
        .width('100%')
        .padding({ left: 16, top: 56, bottom: 8 })
      Text(Translations.t('no_data'))
        .fontSize(14)
        .fontColor(ThemeManager.colors.textSecondary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor(ThemeManager.colors.background)
  }

  @Builder
  buildSettingsPage() {
    Column() {
      Text(Translations.t('tab_settings'))
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeManager.colors.textPrimary)
        .width('100%')
        .padding({ left: 16, top: 56, bottom: 8 })

      // Settings items
      Column() {
        this.settingsItem(Translations.t('dark_mode'), () => {
          ThemeManager.setDarkMode(!ThemeManager.isDark);
        })
        this.settingsItem(Translations.t('theme_color'), () => {})
        this.settingsItem('JM ' + Translations.t('jm_domain_update'), () => {
          router.pushUrl({ url: 'pages/settings/JmSettings' });
        })
        this.settingsItem('HT ' + Translations.t('ht_domain_update'), () => {
          router.pushUrl({ url: 'pages/settings/HtSettings' });
        })
        this.settingsItem(Translations.t('about'), () => {
          router.pushUrl({ url: 'pages/settings/AboutPage' });
        })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor(ThemeManager.colors.background)
  }

  @Builder
  settingsItem(label: string, action: () => void) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor(ThemeManager.colors.textPrimary)
        .layoutWeight(1)
      Text('>')
        .fontSize(14)
        .fontColor(ThemeManager.colors.textSecondary)
    }
    .width('100%')
    .height(52)
    .padding({ left: 16, right: 16 })
    .backgroundColor(ThemeManager.colors.surface)
    .border({ width: { bottom: 0.5 }, color: ThemeManager.colors.divider })
    .onClick(action)
  }

  private navigateToSource(source: string): void {
    const pageMap: Record<string, string> = {
      'picacg': 'pages/picacg/PicacgHome',
      'ehentai': 'pages/ehentai/EhHome',
      'jm': 'pages/jm/JmHome',
      'hitomi': 'pages/hitomi/HitomiHome',
      'htmanga': 'pages/htcomic/HtHome',
      'nhentai': 'pages/nhentai/NhHome'
    };
    const page = pageMap[source];
    if (page !== undefined) {
      router.pushUrl({ url: page });
    }
  }
}
