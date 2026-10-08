// pages/settings/ReadingSettings.ets - 阅读设置 - NavDestination
// 主干为 List + ListItemGroup（分组 + 粘性标题 + 组内分割线）
import { Translations } from '../../common/Translations';
import { ReadingConfig } from '../../common/ReadingConfig';
import { SettingSwitch } from '../../components/SettingSwitch';
import { SettingSelect } from '../../components/SettingSelect';
import { SettingCorner } from '../../components/SettingCommon';
import { immersiveNavModifier } from '../../common/Compat';

@Builder
export function ReadingSettingsBuilder(name: string, param: object) {
  ReadingSettings()
}

@Component
export struct ReadingSettings {
  @State title: string = Translations.t('reading_settings')
  @StorageProp('bottomAvoidHeight') bottomAvoid: number = 0
  @State readMode: number = 2
  @State tapTurnPage: boolean = true
  @State volumeKeyTurnPage: boolean = true
  @State keepScreenOn: boolean = true
  @State pageAnimation: boolean = true
  @State imageQuality: number = 0
  @State autoPageTime: number = 5
  @State imageLayout: number = 0
  @State invertTap: boolean = false
  @State doubleTapZoom: boolean = true
  @State longPressZoom: boolean = true
  @State sidePageTurn: boolean = false
  @State showPageInfo: boolean = true

  private readModeKeys: string[] = ['mode_ltr', 'mode_rtl', 'mode_ttb', 'mode_continuous', 'mode_dual', 'mode_dual_rtl'];
  private imageQualities: string[] = ['Original', 'High', 'Medium'];
  private imageLayoutKeys: string[] = ['layout_contain', 'layout_fill', 'layout_cover'];
  private autoPageTimes: number[] = [3, 5, 8, 10, 15];

  aboutToAppear(): void {
    ReadingConfig.load().then(() => {
      this.readMode = ReadingConfig.readMode;
      this.tapTurnPage = ReadingConfig.tapTurnPage;
      this.volumeKeyTurnPage = ReadingConfig.volumeKeyTurnPage;
      this.keepScreenOn = ReadingConfig.keepScreenOn;
      this.pageAnimation = ReadingConfig.pageAnimation;
      this.imageQuality = ReadingConfig.imageQuality;
      this.autoPageTime = ReadingConfig.autoPageTime;
      this.imageLayout = ReadingConfig.imageLayout;
      this.invertTap = ReadingConfig.invertTap;
      this.doubleTapZoom = ReadingConfig.doubleTapZoom;
      this.longPressZoom = ReadingConfig.longPressZoom;
      this.sidePageTurn = ReadingConfig.sidePageTurn;
      this.showPageInfo = ReadingConfig.showPageInfo;
    });
  }

  private save(): void {
    ReadingConfig.readMode = this.readMode;
    ReadingConfig.tapTurnPage = this.tapTurnPage;
    ReadingConfig.volumeKeyTurnPage = this.volumeKeyTurnPage;
    ReadingConfig.keepScreenOn = this.keepScreenOn;
    ReadingConfig.pageAnimation = this.pageAnimation;
    ReadingConfig.imageQuality = this.imageQuality;
    ReadingConfig.autoPageTime = this.autoPageTime;
    ReadingConfig.imageLayout = this.imageLayout;
    ReadingConfig.invertTap = this.invertTap;
    ReadingConfig.doubleTapZoom = this.doubleTapZoom;
    ReadingConfig.longPressZoom = this.longPressZoom;
    ReadingConfig.sidePageTurn = this.sidePageTurn;
    ReadingConfig.showPageInfo = this.showPageInfo;
    ReadingConfig.saveAll();
  }

  private readModeLabels(): string[] {
    const labels: string[] = [];
    for (let i = 0; i < this.readModeKeys.length; i++) {
      labels.push(Translations.t(this.readModeKeys[i]));
    }
    return labels;
  }

  private imageLayoutLabels(): string[] {
    const labels: string[] = [];
    for (let i = 0; i < this.imageLayoutKeys.length; i++) {
      labels.push(Translations.t(this.imageLayoutKeys[i]));
    }
    return labels;
  }

  private autoPageTimeLabels(): string[] {
    const labels: string[] = [];
    for (let i = 0; i < this.autoPageTimes.length; i++) {
      labels.push(`${this.autoPageTimes[i]}${Translations.t('seconds_suffix')}`);
    }
    return labels;
  }

  /** 分组标题（bg_page 垫底，随列表滚动） */
  @Builder
  groupHeader(title: string) {
    Text(title)
      .fontSize(13)
      .fontColor($r('app.color.text_secondary'))
      .width('100%')
      .padding({ left: 4, top: 16, bottom: 8 })
      .backgroundColor($r('app.color.bg_page'))
  }

  build() {
    NavDestination() {
      List({ space: 24 }) {
        ListItemGroup({ header: this.groupHeader(Translations.t('section_turn_method')) }) {
          SettingSelect({
            corner: SettingCorner.ALL,
            icon: $r('sys.symbol.arrowshape_turn_up_left'),
            title: Translations.t('section_turn_method'),
            options: this.readModeLabels(),
            selectedIndex: this.readMode,
            onSelect: (index: number) => {
              this.readMode = index;
              this.save();
            }
          })
        }

        ListItemGroup({ header: this.groupHeader(Translations.t('section_turn_control')) }) {
          SettingSwitch({ corner: SettingCorner.FIRST, icon: $r('sys.symbol.hand_tap'), title: Translations.t('tap_turn_page'), isOn: this.tapTurnPage, onToggle: (v: boolean) => {
            this.tapTurnPage = v; this.save();
          }})
          SettingSwitch({ corner: SettingCorner.MIDDLE, icon: $r('sys.symbol.arrowshape_turn_up_left'), title: Translations.t('invert_tap'), isOn: this.invertTap, onToggle: (v: boolean) => {
            this.invertTap = v; this.save();
          }})
          SettingSwitch({ corner: SettingCorner.MIDDLE, icon: $r('sys.symbol.speaker_wave_2'), title: Translations.t('volume_key'), isOn: this.volumeKeyTurnPage, onToggle: (v: boolean) => {
            this.volumeKeyTurnPage = v; this.save();
          }})
          SettingSwitch({ corner: SettingCorner.LAST, icon: $r('sys.symbol.rectangle_3_group'), title: Translations.t('side_page_turn'), isOn: this.sidePageTurn, onToggle: (v: boolean) => {
            this.sidePageTurn = v; this.save();
          }})
        }
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider')})

        ListItemGroup({ header: this.groupHeader(Translations.t('section_display')) }) {
          SettingSwitch({ corner: SettingCorner.FIRST, icon: $r('sys.symbol.brightness'), title: Translations.t('keep_screen_on'), isOn: this.keepScreenOn, onToggle: (v: boolean) => {
            this.keepScreenOn = v; this.save();
          }})
          SettingSwitch({ corner: SettingCorner.MIDDLE, icon: $r('sys.symbol.play'), title: Translations.t('page_animation'), isOn: this.pageAnimation, onToggle: (v: boolean) => {
            this.pageAnimation = v; this.save();
          }})
          SettingSwitch({ corner: SettingCorner.LAST, icon: $r('sys.symbol.info_circle'), title: Translations.t('show_page_info'), isOn: this.showPageInfo, onToggle: (v: boolean) => {
            this.showPageInfo = v; this.save();
          }})
        }
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider')})

        ListItemGroup({ header: this.groupHeader(Translations.t('section_zoom')) }) {
          SettingSwitch({ corner: SettingCorner.FIRST, icon: $r('sys.symbol.magnifyingglass'), title: Translations.t('double_tap_zoom'), isOn: this.doubleTapZoom, onToggle: (v: boolean) => {
            this.doubleTapZoom = v; this.save();
          }})
          SettingSwitch({ corner: SettingCorner.LAST, icon: $r('sys.symbol.hand_tap'), title: Translations.t('long_press_zoom'), isOn: this.longPressZoom, onToggle: (v: boolean) => {
            this.longPressZoom = v; this.save();
          }})
        }
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider')})

        ListItemGroup({ header: this.groupHeader(Translations.t('section_image')) }) {
          SettingSelect({
            corner: SettingCorner.FIRST,
            icon: $r('sys.symbol.camera'),
            title: Translations.t('image_quality'),
            options: this.imageQualities,
            selectedIndex: this.imageQuality,
            onSelect: (index: number) => {
              this.imageQuality = index;
              this.save();
            }
          })
          SettingSelect({
            corner: SettingCorner.LAST,
            icon: $r('sys.symbol.square_grid_2x2'),
            title: Translations.t('image_layout'),
            options: this.imageLayoutLabels(),
            selectedIndex: this.imageLayout,
            onSelect: (index: number) => {
              this.imageLayout = index;
              this.save();
            }
          })
        }
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider')})

        ListItemGroup({ header: this.groupHeader(Translations.t('section_auto')) }) {
          SettingSelect({
            corner: SettingCorner.ALL,
            icon: $r('sys.symbol.timer'),
            title: Translations.t('auto_page_interval'),
            options: this.autoPageTimeLabels(),
            selectedIndex: this.autoPageTimes.indexOf(this.autoPageTime),
            onSelect: (index: number) => {
              this.autoPageTime = this.autoPageTimes[index];
              this.save();
            }
          })
        }
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
      .padding({ left: 16, right: 16, bottom: this.bottomAvoid + 24 })
    }
    .backgroundColor($r('app.color.bg_page'))
    .title(this.title, { backgroundColor: $r('app.color.bg_page') })   // 标题文本 + 返回按钮
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .hideTitleBar(false)
    .attributeModifier(immersiveNavModifier)
    .onBackPressed(() => {
      this.save();
      return false;
    })
    .id('readingSettingsPage')
  }
}
