// pages/settings/ExploreSettings.ets - 浏览设置
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../../common/ThemeManager';
import { SettingItem } from '../../components/SettingItem';
import { SettingSwitch } from '../../components/SettingSwitch';
import { SettingSection } from '../../components/SettingSection';

@Entry
@Component
struct ExploreSettings {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State initialPage: number = 0
  @State listMode: number = 0
  @State checkClipboard: boolean = true
  @State sidePageTurn: boolean = false
  @State autoLanguageFilter: number = 0
  @State hideReadItems: boolean = false
  @State hideBlockedWorks: boolean = true

  private initialPages: string[] = ['主页', '收藏夹', '探索', '分类']
  private listModes: string[] = ['连续模式', '分页模式']
  private langFilters: string[] = ['无', 'Chinese', 'English', 'Japanese']

  build() {
    Column() {
      Row() {
        Image($rawfile('icons/ic_back.svg'))
          .width(24).height(24).objectFit(ImageFit.Contain)
          .onClick(() => { router.back(); })
        Text('浏览设置')
          .fontSize(22).fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF')
          .margin({ left: 12 })
      }
      .width('100%').height(64).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          SettingSection({ title: '显示' })
          SettingItem({ icon: '🏠', title: '初始页面', value: this.initialPages[this.initialPage], onTap: () => {
            this.initialPage = (this.initialPage + 1) % this.initialPages.length
          }})
          SettingItem({ icon: '📋', title: '探索页面配置', onTap: () => {} })
          SettingItem({ icon: '🗂️', title: '分类页面配置', onTap: () => {} })
          SettingItem({ icon: '📱', title: '漫画列表显示', value: this.listModes[this.listMode], onTap: () => {
            this.listMode = (this.listMode + 1) % this.listModes.length
          }})
          SettingItem({ icon: '🚫', title: '关键词屏蔽', onTap: () => {} })

          SettingSection({ title: '过滤' })
          SettingSwitch({ icon: '👁️', title: '完全隐藏屏蔽作品', isOn: this.hideBlockedWorks, onToggle: (v: boolean) => { this.hideBlockedWorks = v } })
          SettingSwitch({ icon: '📖', title: '隐藏已读内容', isOn: this.hideReadItems, onToggle: (v: boolean) => { this.hideReadItems = v } })
          SettingItem({ icon: '🌐', title: '自动语言筛选', value: this.langFilters[this.autoLanguageFilter], onTap: () => {
            this.autoLanguageFilter = (this.autoLanguageFilter + 1) % this.langFilters.length
          }})

          SettingSection({ title: '搜索' })
          SettingItem({ icon: '🔎', title: '默认搜索源', value: 'NHentai', onTap: () => {} })

          SettingSection({ title: '工具' })
          SettingSwitch({ icon: '📋', title: '检查剪切板链接', isOn: this.checkClipboard, onToggle: (v: boolean) => { this.checkClipboard = v } })
          SettingSwitch({ icon: '📱', title: '侧边翻页栏', isOn: this.sidePageTurn, onToggle: (v: boolean) => { this.sidePageTurn = v } })
        }.width('100%')
      }.layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
  }
}
