// pages/settings/ReadingSettings.ets - 阅读设置（完整版）
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../../common/ThemeManager';
import { SettingItem } from '../../components/SettingItem';
import { SettingSwitch } from '../../components/SettingSwitch';
import { SettingSection } from '../../components/SettingSection';

@Entry
@Component
struct ReadingSettings {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State readMode: number = 2  // 0=左→右 1=右→左 2=上→下 3=连续 4=双页 5=双页反向
  @State tapTurnPage: boolean = true
  @State volumeKeyTurnPage: boolean = true
  @State keepScreenOn: boolean = true
  @State showChapterComments: boolean = true
  @State showCommentsAtEnd: boolean = false
  @State fontSize: number = 16
  @State imageQuality: number = 0  // 0=original 1=high 2=medium
  @State pageAnimation: boolean = true
  @State autoPageTime: number = 5
  @State imageLayout: number = 0  // 0=contain 1=fitWidth 2=fitHeight
  @State invertTap: boolean = false
  @State doubleTapZoom: boolean = true
  @State longPressZoom: boolean = true
  @State sidePageTurn: boolean = false
  @State showPageInfo: boolean = true

  private readModes: string[] = ['从左至右', '从右至左', '从上至下', '从上至下(连续)', '双页', '双页(反向)']
  private imageQualities: string[] = ['Original', 'High', 'Medium']
  private imageLayouts: string[] = ['自适应', '适应宽度', '适应高度']
  private fontSizes: number[] = [12, 14, 16, 18, 20, 22, 24]
  private autoPageTimes: number[] = [3, 5, 8, 10, 15]

  build() {
    Column() {
      Row() {
        Image($rawfile('icons/ic_back.svg'))
          .width(24).height(24).objectFit(ImageFit.Contain)
          .onClick(() => { router.back(); })
        Text('阅读设置')
          .fontSize(22).fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF')
          .margin({ left: 12 })
      }
      .width('100%').height(64).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          SettingSection({ title: '翻页方式' })
          SettingItem({ icon: '📖', title: '阅读模式', value: this.readModes[this.readMode], onTap: () => {
            this.readMode = (this.readMode + 1) % this.readModes.length
          }})

          SettingSection({ title: '翻页控制' })
          SettingSwitch({ icon: '👆', title: '点按翻页', isOn: this.tapTurnPage, onToggle: (v: boolean) => { this.tapTurnPage = v } })
          SettingSwitch({ icon: '↕️', title: '反转点按翻页', isOn: this.invertTap, onToggle: (v: boolean) => { this.invertTap = v } })
          SettingSwitch({ icon: '🔊', title: '音量键翻页', isOn: this.volumeKeyTurnPage, onToggle: (v: boolean) => { this.volumeKeyTurnPage = v } })
          SettingSwitch({ icon: '📱', title: '侧边翻页栏', isOn: this.sidePageTurn, onToggle: (v: boolean) => { this.sidePageTurn = v } })

          SettingSection({ title: '显示' })
          SettingSwitch({ icon: '🔆', title: '屏幕常亮', isOn: this.keepScreenOn, onToggle: (v: boolean) => { this.keepScreenOn = v } })
          SettingSwitch({ icon: '✨', title: '翻页动画', isOn: this.pageAnimation, onToggle: (v: boolean) => { this.pageAnimation = v } })
          SettingSwitch({ icon: 'ℹ️', title: '显示页码', isOn: this.showPageInfo, onToggle: (v: boolean) => { this.showPageInfo = v } })
          SettingSwitch({ icon: '💬', title: '显示章节评论', isOn: this.showChapterComments, onToggle: (v: boolean) => { this.showChapterComments = v } })
          if (this.showChapterComments) {
            SettingSwitch({ icon: '📝', title: '章节末尾显示评论', isOn: this.showCommentsAtEnd, onToggle: (v: boolean) => { this.showCommentsAtEnd = v } })
          }

          SettingSection({ title: '缩放' })
          SettingSwitch({ icon: '🔍', title: '双击缩放', isOn: this.doubleTapZoom, onToggle: (v: boolean) => { this.doubleTapZoom = v } })
          SettingSwitch({ icon: '✋', title: '长按缩放', isOn: this.longPressZoom, onToggle: (v: boolean) => { this.longPressZoom = v } })

          SettingSection({ title: '图片' })
          SettingItem({ icon: '🖼️', title: '图片质量', value: this.imageQualities[this.imageQuality], onTap: () => {
            this.imageQuality = (this.imageQuality + 1) % this.imageQualities.length
          }})
          SettingItem({ icon: '📐', title: '图片布局', value: this.imageLayouts[this.imageLayout], onTap: () => {
            this.imageLayout = (this.imageLayout + 1) % this.imageLayouts.length
          }})

          SettingSection({ title: '字体' })
          Row() {
            Text('A').fontSize(12).fontColor(this.isDarkMode ? '#8E8E93' : '#666666')
            Slider({
              value: this.fontSize,
              min: 12,
              max: 24,
              step: 2,
              style: SliderStyle.OutSet
            })
            .layoutWeight(1)
            .onChange((value: number) => { this.fontSize = value })
            Text('A').fontSize(24).fontColor(this.isDarkMode ? '#8E8E93' : '#666666')
          }
          .width('100%').height(56).padding({ left: 16, right: 16 })
          .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF')

          SettingSection({ title: '自动翻页' })
          SettingItem({ icon: '⏱️', title: '自动翻页间隔', value: this.autoPageTime.toString() + '秒', onTap: () => {
            let idx = this.autoPageTimes.indexOf(this.autoPageTime)
            idx = (idx + 1) % this.autoPageTimes.length
            this.autoPageTime = this.autoPageTimes[idx]
          }})
        }.width('100%')
      }.layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
  }
}
