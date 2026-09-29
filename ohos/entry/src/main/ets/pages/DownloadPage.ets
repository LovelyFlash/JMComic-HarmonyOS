// pages/DownloadPage.ets - 下载管理 - NavDestination
import { promptAction } from '@kit.ArkUI';
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { Database, DownloadItem } from '../data/database/Database';
import { NavTitleBar } from '../components/NavTitleBar';

@Builder
export function DownloadPageBuilder(name: string, param: object) {
  DownloadPage()
}

@Component
export struct DownloadPage {
  @State items: DownloadItem[] = []
  @State loading: boolean = true
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @StorageLink('themeVersion') themeVersion: number = 0

  aboutToAppear(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    this.loading = true;
    this.items = await Database.queryDownloads();
    this.loading = false;
  }

  removeDownload(item: DownloadItem): void {
    this.getUIContext().showAlertDialog({
      title: Translations.t('delete_download'),
      message: `${Translations.t('delete_confirm_prefix')}${item.title}${Translations.t('delete_confirm_suffix')}`,
      primaryButton: {
        value: Translations.t('cancel'),
        action: () => {
        }
      },
      secondaryButton: {
        value: Translations.t('delete'),
        fontColor: ThemeManager.danger,
        action: () => {
          Database.removeDownload(item.id, item.source).then(() => {
            promptAction.showToast({ message: Translations.t('deleted'), duration: 1500 });
            this.loadData();
          });
        }
      }
    });
  }

  @Builder
  downloadCountBadge() {
    ForEach([this.themeVersion], (v: number) => {
      Text(`${this.items.length}${Translations.t('items_suffix')}`)
        .fontSize(13).fontColor(ThemeManager.textSecondary)
    }, (v: number) => `theme-${v}`)
  }

  build() {
    NavDestination() {
      Column({ space: 0 }) {
        NavTitleBar({ title: Translations.t('download_manager'), rightContent: this.downloadCountBadge })
        if (this.loading) {
          ForEach([this.themeVersion], (v: number) => {
            Column() {
              LoadingProgress().width(40).height(40)
            }
            .width('100%').layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          }, (v: number) => `theme-${v}`)
        } else if (this.items.length === 0) {
        ForEach([this.themeVersion], (v: number) => {
          Column({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.arrow_down_circle'))
              .fontSize(44)
              .fontColor([ThemeManager.textTertiary])
            Text(Translations.t('no_downloads'))
              .fontSize(14).fontColor(ThemeManager.textSecondary)
            Text(Translations.t('download_hint'))
              .fontSize(12).fontColor(ThemeManager.textTertiary)
          }
          .width('100%').layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }, (v: number) => `theme-${v}`)
      } else {
        ForEach([this.themeVersion], (v: number) => {
          List({ space: 1 }) {
            ForEach(this.items, (item: DownloadItem) => {
              ListItem() {
                Row({ space: 12 }) {
                  Image(item.coverUrl)
                    .width(64).height(88).objectFit(ImageFit.Cover)
                    .borderRadius(6)
                    .backgroundColor(ThemeManager.surface)
                  Column({ space: 6 }) {
                    Text(item.title)
                      .fontSize(15).fontWeight(FontWeight.Medium)
                      .fontColor(ThemeManager.textPrimary)
                      .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                    Text(item.source)
                      .fontSize(12).fontColor(ThemeManager.primary)
                    if (item.downloadPath.length > 0) {
                      Text(item.downloadPath)
                        .fontSize(11).fontColor(ThemeManager.textTertiary)
                        .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')
                    }
                  }
                  .layoutWeight(1).alignItems(HorizontalAlign.Start)
                  SymbolGlyph($r('sys.symbol.trash'))
                    .fontSize(20)
                    .fontColor([ThemeManager.textTertiary])
                    .onClick(() => {
                      this.removeDownload(item);
                    })
                }
                .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 })
                .onClick(() => {
                  const param: Record<string, Object> = {
                    'comicId': item.id, 'title': item.title, 'source': item.source
                  };
                  NavUtil.push('comicDetail', param);
                })
              }
              .id('download' + item.id + item.source + this.themeVersion)
            }, (item: DownloadItem) => item.id + item.source)
          }
          .width('100%').layoutWeight(1)
          .divider({ strokeWidth: 0.5, color: ThemeManager.divider })
        }, (v: number) => `theme-${v}`)
        }
      }
      .width('100%').height('100%')
    }
    .hideTitleBar(true)
    .backgroundColor(this.themeVersion >= 0 ? ThemeManager.background : '')
  }
}
