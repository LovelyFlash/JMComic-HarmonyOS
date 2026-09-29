// pages/PreSearchPage.ets - 搜索入口（历史 + 热词）- NavDestination
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { Settings } from '../data/preferences/Settings';
import { JmApi } from '../data/api/JmApi';
import { NavTitleBar } from '../components/NavTitleBar';

@Builder
export function PreSearchPageBuilder(name: string, param: object) {
  PreSearchPage()
}

@Component
export struct PreSearchPage {
  @State historyItems: string[] = []
  @State hotTags: string[] = []
  @State hotLoading: boolean = false
  @State inputText: string = ''
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @StorageLink('themeVersion') themeVersion: number = 0

  aboutToAppear(): void {
    this.loadHistory();
    this.loadHotTags();
  }

  async loadHistory(): Promise<void> {
    const raw = await Settings.getString('searchHistory', '');
    this.historyItems = raw.length > 0 ? raw.split('|') : [];
  }

  async loadHotTags(): Promise<void> {
    this.hotLoading = true;
    try {
      this.hotTags = await JmApi.getHotTags();
    } catch (e) {
      this.hotTags = [];
    }
    this.hotLoading = false;
  }

  private async clearHistory(): Promise<void> {
    await Settings.putString('searchHistory', '');
    this.historyItems = [];
  }

  private gotoSearch(kw: string): void {
    const param: Record<string, Object> = { 'keyword': kw };
    NavUtil.push('search', param);
  }

  build() {
    NavDestination() {
      ForEach([this.themeVersion], (v: number) => {
        Column({ space: 0 }) {
          NavTitleBar({ title: Translations.t('search') })
          Row({ space: 8 }) {
            SymbolGlyph($r('sys.symbol.magnifyingglass'))
              .fontSize(20)
              .fontColor([ThemeManager.textSecondary])
            TextInput({ placeholder: Translations.t('search_hint') })
              .layoutWeight(1)
              .height(36)
              .fontSize(14)
              .backgroundColor(Color.Transparent)
              .fontColor(ThemeManager.textPrimary)
              .placeholderColor(ThemeManager.textSecondary)
              .caretColor(ThemeManager.primary)
              .onChange((value: string) => { this.inputText = value; })
              .onSubmit(() => {
                if (this.inputText.length > 0) { this.gotoSearch(this.inputText); }
              })
          }
          .width('100%').height(44)
          .padding({ left: 12, right: 12 })
          .margin({ left: 16, right: 16, top: 4, bottom: 16 })
          .backgroundColor(ThemeManager.surface)
          .borderRadius(22)

          Scroll() {
            Column({ space: 20 }) {
              // 搜索历史
              if (this.historyItems.length > 0) {
                Column({ space: 12 }) {
                  Row() {
                    Text(Translations.t('search_history'))
                      .fontSize(15).fontWeight(FontWeight.Medium)
                      .fontColor(ThemeManager.textPrimary)
                      .layoutWeight(1)
                    SymbolGlyph($r('sys.symbol.trash'))
                      .fontSize(18)
                      .fontColor([ThemeManager.textTertiary])
                      .onClick(() => { this.clearHistory(); })
                  }
                  .width('100%')

                  Flex({ wrap: FlexWrap.Wrap }) {
                    ForEach(this.historyItems, (kw: string) => {
                      Text(kw)
                        .fontSize(13)
                        .fontColor(ThemeManager.textPrimary)
                        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                        .backgroundColor(ThemeManager.surfaceSecondary)
                        .borderRadius(16)
                        .margin({ right: 8, bottom: 8 })
                        .onClick(() => { this.gotoSearch(kw); })
                        .id('history' + kw + this.themeVersion)
                    }, (kw: string) => kw)
                  }
                  .width('100%')
                }
              }

              // 热门标签
              Column({ space: 12 }) {
                Row() {
                  Text(Translations.t('hot_search'))
                    .fontSize(15).fontWeight(FontWeight.Medium)
                    .fontColor(ThemeManager.textPrimary)
                    .layoutWeight(1)
                  if (this.hotLoading) {
                    LoadingProgress().width(20).height(20)
                  }
                }
                .width('100%')

                if (this.hotTags.length > 0) {
                  Flex({ wrap: FlexWrap.Wrap }) {
                    ForEach(this.hotTags.slice(0, 20), (tag: string) => {
                      Text(tag)
                        .fontSize(13)
                        .fontColor(ThemeManager.primary)
                        .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                        .backgroundColor(ThemeManager.surfaceSecondary)
                        .borderRadius(16)
                        .margin({ right: 8, bottom: 8 })
                        .onClick(() => { this.gotoSearch(tag); })
                        .id('tag' + tag + this.themeVersion)
                    }, (tag: string) => tag)
                  }
                  .width('100%')
                } else if (!this.hotLoading) {
                  Text(Translations.t('no_hot_tags'))
                    .fontSize(13)
                    .fontColor(ThemeManager.textSecondary)
                }
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: 32 })
          }
          .layoutWeight(1)
          .align(Alignment.Top)
        }
        .width('100%').height('100%')
        .backgroundColor(ThemeManager.background)
      }, (v: number) => `theme-${v}`)
    }
    .hideTitleBar(true)
    .backgroundColor(this.themeVersion >= 0 ? ThemeManager.background : '')
  }
}
