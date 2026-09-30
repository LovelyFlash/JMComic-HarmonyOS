// pages/settings/JmSettings.ets - JM 设置（域名/图片分流/版本号/签到/收藏排序）- NavDestination
import { promptAction } from '@kit.ArkUI';
import { Translations } from '../../common/Translations';
import { ApiConstants, SettingsKeys } from '../../common/Constants';
import { JmApi } from '../../data/api/JmApi';
import { Settings } from '../../data/preferences/Settings';
import { Logger } from '../../common/Logger';
import { SettingSwitch } from '../../components/SettingSwitch';
import { SettingItem } from '../../components/SettingItem';
import { SettingsGroup } from '../../components/SettingsGroup';
import { SettingOptions } from '../../components/SettingOptions';
import { NavTitleBar } from '../../components/NavTitleBar';

const TAG = 'JmSettings';

@Builder
export function JmSettingsBuilder(name: string, param: object) {
  JmSettings()
}

@Component
export struct JmSettings {
  @State currentDomain: string = ''
  @State domains: string[] = []
  @State isChecking: boolean = false
  @State isUpdating: boolean = false
  @State imgLineIndex: number = 1
  @State appVersion: string = ''
  @State autoSelectDomain: boolean = true
  @State autoCheckin: boolean = false
  @State favoriteOrder: number = 0
  @State checkingIn: boolean = false
  
  @StorageProp('themeColor') themeColor: string = '#2563EB'

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

  private async checkHealth(): Promise<void> {
    if (this.isChecking) {
      return;
    }
    this.isChecking = true;
    const ok: boolean = await JmApi.healthCheck();
    this.isChecking = false;
    if (ok) {
      promptAction.showToast({ message: Translations.t('available'), duration: 1500 });
    } else {
      promptAction.showToast({ message: Translations.t('unavailable'), duration: 1500 });
    }
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
      Logger.warn(TAG, `getAppVersionCode after domain update failed: ${String(e)}`);
    }
    if (JmApi.isLoggedIn()) {
      JmApi.reLogin().catch((e: Object) => {
        Logger.warn(TAG, `reLogin after domain update failed: ${String(e)}`);
      });
    }
    this.refreshState();
  }

  private async setAutoSelectDomain(value: boolean): Promise<void> {
    this.autoSelectDomain = value;
    await Settings.setBool(SettingsKeys.JM_AUTO_SELECT_DOMAIN, value);
    if (value && JmApi.isLoggedIn()) {
      JmApi.reLogin().catch((e: Object) => {
        Logger.warn(TAG, `reLogin after autoSelectDomain on failed: ${String(e)}`);
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
        promptAction.showToast({ message: Translations.t('image_line_fallback'), duration: 1500 });
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
      promptAction.showToast({
        message: version.length > 0 ? `${Translations.t('update_version')}: ${version}` : Translations.t('error'),
        duration: 2000
      });
    } catch (e) {
      promptAction.showToast({ message: `${Translations.t('error')}: ${String(e)}`, duration: 2000 });
    }
  }

  private async setAutoCheckin(value: boolean): Promise<void> {
    this.autoCheckin = value;
    await Settings.setBool(SettingsKeys.JM_AUTO_CHECKIN, value);
    if (value && JmApi.isLoggedIn()) {
      try {
        await JmApi.dailyChk();
      } catch (e) {
        Logger.warn(TAG, `auto check-in on toggle failed: ${String(e)}`);
      }
    }
  }

  private async doCheckIn(): Promise<void> {
    if (this.checkingIn) {
      return;
    }
    if (!JmApi.isLoggedIn()) {
      promptAction.showToast({ message: Translations.t('please_login'), duration: 1500 });
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

  @Builder
  domainRow(domain: string, index: number) {
    Row({ space: 12 }) {
      Text(this.stripProtocol(domain))
        .fontSize(16)
        .fontColor(this.currentDomain === domain ? this.themeColor : $r('app.color.text_primary'))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      if (this.currentDomain === domain) {
        SymbolGlyph($r('sys.symbol.checkmark'))
          .fontSize(20)
          .fontColor([this.themeColor])
      }
    }
    .width('100%')
    .height(52)
    .padding({ left: 20, right: 20 })
    .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
    .opacity(this.autoSelectDomain ? 0.4 : 1)
    .id('domainRow' + index)
    .onClick(() => {
      if (!this.autoSelectDomain) {
        this.selectDomainAt(index);
      }
    })
  }

  @Builder
  infoRow(label: string, value: string, isPrimary: boolean) {
    Row({ space: 12 }) {
      Text(label)
        .fontSize(17)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      Text(value)
        .fontSize(14)
        .fontColor(isPrimary ? this.themeColor : $r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .constraintSize({ maxWidth: '60%' })
    }
    .width('100%')
    .height(52)
    .padding({ left: 20, right: 20 })
    .border({ width: { bottom: 0.5 }, color: $r('app.color.divider') })
    .id('infoRow' + label)
  }

  build() {
    NavDestination() {
      
        Column() {
          NavTitleBar({ title: Translations.t('jm_name') })
          Scroll() {
            Column({ space: 0 }) {
              SettingsGroup({ title: Translations.t('api_line') }) {
                SettingSwitch({
                  icon: $r('sys.symbol.arrow_clockwise'),
                  title: Translations.t('auto_select_domain'),
                  isOn: this.autoSelectDomain,
                  onToggle: (value: boolean) => {
                    this.setAutoSelectDomain(value);
                  }
                })
                ForEach(this.domains, (domain: string, index: number) => {
                  this.domainRow(domain, index)
                }, (domain: string) => domain)
                this.infoRow(Translations.t('current_domain'), this.stripProtocol(this.currentDomain), true)
                SettingItem({
                  icon: $r('sys.symbol.checkmark_circle'),
                  title: Translations.t('check_domain_health'),
                  onTap: () => {
                    this.checkHealth();
                  }
                })
                SettingItem({
                  icon: $r('sys.symbol.gearshape'),
                  title: Translations.t('update_domains_remote'),
                  showDivider: false,
                  onTap: () => {
                    this.updateDomains();
                  }
                })
              }
              SettingsGroup({ title: Translations.t('image_line') }) {
                SettingOptions({
                  options: [`${Translations.t('shunt')} 1`, `${Translations.t('shunt')} 2`, `${Translations.t('shunt')} 3`, `${Translations.t('shunt')} 4`],
                  selectedIndex: this.imgLineIndex,
                  onSelect: (index: number) => {
                    this.selectImgLine(index);
                  }
                })
              }
              SettingsGroup({ title: Translations.t('app_version') }) {
                this.infoRow(Translations.t('app_version'), this.appVersion, false)
                SettingItem({
                  icon: $r('sys.symbol.timer'),
                  title: Translations.t('update_version'),
                  showDivider: false,
                  onTap: () => {
                    this.updateVersion();
                  }
                })
              }
              SettingsGroup({ title: Translations.t('check_in') }) {
                SettingSwitch({
                  icon: $r('sys.symbol.checkmark_circle'),
                  title: Translations.t('auto_checkin'),
                  isOn: this.autoCheckin,
                  onToggle: (value: boolean) => {
                    this.setAutoCheckin(value);
                  }
                })
                SettingItem({
                  icon: $r('sys.symbol.checkmark'),
                  title: Translations.t('check_in_now'),
                  showDivider: false,
                  onTap: () => {
                    this.doCheckIn();
                  }
                })
              }
              SettingsGroup({ title: Translations.t('favorite_order') }) {
                SettingOptions({
                  options: [Translations.t('favorite_order_latest'), Translations.t('favorite_order_update')],
                  selectedIndex: this.favoriteOrder,
                  onSelect: (index: number) => {
                    this.setFavoriteOrder(index);
                  }
                })
              }
            }
            .width('100%')
            .padding({ bottom: 24 })
          }
          .width('100%').layoutWeight(1)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .width('100%').height('100%')
      
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.bg_page'))
  }
}
