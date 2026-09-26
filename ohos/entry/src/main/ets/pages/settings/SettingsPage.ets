// pages/settings/SettingsPage.ets - 设置主页（完整版）
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../../common/ThemeManager';
import { Translations } from '../../common/Translations';
import { SettingItem } from '../../components/SettingItem';
import { SettingSection } from '../../components/SettingSection';

@Entry
@Component
struct SettingsPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  build() {
    Column() {
      // Header
      Row() {
        Image($rawfile('icons/ic_back.svg'))
          .width(24).height(24).objectFit(ImageFit.Contain)
          .onClick(() => { router.back(); })
        Text(Translations.t('tab_settings'))
          .fontSize(22).fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000')
          .margin({ left: 12 })
      }
      .width('100%')
      .height(64)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          // === 浏览 ===
          SettingSection({ title: '浏览' })
          SettingItem({ icon: '🔍', title: '初始页面', value: '主页', onTap: () => {} })
          SettingItem({ icon: '📋', title: '探索页面配置', onTap: () => {} })
          SettingItem({ icon: '🚫', title: '关键词屏蔽', onTap: () => {} })
          SettingItem({ icon: '🔎', title: '默认搜索源', value: 'NHentai', onTap: () => {} })
          SettingItem({ icon: '📱', title: '漫画列表显示', value: '连续模式', onTap: () => {} })

          // === 阅读 ===
          SettingSection({ title: '阅读' })
          SettingItem({ icon: '📖', title: '阅读模式', value: '从上至下', onTap: () => {
            router.pushUrl({ url: 'pages/settings/ReadingSettings' });
          }})
          SettingItem({ icon: '👆', title: '点按翻页', value: 'ON', onTap: () => {} })
          SettingItem({ icon: '🔊', title: '音量键翻页', value: 'ON', onTap: () => {} })
          SettingItem({ icon: '🔆', title: '屏幕常亮', value: 'ON', onTap: () => {} })
          SettingItem({ icon: '📝', title: '显示章节评论', value: 'ON', onTap: () => {} })
          SettingItem({ icon: '💾', title: '图片质量', value: 'Original', onTap: () => {} })
          SettingItem({ icon: '🔤', title: '字体大小', value: '16', onTap: () => {} })

          // === 外观 ===
          SettingSection({ title: '外观' })
          SettingItem({ icon: '🌙', title: Translations.t('dark_mode'), value: this.getDarkModeLabel(), onTap: () => {
            this.cycleDarkMode();
          }})
          SettingItem({ icon: '🎨', title: Translations.t('theme_color'), value: '', onTap: () => {
            this.cycleThemeColor();
          }})

          // === 本地收藏 ===
          SettingSection({ title: '本地收藏' })
          SettingItem({ icon: '⭐', title: '收藏夹设置', onTap: () => {} })

          // === APP ===
          SettingSection({ title: 'APP' })
          SettingItem({ icon: '📂', title: '下载路径', value: '默认', onTap: () => {} })
          SettingItem({ icon: '🗑️', title: '清除缓存', value: '', onTap: () => {} })
          SettingItem({ icon: '🔄', title: '检查更新', onTap: () => {} })

          // === 漫画源 ===
          SettingSection({ title: '漫画源' })
          SettingItem({ icon: '📕', title: 'JM 禁漫', value: '→', onTap: () => {
            router.pushUrl({ url: 'pages/settings/JmSettings' });
          }})
          SettingItem({ icon: '📚', title: 'HT 绅士漫画', value: '→', onTap: () => {
            router.pushUrl({ url: 'pages/settings/HtSettings' });
          }})
          SettingItem({ icon: '📘', title: 'NHentai 设置', value: '→', onTap: () => {} })
          SettingItem({ icon: '📖', title: 'EHentai 设置', value: '→', onTap: () => {} })
          SettingItem({ icon: '🐱', title: 'Picacg 设置', value: '→', onTap: () => {} })
          SettingItem({ icon: '🎨', title: 'Hitomi 设置', value: '→', onTap: () => {} })

          // === 网络 ===
          SettingSection({ title: '网络' })
          SettingItem({ icon: '🌐', title: '代理设置', value: '系统代理', onTap: () => {} })
          SettingItem({ icon: '☁️', title: 'WebDAV 同步', value: '未配置', onTap: () => {} })

          // === 关于 ===
          SettingSection({ title: '关于' })
          SettingItem({ icon: 'ℹ️', title: Translations.t('about'), value: 'v' + '1.0.0', onTap: () => {
            router.pushUrl({ url: 'pages/settings/AboutPage' });
          }})
        }
        .width('100%')
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDarkMode ? '#000000' : '#F5F5F5')
  }

  private getDarkModeLabel(): string {
    return ThemeManager.isDark ? '开启' : '关闭';
  }

  private cycleDarkMode(): void {
    ThemeManager.setDarkMode(!ThemeManager.isDark);
  }

  private cycleThemeColor(): void {
    const colors = ThemeManager.themePresets;
    const current = ThemeManager.themeColor;
    let idx = 0;
    for (let i = 0; i < colors.length; i++) {
      if (colors[i] === current) { idx = i; break; }
    }
    ThemeManager.setThemeColor(colors[(idx + 1) % colors.length]);
  }
}
