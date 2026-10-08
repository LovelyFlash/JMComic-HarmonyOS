// pages/PreSearchPage.ets - 搜索入口（历史 + 热词）- NavDestination
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { Settings } from '../data/preferences/Settings';
import { JmApi } from '../data/api/JmApi';
import { ChipTokens, DEFAULT_THEME_COLOR } from '../common/Constants';
import { immersiveNavModifier } from '../common/Compat';

@Builder
export function PreSearchPageBuilder(name: string, param: object) {
  PreSearchPage()
}

@Component
export struct PreSearchPage {
  @State title: string = Translations.t('search')
  @State historyItems: string[] = []
  @State hotTags: string[] = []
  @State hotLoading: boolean = false
  @State inputText: string = ''
  
  @StorageProp('bottomAvoidHeight') bottomAvoid: number = 0
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR

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
      
        Column({ space: 0 }) {
          Column() {
            Row({ space: 8 }) {
              SymbolGlyph($r('sys.symbol.magnifyingglass'))
                .fontSize(20)
                .fontColor([$r('app.color.text_secondary')])
              TextInput({ text: this.inputText, placeholder: Translations.t('search_hint') })
                .layoutWeight(1)
                .height(36)
                .fontSize(14)
                .backgroundColor(Color.Transparent)
                .fontColor($r('app.color.text_primary'))
                .placeholderColor($r('app.color.text_secondary'))
                .caretColor(this.themeColor)
                .onChange((value: string) => { this.inputText = value; })
                .onSubmit(() => {
                  if (this.inputText.length > 0) { this.gotoSearch(this.inputText); }
                })
              if (this.inputText.length > 0) {
                SymbolGlyph($r('sys.symbol.xmark_circle_fill'))
                  .fontSize(18)
                  .fontColor([$r('app.color.text_tertiary')])
                  .onClick(() => { this.inputText = ''; })
              }
            }
            .width('100%').height(44)
            .padding({ left: 12, right: 12 })
            .backgroundColor($r('app.color.bg_fill'))
            .borderRadius(22)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 16 })

          Scroll() {
            Column({ space: 20 }) {
              // 搜索历史
              if (this.historyItems.length > 0) {
                Column({ space: 12 }) {
                  Row() {
                    Text(Translations.t('search_history'))
                      .fontSize(15).fontWeight(FontWeight.Medium)
                      .fontColor($r('app.color.text_primary'))
                      .layoutWeight(1)
                    SymbolGlyph($r('sys.symbol.trash'))
                      .fontSize(18)
                      .fontColor([$r('app.color.text_tertiary')])
                      .onClick(() => { this.clearHistory(); })
                  }
                  .width('100%')

                  Flex({ wrap: FlexWrap.Wrap }) {
                    ForEach(this.historyItems, (kw: string) => {
                      Text(kw)
                        .fontSize(ChipTokens.FONT_SIZE)
                        .fontColor($r('app.color.text_primary'))
                        .padding({
                          left: ChipTokens.PAD_H, right: ChipTokens.PAD_H,
                          top: ChipTokens.PAD_V, bottom: ChipTokens.PAD_V
                        })
                        .backgroundColor($r('app.color.bg_surface'))
                        .borderRadius(ChipTokens.RADIUS)
                        .margin({ right: ChipTokens.GAP, bottom: ChipTokens.GAP })
                        .onClick(() => { this.gotoSearch(kw); })
                        .id('searchHistory' + kw)
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
                    .fontColor($r('app.color.text_primary'))
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
                        .fontSize(ChipTokens.FONT_SIZE)
                        .fontColor(this.themeColor)
                        .padding({
                          left: ChipTokens.PAD_H, right: ChipTokens.PAD_H,
                          top: ChipTokens.PAD_V, bottom: ChipTokens.PAD_V
                        })
                        .backgroundColor($r('app.color.bg_surface'))
                        .borderRadius(ChipTokens.RADIUS)
                        .margin({ right: ChipTokens.GAP, bottom: ChipTokens.GAP })
                        .onClick(() => { this.gotoSearch(tag); })
                        .id('preSearchTag' + tag)
                    }, (tag: string) => tag)
                  }
                  .width('100%')
                } else if (!this.hotLoading) {
                  Text(Translations.t('no_hot_tags'))
                    .fontSize(13)
                    .fontColor($r('app.color.text_secondary'))
                }
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, bottom: this.bottomAvoid + 32 })
          }
          .layoutWeight(1)
          .align(Alignment.Top)
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
        }
        .width('100%').height('100%')
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .title(this.title, { backgroundColor: $r('app.color.bg_page') })
    .hideTitleBar(false)
    .backgroundColor($r('app.color.bg_page'))
    .attributeModifier(immersiveNavModifier)
  }
}
