// pages/settings/NetworkSettings.ets - 网络设置
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../../common/ThemeManager';
import { SettingItem } from '../../components/SettingItem';
import { SettingSwitch } from '../../components/SettingSwitch';
import { SettingSection } from '../../components/SettingSection';

@Entry
@Component
struct NetworkSettings {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State useSystemProxy: boolean = true
  @State enableCache: boolean = true

  build() {
    Column({ space: 8 }) {
      Row() {
        Image($rawfile('icons/ic_back.svg'))
          .width(24).height(24).objectFit(ImageFit.Contain)
          .onClick(() => { router.back(); })
        Text('网络设置')
          .fontSize(22).fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF')
          .margin({ left: 12 })
      }
      .width('100%').height(64).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      Scroll() {
        Column({ space: 8 }) {
          SettingSection({ title: '代理' })
          SettingSwitch({ icon: '🌐', title: '使用系统代理', isOn: this.useSystemProxy, onToggle: (v: boolean) => { this.useSystemProxy = v } })
          SettingItem({ icon: '🔗', title: '自定义代理', value: '未配置', onTap: () => {} })

          SettingSection({ title: '缓存' })
          SettingSwitch({ icon: '💾', title: '启用网络缓存', isOn: this.enableCache, onToggle: (v: boolean) => { this.enableCache = v } })
          SettingItem({ icon: '⏱️', title: '缓存超时', value: '5 分钟', onTap: () => {} })

          SettingSection({ title: 'WebDAV 同步' })
          SettingItem({ icon: '☁️', title: 'WebDAV 服务器', value: '未配置', onTap: () => {} })
          SettingItem({ icon: '🔄', title: '立即同步', onTap: () => {} })
          SettingItem({ icon: '📊', title: '同步状态', value: '上次同步: 无', onTap: () => {} })
        }.width('100%')
      }.layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
  }
}
