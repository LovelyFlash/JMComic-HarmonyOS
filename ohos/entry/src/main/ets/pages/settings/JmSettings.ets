// pages/settings/JmSettings.ets - JM 设置（域名更新）
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../../common/ThemeManager';
import { Translations } from '../../common/Translations';
import { ApiConstants } from '../../common/Constants';
import { AppData } from '../../viewmodel/AppData';
import { Logger } from '../../common/Logger';
import { Network } from '../../common/Network';

const TAG = 'JmSettings';

@Entry
@Component
struct JmSettings {
  @State currentDomain: string = ''
  @State domains: string[] = []
  @State isChecking: boolean = false
  @State healthStatus: boolean[] = []
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  aboutToAppear(): void {
    this.domains = AppData.jmDomains;
    const idx = AppData.jmDomainIndex;
    if (idx >= 0 && idx < this.domains.length) {
      this.currentDomain = this.domains[idx];
    }
  }

  build() {
    Column() {
      Row() {
        Text('<').fontSize(20).fontColor(ThemeManager.colors.primary)
          .onClick(() => { router.back(); })
        Text('JM ' + Translations.t('jm_domain_update'))
          .fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(ThemeManager.colors.textPrimary).margin({ left: 16 })
      }.width('100%').height(56).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          // Current domain
          Text('当前域名').fontSize(13).fontColor(ThemeManager.colors.textSecondary)
            .width('100%').padding({ left: 16, top: 56, bottom: 8 })
          Text(this.currentDomain).fontSize(15).fontColor(ThemeManager.colors.textPrimary)
            .width('100%').padding({ left: 16, bottom: 16 })

          // Domain list
          Text('可用域名').fontSize(13).fontColor(ThemeManager.colors.textSecondary)
            .width('100%').padding({ left: 16, top: 8, bottom: 8 })

          ForEach(this.domains, (domain: string, index: number) => {
            Row() {
              Column() {
                Text(domain).fontSize(14).fontColor(
                  domain === this.currentDomain ? ThemeManager.colors.primary : ThemeManager.colors.textPrimary)
                if (index < this.healthStatus.length && this.healthStatus[index]) {
                  Text('✓ 可用').fontSize(11).fontColor('#34C759')
                } else if (index < this.healthStatus.length && !this.healthStatus[index]) {
                  Text('✗ 不可用').fontSize(11).fontColor('#FF3B30')
                }
              }.alignItems(HorizontalAlign.Start).layoutWeight(1)

              if (domain === this.currentDomain) {
                Text('●').fontSize(16).fontColor(ThemeManager.colors.primary)
              }
            }
            .width('100%').height(56).padding({ left: 16, right: 16 })
            .backgroundColor(ThemeManager.colors.surface)
            .border({ width: { bottom: 0.5 }, color: ThemeManager.colors.divider })
            .onClick(() => {
              AppData.jmDomainIndex = index;
              this.currentDomain = domain;
            })
          })

          // Health check button
          Button(this.isChecking ? '检查中...' : '检查域名健康状态')
            .width('90%').height(44).margin({ top: 24 })
            .fontSize(14).fontColor('#FFFFFF')
            .backgroundColor(this.isChecking ? '#999999' : ThemeManager.colors.primary)
            .onClick(() => { this.checkHealth(); })

          // Refresh from remote
          Button('从远程更新域名列表')
            .width('90%').height(44).margin({ top: 12 })
            .fontSize(14).fontColor('#FFFFFF')
            .backgroundColor('#FF9500')
            .onClick(() => { this.refreshDomains(); })
        }
      }.layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ThemeManager.colors.background)
  }

  private async checkHealth(): Promise<void> {
    this.isChecking = true;
    this.healthStatus = [];
    for (let i = 0; i < this.domains.length; i++) {
      const domain = this.domains[i];
      const url = `https://${domain}`;
      const ok = await Network.headCheck(url, 5000);
      this.healthStatus.push(ok);
    }
    this.isChecking = false;
    Logger.info(TAG, `Health check done: ${this.healthStatus.join(', ')}`);
  }

  private async refreshDomains(): Promise<void> {
    Logger.info(TAG, 'Refreshing JM domains from remote...');
    for (const url of ApiConstants.JM_DOMAIN_URLS) {
      const data = await Network.get(url);
      if (data.length > 0) {
        Logger.info(TAG, `Got domain data from ${url}`);
        break;
      }
    }
  }
}
