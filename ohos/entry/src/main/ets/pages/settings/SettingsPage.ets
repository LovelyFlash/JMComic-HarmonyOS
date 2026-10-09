// pages/settings/SettingsPage.ets - 设置主页（深色下拉/主题色/首页显示 + 子设置）- NavDestination
// 主干为 List + ListItemGroup（分组 + 组内分割线），每项一行 ListItem
import { ThemeManager } from '../../common/ThemeManager';
import { Translations } from '../../common/Translations';
import { NavUtil } from '../../common/NavUtil';
import { ApiConstants, DEFAULT_THEME_COLOR, SettingsKeys } from '../../common/Constants';
import { Settings } from '../../data/preferences/Settings';
import { SettingItem } from '../../components/SettingItem';
import { SettingSwitch } from '../../components/SettingSwitch';
import { SettingSelect } from '../../components/SettingSelect';
import { SettingCorner } from '../../components/SettingCommon';
import { uiMaterial } from '@kit.ArkUI';

@Builder
export function SettingsPageBuilder(name: string, param: object) {
  SettingsPage()
}

@Component
export struct SettingsPage {
  @StorageProp('bottomAvoidHeight') bottomAvoid: number = 0
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR
  @StorageProp('darkModePolicy') darkModePolicy: string = 'system'
  @State showColorSheet: boolean = false
  @State showHistoryImages: boolean = true
  @State saveDetail: boolean = true
  @State offlineFirst: boolean = false
  @State title: string = '设置'

  aboutToAppear(): void {
    Settings.getBool(SettingsKeys.SHOW_HISTORY_IMAGES, true).then((v: boolean) => {
      this.showHistoryImages = v;
      AppStorage.setOrCreate('showHistoryImages', v);
    });
    Settings.getBool(SettingsKeys.SAVE_DETAIL_ON_DOWNLOAD, true).then((v: boolean) => {
      this.saveDetail = v;
    });
    Settings.getBool(SettingsKeys.OFFLINE_FIRST, false).then((v: boolean) => {
      this.offlineFirst = v;
    });
  }

  private darkModeIndex(): number {
    const mode = this.darkModePolicy;
    if (mode === 'enabled') {
      return 1;
    }
    if (mode === 'disabled') {
      return 2;
    }
    return 0;
  }

  private setDarkModeByIndex(index: number): void {
    if (index === 0) {
      const isSysDark = AppStorage.get<boolean>('systemIsDark') ?? false;
      ThemeManager.setDarkModePolicy('system', isSysDark);
    } else if (index === 1) {
      ThemeManager.setDarkModePolicy('enabled', false);
    } else {
      ThemeManager.setDarkModePolicy('disabled', false);
    }
  }

  private darkModeLabels(): string[] {
    return [
      Translations.t('dark_mode_system'),
      Translations.t('dark_mode_dark'),
      Translations.t('dark_mode_light')
    ];
  }

  private async setShowHistoryImages(value: boolean): Promise<void> {
    this.showHistoryImages = value;
    AppStorage.setOrCreate('showHistoryImages', value);
    await Settings.setBool(SettingsKeys.SHOW_HISTORY_IMAGES, value);
  }

  private async setSaveDetail(value: boolean): Promise<void> {
    this.saveDetail = value;
    await Settings.setBool(SettingsKeys.SAVE_DETAIL_ON_DOWNLOAD, value);
  }

  private async setOfflineFirst(value: boolean): Promise<void> {
    this.offlineFirst = value;
    await Settings.setBool(SettingsKeys.OFFLINE_FIRST, value);
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

  @Builder
  colorSheetContent() {
    Column({ space: 16 }) {
      Text(Translations.t('select_theme_color'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .padding({ left: 20, top: 8 })
      Grid() {
        ForEach(ThemeManager.themePresets, (color: string) => {
          GridItem() {
            Column() {
              if (this.themeColor === color) {
                SymbolGlyph($r('sys.symbol.checkmark'))
                  .fontSize(20)
                  .fontColor([$r('app.color.text_on_brand')])
              }
            }
            .width(44).height(44)
            .borderRadius(22)
            .backgroundColor(color)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .onClick(() => {
              ThemeManager.setThemeColor(color);
              this.showColorSheet = false;
            })
          }
        }, (color: string) => color)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(16)
      .rowsGap(16)
      .width('100%')
      .height(168)
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .padding({ bottom: 32 })
    .id('colorSheet')
  }

  build() {
    NavDestination() {
      List({ space: 24 }) {
        ListItemGroup({ header: this.groupHeader(Translations.t('settings_appearance')) }) {
          SettingSelect({
            corner: SettingCorner.FIRST,
            icon: $r('sys.symbol.moon'),
            title: Translations.t('dark_mode'),
            options: this.darkModeLabels(),
            selectedIndex: this.darkModeIndex(),
            onSelect: (index: number) => {
              this.setDarkModeByIndex(index);
            }
          })
          SettingItem({
            corner: SettingCorner.MIDDLE,
            icon: $r('sys.symbol.brightness'),
            title: Translations.t('theme_color'),
            onTap: () => {
              this.showColorSheet = true;
            }
          })
          SettingSwitch({
            corner: SettingCorner.LAST,
            icon: $r('sys.symbol.square_grid_2x2'),
            title: Translations.t('show_history_images'),
            isOn: this.showHistoryImages,
            onToggle: (value: boolean) => {
              this.setShowHistoryImages(value);
            }
          })
        }
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider')})

        ListItemGroup({ header: this.groupHeader(Translations.t('settings_reading')) }) {
          SettingItem({
            corner: SettingCorner.ALL,
            icon: $r('sys.symbol.list_bullet'),
            title: Translations.t('reading_settings'),
            onTap: () => {
              NavUtil.push('readingSettings');
            }
          })
        }

        ListItemGroup({ header: this.groupHeader(Translations.t('settings_comic_source')) }) {
          SettingItem({
            corner: SettingCorner.ALL,
            icon: $r('sys.symbol.arrow_clockwise'),
            title: Translations.t('jm_name'),
            onTap: () => {
              NavUtil.push('jmSettings');
            }
          })
        }

        ListItemGroup({ header: this.groupHeader(Translations.t('settings_download')) }) {
          SettingSwitch({
            corner: SettingCorner.FIRST,
            icon: $r('sys.symbol.arrow_down_circle'),
            title: Translations.t('save_detail_data'),
            isOn: this.saveDetail,
            onToggle: (value: boolean) => {
              this.setSaveDetail(value);
            }
          })
          SettingSwitch({
            corner: SettingCorner.LAST,
            icon: $r('sys.symbol.wifi'),
            title: Translations.t('offline_first'),
            isOn: this.offlineFirst,
            onToggle: (value: boolean) => {
              this.setOfflineFirst(value);
            }
          })
        }
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider')})

        ListItemGroup({ header: this.groupHeader(Translations.t('settings_system')) }) {
          SettingItem({
            corner: SettingCorner.ALL,
            icon: $r('sys.symbol.questionmark_circle'),
            title: Translations.t('about'),
            value: 'v' + ApiConstants.APP_VERSION,
            onTap: () => {
              NavUtil.push('about');
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
    .bindSheet($$this.showColorSheet, this.colorSheetContent(), {
      detents: [SheetSize.MEDIUM],
      blurStyle: BlurStyle.COMPONENT_THICK,
      showClose: false,
      scrollSizeMode: ScrollSizeMode.CONTINUOUS,
      width: '100%'
    })
    .title(this.title, { backgroundColor: $r('app.color.bg_page') })   // 设置标题文本 + 返回按钮
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .hideTitleBar(false)
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    }))
    .id('settingsPage')
  }
}
