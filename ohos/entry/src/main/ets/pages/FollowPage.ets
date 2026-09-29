// pages/FollowPage.ets - 追更页面 - NavDestination
import { promptAction } from '@kit.ArkUI';
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { Database, FollowItem } from '../data/database/Database';
import { NavTitleBar } from '../components/NavTitleBar';

@Builder
export function FollowPageBuilder(name: string, param: object) {
  FollowPage()
}

@Component
export struct FollowPage {
  @State follows: FollowItem[] = []
  @State loading: boolean = true
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @StorageLink('themeVersion') themeVersion: number = 0

  aboutToAppear(): void {
    this.loadData();
  }

  async loadData(): Promise<void> {
    this.loading = true;
    this.follows = await Database.queryFollows();
    this.loading = false;
  }

  removeFollow(item: FollowItem): void {
    this.getUIContext().showAlertDialog({
      title: Translations.t('unfollow'),
      message: `${Translations.t('unfollow_confirm_prefix')}${item.title}${Translations.t('unfollow_confirm_suffix')}`,
      primaryButton: {
        value: Translations.t('cancel'),
        action: () => {
        }
      },
      secondaryButton: {
        value: Translations.t('confirm'),
        fontColor: ThemeManager.danger,
        action: () => {
          Database.removeFollow(item.id, item.source).then(() => {
            promptAction.showToast({ message: Translations.t('follow_removed'), duration: 1500 });
            this.loadData();
          });
        }
      }
    });
  }

  build() {
    NavDestination() {
      ForEach([this.themeVersion], (v: number) => {
        Column({ space: 0 }) {
          NavTitleBar({ title: Translations.t('follow') })
          if (this.loading) {
            Column() {
              LoadingProgress().width(40).height(40)
            }
            .width('100%').layoutWeight(1)
            .justifyContent(FlexAlign.Center)
          } else if (this.follows.length === 0) {
            Column({ space: 12 }) {
              SymbolGlyph($r('sys.symbol.clock'))
                .fontSize(44)
                .fontColor([ThemeManager.textTertiary])
              Text(Translations.t('no_follows'))
                .fontSize(14).fontColor(ThemeManager.textSecondary)
              Text(Translations.t('follow_hint'))
                .fontSize(12).fontColor(ThemeManager.textTertiary)
            }
            .width('100%').layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            List({ space: 1 }) {
              ForEach(this.follows, (item: FollowItem) => {
                ListItem() {
                  Row({ space: 12 }) {
                    Image(item.coverUrl)
                      .width(64).height(88).objectFit(ImageFit.Cover)
                      .borderRadius(6)
                      .backgroundColor(ThemeManager.surface)
                    Column({ space: 6 }) {
                      Row({ space: 6 }) {
                        Text(item.title)
                          .fontSize(15).fontWeight(FontWeight.Medium)
                          .fontColor(ThemeManager.textPrimary)
                          .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                          .layoutWeight(1)
                        if (item.hasUpdate) {
                          Text(Translations.t('has_update'))
                            .fontSize(11)
                            .fontColor('#FFFFFF')
                            .backgroundColor(ThemeManager.danger)
                            .borderRadius(8)
                            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                        }
                      }
                      Text(item.source)
                        .fontSize(12).fontColor(ThemeManager.primary)
                    }
                    .layoutWeight(1).alignItems(HorizontalAlign.Start)
                    SymbolGlyph($r('sys.symbol.xmark'))
                      .fontSize(18)
                      .fontColor([ThemeManager.textTertiary])
                      .onClick(() => {
                        this.removeFollow(item);
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
                .id('follow' + item.id + item.source + this.themeVersion)
              }, (item: FollowItem) => item.id + item.source)
            }
            .width('100%').layoutWeight(1)
            .divider({ strokeWidth: 0.5, color: ThemeManager.divider })
          }
        }
        .width('100%').height('100%')
      }, (v: number) => `theme-${v}`)
    }
    .hideTitleBar(true)
    .backgroundColor(this.themeVersion >= 0 ? ThemeManager.background : '')
  }
}
