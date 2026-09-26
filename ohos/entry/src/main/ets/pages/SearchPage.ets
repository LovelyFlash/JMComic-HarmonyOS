// pages/SearchPage.ets - 搜索页
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../common/ThemeManager';
import { Comic } from '../data/model/Comic';
import { SearchBar } from '../components/SearchBar';
import { ComicGrid } from '../components/ComicGrid';

@Entry
@Component
struct SearchPage {
  @State keyword: string = ''
  @State comics: Comic[] = []
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  build() {
    Column() {
      // Top bar
      Row() {
        Text('<')
          .fontSize(20)
          .fontColor(this.isDarkMode ? '#4DA6FF' : '#007AFF')
          .onClick(() => { router.back(); })
        Text('搜索')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000')
          .margin({ left: 16 })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      // Search bar
      SearchBar({
        keyword: this.keyword,
        onSearch: (kw: string) => { this.keyword = kw; },
        onTextChanged: (text: string) => { this.keyword = text; }
      })
      .margin({ left: 16, right: 16, bottom: 8 })

      // Results
      if (this.comics.length === 0) {
        Column() {
          Text('输入关键词搜索漫画')
            .fontSize(14)
            .fontColor(this.isDarkMode ? '#999999' : '#666666')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        ComicGrid({ comics: this.comics, columns: 3 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
  }
}
