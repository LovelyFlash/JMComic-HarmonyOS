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
        Text('<').fontSize(20).fontColor(this.isDarkMode ? '#4DA6FF' : '#007AFF')
          .onClick(() => { router.back(); })
        Text('HT ' + Translations.t('ht_domain_update'))
          .fontSize(18).fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000').margin({ left: 16 })
      }.width('100%').height(56).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          Text('当前域名').fontSize(13).fontColor(this.isDarkMode ? '#999999' : '#666666')
            .width('100%').padding({ left: 16, top: 56, bottom: 8 })
          Text(this.currentDomain).fontSize(15).fontColor(this.isDarkMode ? '#FFFFFF' : '#000000')
            .width('100%').padding({ left: 16, bottom: 16 })

          // Fetch remote domains
          Button(this.isLoading ? '加载中...' : '获取远程域名列表')
            .width('90%').height(44).margin({ top: 12 })
            .fontSize(14).fontColor('#FFFFFF')
            .backgroundColor(this.isLoading ? '#999999' : this.isDarkMode ? '#FFB340' : '#FF9500')
            .onClick(() => { this.fetchDomains(); })

          // Available domains
          if (this.availableDomains.length > 0) {
            Text('可用域名').fontSize(13).fontColor(this.isDarkMode ? '#999999' : '#666666')
              .width('100%').padding({ left: 16, top: 24, bottom: 8 })

            ForEach(this.availableDomains, (domain: string) => {
              Row() {
                Text(domain).fontSize(14).fontColor(
                  domain === this.currentDomain ? this.isDarkMode ? '#4DA6FF' : '#007AFF' : this.isDarkMode ? '#FFFFFF' : '#000000')
                  .layoutWeight(1)
                if (domain === this.currentDomain) {
                  Text('●').fontSize(16).fontColor(this.isDarkMode ? '#4DA6FF' : '#007AFF')
                }
              }
              .width('100%').height(52).padding({ left: 16, right: 16 })
              .backgroundColor(this.isDarkMode ? '#1C1C1E' : '#FFFFFF')
              .border({ width: { bottom: 0.5 }, color: this.isDarkMode ? '#333333' : '#E5E5EA' })
              .onClick(() => {
                AppData.htBaseUrl = domain;
                this.currentDomain = domain;
              })
            })
          }
        }
      }.layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
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
