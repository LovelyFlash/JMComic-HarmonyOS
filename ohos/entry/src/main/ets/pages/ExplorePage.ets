// pages/ExplorePage.ets - 探索页
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../common/ThemeManager';
import { AppData } from '../viewmodel/AppData';
import { Translations } from '../common/Translations';

interface SourceEntry {
  name: string;
  label: string;
  source: string;
  icon: string;
}

@Component
export struct ExplorePage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  private sources: SourceEntry[] = [
    { name: 'picacg', label: 'Picacg', source: 'picacg', icon: '🐱' },
    { name: 'ehentai', label: 'EHentai', source: 'ehentai', icon: '📖' },
    { name: 'jm', label: '禁漫', source: 'jm', icon: '📕' },
    { name: 'hitomi', label: 'Hitomi', source: 'hitomi', icon: '🎨' },
    { name: 'htmanga', label: '绅士漫画', source: 'htmanga', icon: '📚' },
    { name: 'nhentai', label: 'NHentai', source: 'nhentai', icon: '📘' }
  ]

  build() {
    Column() {
      // Header
      Text(Translations.t('tab_explore'))
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeManager.colors.textPrimary)
        .width('100%')
        .padding({ left: 16, top: 16, bottom: 8 })

      Text(Translations.t('app_name') + ' - ' + Translations.t('tab_explore'))
        .fontSize(14)
        .fontColor(ThemeManager.colors.textSecondary)
        .width('100%')
        .padding({ left: 16, bottom: 16 })

      // Source Grid
      Grid() {
        ForEach(this.sources, (entry: SourceEntry) => {
          GridItem() {
            Column() {
              Text(entry.icon)
                .fontSize(36)
              Text(entry.label)
                .fontSize(13)
                .fontColor(ThemeManager.colors.textPrimary)
                .margin({ top: 8 })
                .maxLines(1)
            }
            .width('100%')
            .height(100)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(ThemeManager.colors.surface)
            .borderRadius(12)
            .onClick(() => {
              AppData.currentSource = entry.source;
              router.pushUrl({
                url: `pages/${this.getSourcePage(entry.source)}`
              });
            })
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(12)
      .rowsGap(12)
      .width('100%')
      .padding(16)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeManager.colors.background)
  }

  private getSourcePage(source: string): string {
    switch (source) {
      case 'picacg': return 'picacg/PicacgHome';
      case 'ehentai': return 'ehentai/EhHome';
      case 'jm': return 'jm/JmHome';
      case 'hitomi': return 'hitomi/HitomiHome';
      case 'htmanga': return 'htcomic/HtHome';
      case 'nhentai': return 'nhentai/NhHome';
      default: return 'ExplorePage';
    }
  }
}
