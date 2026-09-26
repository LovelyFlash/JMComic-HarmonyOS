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
    .width('92%')
    .height(56)
    .borderRadius(28)
    .backgroundColor(ThemeManager.colors.surface)
    .shadow({ radius: 12, color: 'rgba(0,0,0,0.15)', offsetX: 0, offsetY: 4 })
    .padding({ left: 8, right: 8 })
  }

  @Builder
  tabItem(index: number, label: string) {
    Column() {
      Text(label)
        .fontSize(10)
        .fontColor(this.selectedIndex === index ? ThemeManager.colors.primary : ThemeManager.colors.textSecondary)
    }
    .layoutWeight(1)
    .height(52)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.onTap(index);
    })
  }
}
