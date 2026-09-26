// pages/settings/HtSettings.ets - HT 设置（域名更新）
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../../common/ThemeManager';
import { Translations } from '../../common/Translations';
import { ApiConstants } from '../../common/Constants';
import { AppData } from '../../viewmodel/AppData';
import { Logger } from '../../common/Logger';
import { Network } from '../../common/Network';

const TAG = 'HtSettings';

@Entry
@Component
struct HtSettings {
  @State currentDomain: string = ''
  @State availableDomains: string[] = []
  @State isLoading: boolean = false
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  aboutToAppear(): void {
    this.currentDomain = AppData.htBaseUrl;
  }

  build() {
    Column() {
      Row() {
        Text('<').fontSize(20).fontColor(ThemeManager.colors.primary)
          .onClick(() => { router.back(); })
        Text('HT ' + Translations.t('ht_domain_update'))
          .fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(ThemeManager.colors.textPrimary).margin({ left: 16 })
      }.width('100%').height(56).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          Text('当前域名').fontSize(13).fontColor(ThemeManager.colors.textSecondary)
            .width('100%').padding({ left: 16, top: 56, bottom: 8 })
          Text(this.currentDomain).fontSize(15).fontColor(ThemeManager.colors.textPrimary)
            .width('100%').padding({ left: 16, bottom: 16 })

          // Fetch remote domains
          Button(this.isLoading ? '加载中...' : '获取远程域名列表')
            .width('90%').height(44).margin({ top: 12 })
            .fontSize(14).fontColor('#FFFFFF')
            .backgroundColor(this.isLoading ? '#999999' : '#FF9500')
            .onClick(() => { this.fetchDomains(); })

          // Available domains
          if (this.availableDomains.length > 0) {
            Text('可用域名').fontSize(13).fontColor(ThemeManager.colors.textSecondary)
              .width('100%').padding({ left: 16, top: 24, bottom: 8 })

            ForEach(this.availableDomains, (domain: string) => {
              Row() {
                Text(domain).fontSize(14).fontColor(
                  domain === this.currentDomain ? ThemeManager.colors.primary : ThemeManager.colors.textPrimary)
                  .layoutWeight(1)
                if (domain === this.currentDomain) {
                  Text('●').fontSize(16).fontColor(ThemeManager.colors.primary)
                }
              }
              .width('100%').height(52).padding({ left: 16, right: 16 })
              .backgroundColor(ThemeManager.colors.surface)
              .border({ width: { bottom: 0.5 }, color: ThemeManager.colors.divider })
              .onClick(() => {
                AppData.htBaseUrl = domain;
                this.currentDomain = domain;
              })
            })
          }
        }
      }.layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(ThemeManager.colors.background)
  }

  private async fetchDomains(): Promise<void> {
    this.isLoading = true;
    const data = await Network.get(ApiConstants.HT_DOMAIN_URL);
    if (data.length > 0) {
      const lines = data.split('\n');
      const domains: string[] = [];
      for (const line of lines) {
        const trimmed = line.trim();
        if (trimmed.length > 0) {
          try {
            const decoded = decodeURIComponent(trimmed);
            if (decoded.startsWith('http')) {
              domains.push(decoded);
            } else {
              domains.push(trimmed);
            }
          } catch (e) {
            domains.push(trimmed);
          }
        }
      }
      this.availableDomains = domains;
      Logger.info(TAG, `Fetched ${domains.length} HT domains`);
    }
    this.isLoading = false;
  }
}
