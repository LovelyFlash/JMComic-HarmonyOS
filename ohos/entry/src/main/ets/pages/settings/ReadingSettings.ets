// pages/settings/ReadingSettings.ets - 阅读设置 - NavDestination
import { Translations } from '../../common/Translations';
import { ReadingConfig } from '../../common/ReadingConfig';
import { SettingSwitch } from '../../components/SettingSwitch';
import { SettingsGroup } from '../../components/SettingsGroup';
import { SettingOptions } from '../../components/SettingOptions';
import { NavTitleBar } from '../../components/NavTitleBar';

@Builder
export function ReadingSettingsBuilder(name: string, param: object) {
  ReadingSettings()
}

@Component
export struct ReadingSettings {
  
  
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

  build() {
    NavDestination() {
      
        Column() {
          NavTitleBar({ title: Translations.t('reading_settings') })
          Scroll() {
            Column({ space: 0 }) {
              SettingsGroup({ title: Translations.t('section_turn_method') }) {
                SettingOptions({
                  options: this.readModeLabels(),
                  selectedIndex: this.readMode,
                  onSelect: (index: number) => {
                    this.readMode = index;
                    this.save();
                  }
                })
              }
              SettingsGroup({ title: Translations.t('section_turn_control') }) {
                SettingSwitch({ icon: $r('sys.symbol.hand_tap'), title: Translations.t('tap_turn_page'), isOn: this.tapTurnPage, onToggle: (v: boolean) => {
                  this.tapTurnPage = v; this.save();
                }})
                SettingSwitch({ icon: $r('sys.symbol.arrowshape_turn_up_left'), title: Translations.t('invert_tap'), isOn: this.invertTap, onToggle: (v: boolean) => {
                  this.invertTap = v; this.save();
                }})
                SettingSwitch({ icon: $r('sys.symbol.speaker_wave_2'), title: Translations.t('volume_key'), isOn: this.volumeKeyTurnPage, onToggle: (v: boolean) => {
                  this.volumeKeyTurnPage = v; this.save();
                }})
                SettingSwitch({ icon: $r('sys.symbol.rectangle_3_group'), title: Translations.t('side_page_turn'), isOn: this.sidePageTurn, showDivider: false, onToggle: (v: boolean) => {
                  this.sidePageTurn = v; this.save();
                }})
              }
              SettingsGroup({ title: Translations.t('section_display') }) {
                SettingSwitch({ icon: $r('sys.symbol.brightness'), title: Translations.t('keep_screen_on'), isOn: this.keepScreenOn, onToggle: (v: boolean) => {
                  this.keepScreenOn = v; this.save();
                }})
                SettingSwitch({ icon: $r('sys.symbol.play'), title: Translations.t('page_animation'), isOn: this.pageAnimation, onToggle: (v: boolean) => {
                  this.pageAnimation = v; this.save();
                }})
                SettingSwitch({ icon: $r('sys.symbol.info_circle'), title: Translations.t('show_page_info'), isOn: this.showPageInfo, showDivider: false, onToggle: (v: boolean) => {
                  this.showPageInfo = v; this.save();
                }})
              }
              SettingsGroup({ title: Translations.t('section_zoom') }) {
                SettingSwitch({ icon: $r('sys.symbol.magnifyingglass'), title: Translations.t('double_tap_zoom'), isOn: this.doubleTapZoom, onToggle: (v: boolean) => {
                  this.doubleTapZoom = v; this.save();
                }})
                SettingSwitch({ icon: $r('sys.symbol.hand_tap'), title: Translations.t('long_press_zoom'), isOn: this.longPressZoom, showDivider: false, onToggle: (v: boolean) => {
                  this.longPressZoom = v; this.save();
                }})
              }
              SettingsGroup({ title: Translations.t('section_image') }) {
                SettingOptions({
                  options: this.imageQualities,
                  selectedIndex: this.imageQuality,
                  onSelect: (index: number) => {
                    this.imageQuality = index;
                    this.save();
                  }
                })
                SettingOptions({
                  options: this.imageLayoutLabels(),
                  selectedIndex: this.imageLayout,
                  onSelect: (index: number) => {
                    this.imageLayout = index;
                    this.save();
                  }
                })
              }
              SettingsGroup({ title: Translations.t('section_auto') }) {
                SettingOptions({
                  options: this.autoPageTimeLabels(),
                  selectedIndex: this.autoPageTimes.indexOf(this.autoPageTime),
                  onSelect: (index: number) => {
                    this.autoPageTime = this.autoPageTimes[index];
                    this.save();
                  }
                })
              }
            }.width('100%').padding({ bottom: 24 })
          }
          .width('100%').layoutWeight(1)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .width('100%').height('100%')
      
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_page'))
    .onBackPressed(() => {
      this.save();
      return false;
    })
  }
}
