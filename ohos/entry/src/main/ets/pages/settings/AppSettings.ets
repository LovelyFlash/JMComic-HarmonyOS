// pages/settings/AppSettings.ets - APP 设置
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../../common/ThemeManager';
import { SettingItem } from '../../components/SettingItem';
import { SettingSection } from '../../components/SettingSection';
import { ApiConstants } from '../../common/Constants';

@Entry
@Component
struct AppSettings {
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  build() {
    Column({ space: 8 }) {
      Row() {
        Image($rawfile('icons/ic_back.svg'))
          .width(24).height(24).objectFit(ImageFit.Contain)
          .onClick(() => { router.back(); })
        Text('APP 设置')
          .fontSize(22).fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF')
          .margin({ left: 12 })
      }
      .width('100%').height(64).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      Scroll() {
        Column({ space: 8 }) {
          SettingSection({ title: '数据' })
          SettingItem({ icon: '📂', title: '下载路径', value: '默认存储', onTap: () => {} })
          SettingItem({ icon: '💾', title: '缓存大小', value: '0 MB', onTap: () => {} })
          SettingItem({ icon: '🗑️', title: '清除缓存', value: '', onTap: () => {} })
          SettingItem({ icon: '📊', title: '缓存限制', value: '1000', onTap: () => {} })

          SettingSection({ title: '更新' })
          SettingItem({ icon: '🔄', title: '检查更新', value: 'v' + ApiConstants.APP_VERSION, onTap: () => {} })
          SettingItem({ icon: '📜', title: '历史版本', onTap: () => {} })

          SettingSection({ title: '数据管理' })
          SettingItem({ icon: '📤', title: '导出数据', onTap: () => {} })
          SettingItem({ icon: '📥', title: '导入数据', onTap: () => {} })
          SettingItem({ icon: '⚠️', title: '删除所有数据', onTap: () => {} })
        }.width('100%')
      }.layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
  }
}
