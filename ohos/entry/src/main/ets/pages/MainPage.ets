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
      // Content area
      if (this.currentTab === 0) {
        this.buildExplorePage()
      } else if (this.currentTab === 1) {
        this.buildHistoryPage()
      } else if (this.currentTab === 2) {
        this.buildFavoritesPage()
      } else {
        this.buildSettingsPage()
      }

      // Floating Tab Bar
      FloatingTabBar({
        selectedIndex: this.currentTab,
        onTap: (index: number) => {
          this.currentTab = index;
        }
      })
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
        .padding({ left: 16, top: 16, bottom: 4 })

      // Source grid
      Grid() {
        this.sourceItem('🐱', 'Picacg', 'picacg')
        this.sourceItem('📖', 'EHentai', 'ehentai')
        this.sourceItem('📕', '禁漫', 'jm')
        this.sourceItem('🎨', 'Hitomi', 'hitomi')
        this.sourceItem('📚', '绅士漫画', 'htmanga')
        this.sourceItem('📘', 'NHentai', 'nhentai')
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
    .backgroundColor(ThemeManager.colors.background)
  }

  @Builder
  sourceItem(icon: string, label: string, source: string) {
    Column() {
      Text(icon)
        .fontSize(32)
      Text(label)
        .fontSize(12)
        .fontColor(ThemeManager.colors.textPrimary)
        .margin({ top: 6 })
    }
    .width('100%')
    .height(90)
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
        .padding({ left: 16, top: 16, bottom: 8 })
      Text(Translations.t('no_data'))
        .fontSize(14)
        .fontColor(ThemeManager.colors.textSecondary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('100%')
    .height('100%')
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
        .padding({ left: 16, top: 16, bottom: 8 })
      Text(Translations.t('no_data'))
        .fontSize(14)
        .fontColor(ThemeManager.colors.textSecondary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('100%')
    .height('100%')
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
        .padding({ left: 16, top: 16, bottom: 8 })
      Text('Settings coming soon')
        .fontSize(14)
        .fontColor(ThemeManager.colors.textSecondary)
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeManager.colors.background)
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
