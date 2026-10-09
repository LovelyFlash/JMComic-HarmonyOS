// pages/settings/JmSettings.ets - JM 设置（域名/图片分流/版本号/签到/收藏排序）- NavDestination
// 主干为 List + ListItemGroup（分组 + 粘性标题 + 组内分割线）
import { Translations } from '../../common/Translations';
import { ApiConstants, DEFAULT_THEME_COLOR, SettingsKeys } from '../../common/Constants';
import { ToastUtil } from '../../common/ToastUtil';
import { JmApi } from '../../data/api/JmApi';
import { Settings } from '../../data/preferences/Settings';
import { Logger } from '../../common/Logger';
import { SettingSwitch } from '../../components/SettingSwitch';
import { SettingItem } from '../../components/SettingItem';
import { SettingSelect } from '../../components/SettingSelect';
import { SettingCheckItem } from '../../components/SettingCheckItem';
import { SettingInfoItem } from '../../components/SettingInfoItem';
import { SettingCorner } from '../../components/SettingCommon';
import { uiMaterial } from '@kit.ArkUI';

const TAG = 'JmSettings';

@Builder
export function JmSettingsBuilder(name: string, param: object) {
  JmSettings()
}

@Component
export struct JmSettings {
  @State title: string = Translations.t('jm_name')
  @State currentDomain: string = ''
  @State domains: string[] = []
  @State isUpdating: boolean = false
  @State imgLineIndex: number = 1
  @State appVersion: string = ''
  @State autoSelectDomain: boolean = true
  @State autoCheckin: boolean = false
  @State favoriteOrder: number = 0
  @State checkingIn: boolean = false
  @StorageProp('bottomAvoidHeight') bottomAvoid: number = 0
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR

  aboutToAppear(): void {
    this.refreshState();
  }

  private async refreshState(): Promise<void> {
    this.currentDomain = JmApi.getDomain();
    this.domains = JmApi.getDomains();
    this.imgLineIndex = JmApi.getImgLineIndex();
    this.appVersion = JmApi.getAppVersion();
    this.autoSelectDomain = await Settings.getBool(SettingsKeys.JM_AUTO_SELECT_DOMAIN, true);
    this.autoCheckin = await Settings.getBool(SettingsKeys.JM_AUTO_CHECKIN, false);
    this.favoriteOrder = await Settings.getNumber(SettingsKeys.JM_FAVORITE_ORDER, 0);
  }

  private async selectDomainAt(index: number): Promise<void> {
    await JmApi.selectDomainAt(index);
    this.refreshState();
  }

  private async updateDomains(): Promise<void> {
    if (this.isUpdating) {
      return;
    }
    this.isUpdating = true;
    const fetched: string[] = await JmApi.fetchDomains();
    this.isUpdating = false;
    const proposal: string[] = fetched.length > 0 ? fetched : ApiConstants.JM_FALLBACK_API_DOMAINS;
    const resultLabel: string = fetched.length > 0 ?
      Translations.t('update_domains_success') : Translations.t('update_domains_failed');
    const lines: string[] = [];
    for (let i = 0; i < proposal.length; i++) {
      lines.push(`${Translations.t('domain_label')}${i + 1}: ${proposal[i]}`);
    }
    this.getUIContext().showAlertDialog({
      title: Translations.t('jm_domain_update'),
      message: `${resultLabel}\n\n${lines.join('\n')}`,
      primaryButton: {
        value: Translations.t('cancel'),
        action: () => {
        }
      },
      secondaryButton: {
        value: Translations.t('confirm'),
        fontColor: this.themeColor,
        action: () => {
          this.applyDomainUpdate(proposal);
        }
      }
    });
  }

  private async applyDomainUpdate(proposal: string[]): Promise<void> {
    await JmApi.applyDomains(proposal);
    try {
      await JmApi.getAppVersionCode();
    } catch (e) {
      Logger.warn(TAG, `getAppVersionCode after domain update failed: ${Logger.describe(e)}`);
    }
    if (JmApi.isLoggedIn()) {
      JmApi.reLogin().catch((e: Object) => {
        Logger.warn(TAG, `reLogin after domain update failed: ${Logger.describe(e)}`);
      });
    }
    this.refreshState();
  }

  private async setAutoSelectDomain(value: boolean): Promise<void> {
    this.autoSelectDomain = value;
    await Settings.setBool(SettingsKeys.JM_AUTO_SELECT_DOMAIN, value);
    if (value && JmApi.isLoggedIn()) {
      JmApi.reLogin().catch((e: Object) => {
        Logger.warn(TAG, `reLogin after autoSelectDomain on failed: ${Logger.describe(e)}`);
      });
    }
  }

  private async selectImgLine(index: number): Promise<void> {
    if (this.imgLineIndex === index) {
      return;
    }
    if (JmApi.isLoggedIn()) {
      const ok: boolean = await JmApi.updateImgUrl(index);
      this.imgLineIndex = JmApi.getImgLineIndex();
      if (!ok) {
        ToastUtil.show(Translations.t('image_line_fallback'), 1500);
      }
    } else {
      await JmApi.setImgLineIndex(index);
      this.imgLineIndex = JmApi.getImgLineIndex();
    }
  }

  private async updateVersion(): Promise<void> {
    try {
      const version: string = await JmApi.getAppVersionCode();
      this.appVersion = JmApi.getAppVersion();
      ToastUtil.show(version.length > 0
        ? `${Translations.t('update_version')}: ${version}` : Translations.t('error'), 2000);
    } catch (e) {
      ToastUtil.failDetail('error', e);
    }
  }

  private async setAutoCheckin(value: boolean): Promise<void> {
    this.autoCheckin = value;
    await Settings.setBool(SettingsKeys.JM_AUTO_CHECKIN, value);
    if (value && JmApi.isLoggedIn()) {
      try {
        await JmApi.dailyChk();
      } catch (e) {
        Logger.warn(TAG, `auto check-in on toggle failed: ${Logger.describe(e)}`);
      }
    }
  }

  private async doCheckIn(): Promise<void> {
    if (this.checkingIn) {
      return;
    }
    if (!JmApi.isLoggedIn()) {
      ToastUtil.show(Translations.t('please_login'), 1500);
      return;
    }
    this.checkingIn = true;
    try {
      const msg: string = await JmApi.dailyChk();
      this.getUIContext().showAlertDialog({
        title: Translations.t('check_in'),
        message: msg,
        confirm: {
          value: Translations.t('confirm'),
          action: () => {
          }
        }
      });
    } catch (e) {
      this.getUIContext().showAlertDialog({
        title: Translations.t('check_in'),
        message: `${Translations.t('check_in_failed')}: ${String(e)}`,
        confirm: {
          value: Translations.t('confirm'),
          action: () => {
          }
        }
      });
    }
    this.checkingIn = false;
  }

  private async setFavoriteOrder(order: number): Promise<void> {
    if (this.favoriteOrder === order) {
      return;
    }
    this.favoriteOrder = order;
    await Settings.putNumber(SettingsKeys.JM_FAVORITE_ORDER, order);
  }

  /** 域名显示去协议前缀（存储值为 normalizeDomain 后的完整 URL，与原版显示一致） */
  private stripProtocol(url: string): string {
    return url.replace(/^https?:\/\//, '');
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

  private imgLineLabels(): string[] {
    return [
      `${Translations.t('shunt')} 1`,
      `${Translations.t('shunt')} 2`,
      `${Translations.t('shunt')} 3`,
      `${Translations.t('shunt')} 4`
    ];
  }

  build() {
    NavDestination() {
      List({ space: 24 }) {
        ListItemGroup({ header: this.groupHeader(Translations.t('api_line')) }) {
          SettingSwitch({
            corner: SettingCorner.FIRST,
            icon: $r('sys.symbol.arrow_clockwise'),
            title: Translations.t('auto_select_domain'),
            isOn: this.autoSelectDomain,
            onToggle: (value: boolean) => {
              this.setAutoSelectDomain(value);
            }
          })
          ForEach(this.domains, (domain: string, index: number) => {
            SettingCheckItem({
              title: this.stripProtocol(domain),
              selected: this.currentDomain === domain,
              interactive: !this.autoSelectDomain,
              itemId: 'domainRow' + index,
              onTap: () => {
                if (!this.autoSelectDomain) {
                  this.selectDomainAt(index);
                }
              }
            })
          }, (domain: string) => domain)
          SettingInfoItem({
            label: Translations.t('current_domain'),
            value: this.stripProtocol(this.currentDomain),
            primary: true,
            itemId: 'infoRow' + Translations.t('current_domain')
          })
          SettingItem({
            corner: SettingCorner.LAST,
            icon: $r('sys.symbol.gearshape'),
            title: Translations.t('update_domains_remote'),
            onTap: () => {
              this.updateDomains();
            }
          })
        }
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider')})

        ListItemGroup({ header: this.groupHeader(Translations.t('image_line')) }) {
          SettingSelect({
            corner: SettingCorner.ALL,
            icon: $r('sys.symbol.camera'),
            title: Translations.t('image_line'),
            options: this.imgLineLabels(),
            selectedIndex: this.imgLineIndex,
            onSelect: (index: number) => {
              this.selectImgLine(index);
            }
          })
        }

        ListItemGroup({ header: this.groupHeader(Translations.t('app_version')) }) {
          SettingInfoItem({
            label: Translations.t('app_version'),
            value: this.appVersion,
            corner: SettingCorner.FIRST,
            itemId: 'infoRow' + Translations.t('app_version')
          })
          SettingItem({
            corner: SettingCorner.LAST,
            icon: $r('sys.symbol.timer'),
            title: Translations.t('update_version'),
            onTap: () => {
              this.updateVersion();
            }
          })
        }
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider')})

        ListItemGroup({ header: this.groupHeader(Translations.t('check_in')) }) {
          SettingSwitch({
            corner: SettingCorner.FIRST,
            icon: $r('sys.symbol.checkmark_circle'),
            title: Translations.t('auto_checkin'),
            isOn: this.autoCheckin,
            onToggle: (value: boolean) => {
              this.setAutoCheckin(value);
            }
          })
          SettingItem({
            corner: SettingCorner.LAST,
            icon: $r('sys.symbol.checkmark'),
            title: Translations.t('check_in_now'),
            onTap: () => {
              this.doCheckIn();
            }
          })
        }
        .divider({ strokeWidth: 0.5, color: $r('app.color.divider')})

        ListItemGroup({ header: this.groupHeader(Translations.t('favorite_order')) }) {
          SettingSelect({
            corner: SettingCorner.ALL,
            icon: $r('sys.symbol.star'),
            title: Translations.t('favorite_order'),
            options: [Translations.t('favorite_order_latest'), Translations.t('favorite_order_update')],
            selectedIndex: this.favoriteOrder,
            onSelect: (index: number) => {
              this.setFavoriteOrder(index);
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
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    }))
    .id('jmSettingsPage')
  }
}
