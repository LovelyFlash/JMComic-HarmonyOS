// components/FloatingTabBar.ets - 悬浮底部导航栏
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';

@Component
export struct FloatingTabBar {
  @Prop selectedIndex: number = 0
  onTap: (index: number) => void = () => {}
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  build() {
    Row() {
      this.tabItem(0, Translations.t('tab_explore'))
      this.tabItem(1, Translations.t('tab_history'))
      this.tabItem(2, Translations.t('tab_favorites'))
      this.tabItem(3, Translations.t('tab_settings'))
    }
    .width('100%')
    .height(52)
    .backgroundColor(ThemeManager.colors.surface)
    .border({ width: { top: 0.5 }, color: ThemeManager.colors.divider })
  }

  @Builder
  tabItem(index: number, label: string) {
    Column() {
      Text(label)
        .fontSize(11)
        .fontColor(this.selectedIndex === index ? ThemeManager.colors.primary : ThemeManager.colors.textSecondary)
        .fontWeight(this.selectedIndex === index ? FontWeight.Medium : FontWeight.Normal)
    }
    .layoutWeight(1)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.onTap(index);
    })
  }
}
