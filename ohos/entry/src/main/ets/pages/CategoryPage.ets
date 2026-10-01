// pages/CategoryPage.ets - 分类页（禁漫固定分类 + 排行榜 + 每周推荐入口）
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { DEFAULT_THEME_COLOR } from '../common/Constants';

class CategoryEntry {
  label: string = '';
  keyword: string = '';
  constructor(label: string, keyword: string) {
    this.label = label;
    this.keyword = keyword;
  }
}

class CategorySection {
  title: string = '';
  type: string = '';
  entries: CategoryEntry[] = [];
  constructor(title: string, type: string, entries: CategoryEntry[]) {
    this.title = title;
    this.type = type;
    this.entries = entries;
  }
}

@Component
export struct CategoryPage {
  
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR
  @StorageLink('bottomRectHeight') bottomRectHeight: number = 0;

  private makeSections(): CategorySection[] {
    const list: CategorySection[] = [];
    const adult: CategoryEntry[] = [
      new CategoryEntry('最新A漫', '0'),
      new CategoryEntry('同人', 'doujin'),
      new CategoryEntry('單本', 'single'),
      new CategoryEntry('短篇', 'short'),
      new CategoryEntry('其他類', 'another'),
      new CategoryEntry('韓漫', 'hanman'),
      new CategoryEntry('美漫', 'meiman'),
      new CategoryEntry('Cosplay', 'another_cosplay'),
      new CategoryEntry('3D', '3D'),
      new CategoryEntry('禁漫漢化組', '禁漫漢化組')
    ];
    list.push(new CategorySection('成人A漫', 'category', adult));
    const theme: CategoryEntry[] = [
      new CategoryEntry('無修正', '無修正'),
      new CategoryEntry('劇情向', '劇情向'),
      new CategoryEntry('青年漫', '青年漫'),
      new CategoryEntry('校服', '校服'),
      new CategoryEntry('純愛', '純愛'),
      new CategoryEntry('人妻', '人妻'),
      new CategoryEntry('教師', '教師'),
      new CategoryEntry('百合', '百合'),
      new CategoryEntry('Yaoi', 'Yaoi'),
      new CategoryEntry('性轉', '性轉'),
      new CategoryEntry('NTR', 'NTR'),
      new CategoryEntry('女裝', '女裝'),
      new CategoryEntry('癡女', '癡女'),
      new CategoryEntry('全彩', '全彩'),
      new CategoryEntry('女性向', '女性向'),
      new CategoryEntry('完結', '完結'),
      new CategoryEntry('禁漫漢化組', '禁漫漢化組')
    ];
    list.push(new CategorySection('主題A漫', 'search', theme));
    const cosplay: CategoryEntry[] = [
      new CategoryEntry('御姐', '御姐'),
      new CategoryEntry('熟女', '熟女'),
      new CategoryEntry('巨乳', '巨乳'),
      new CategoryEntry('貧乳', '貧乳'),
      new CategoryEntry('女性支配', '女性支配'),
      new CategoryEntry('教師', '教師'),
      new CategoryEntry('女僕', '女僕'),
      new CategoryEntry('護士', '護士'),
      new CategoryEntry('泳裝', '泳裝'),
      new CategoryEntry('眼鏡', '眼鏡'),
      new CategoryEntry('連褲襪', '連褲襪'),
      new CategoryEntry('其他制服', '其他制服'),
      new CategoryEntry('兔女郎', '兔女郎')
    ];
    list.push(new CategorySection('角色扮演', 'search', cosplay));
    const play: CategoryEntry[] = [
      new CategoryEntry('群交', '群交'),
      new CategoryEntry('足交', '足交'),
      new CategoryEntry('束縛', '束縛'),
      new CategoryEntry('肛交', '肛交'),
      new CategoryEntry('阿黑顏', '阿黑顏'),
      new CategoryEntry('藥物', '藥物'),
      new CategoryEntry('扶他', '扶他'),
      new CategoryEntry('調教', '調教'),
      new CategoryEntry('野外露出', '野外露出'),
      new CategoryEntry('催眠', '催眠'),
      new CategoryEntry('自慰', '自慰'),
      new CategoryEntry('觸手', '觸手'),
      new CategoryEntry('獸交', '獸交'),
      new CategoryEntry('亞人', '亞人'),
      new CategoryEntry('怪物女孩', '怪物女孩'),
      new CategoryEntry('皮物', '皮物'),
      new CategoryEntry('ryona', 'ryona'),
      new CategoryEntry('騎大車', '騎大車')
    ];
    list.push(new CategorySection('特殊PLAY', 'search', play));
    const other: CategoryEntry[] = [
      new CategoryEntry('CG', 'CG'),
      new CategoryEntry('重口', '重口'),
      new CategoryEntry('獵奇', '獵奇'),
      new CategoryEntry('非H', '非H'),
      new CategoryEntry('血腥暴力', '血腥暴力'),
      new CategoryEntry('站長推薦', '站長推薦')
    ];
    list.push(new CategorySection('其它', 'search', other));
    return list;
  }

  @Builder
  entryChips(section: CategorySection) {
    Flex({ wrap: FlexWrap.Wrap }) {
      ForEach(section.entries, (entry: CategoryEntry) => {
        Text(entry.label)
          .fontSize(13)
          .fontColor($r('app.color.text_primary'))
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .backgroundColor($r('app.color.bg_surface'))
          .borderRadius(20)
          .margin({ right: 8, bottom: 8 })
          .onClick(() => {
            if (section.type === 'category') {
              const param: Record<string, Object> = { 'slug': entry.keyword, 'title': entry.label };
              NavUtil.push('jmCategory', param);
              } else {
              const param: Record<string, Object> = { 'keyword': entry.keyword };
              NavUtil.push('search', param);
            }
          })
          .id('chip' + section.title + entry.label)
      }, (entry: CategoryEntry) => section.title + entry.label)
    }
    .width('100%')
    .id('entryChips' + section.title)
  }

  @Builder
  entryRow(icon: Resource, label: string, onTap: () => void) {
    Row({ space: 12 }) {
      SymbolGlyph(icon)
        .fontSize(22)
        .fontColor([this.themeColor])
      Text(label)
        .fontSize(15)
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
      SymbolGlyph($r('sys.symbol.chevron_right'))
        .fontSize(16)
        .fontColor([$r('app.color.text_tertiary')])
    }
    .width('100%')
    .height(52)
    .padding({ left: 14, right: 14 })
    .backgroundColor($r('app.color.bg_surface'))
    .borderRadius(12)
    .onClick(() => { onTap(); })
    .id('entryRow' + label)
  }

  build() {
    
      Column({ space: 0 }) {
        Scroll() {
          Column({ space: 16 }) {
            ForEach(this.makeSections(), (section: CategorySection) => {
              Column({ space: 12 }) {
                Text(section.title)
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor($r('app.color.text_primary'))
                  .width('100%')
                this.entryChips(section)
              }
              .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
              .width('100%')
              .id('categorySection' + section.title)
            }, (section: CategorySection) => section.title)

            Column({ space: 12 }) {
              this.entryRow($r('sys.symbol.list_number'), Translations.t('ranking'), () => {
                const param: Record<string, Object> = {
                  'slug': '0', 'title': Translations.t('ranking'), 'order': 'mv'
                };
                NavUtil.push('jmCategory', param);
              })
              this.entryRow($r('sys.symbol.clock'), Translations.t('week_recommendation'), () => {
                NavUtil.push('jmWeek');
              })
            }
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
            .width('100%')
          }
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 96 })
        }
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
        .padding({ bottom: this.bottomRectHeight })
        .layoutWeight(1)
        .scrollBar(BarState.Off)
      }
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.bg_page'))
    
  }
}
