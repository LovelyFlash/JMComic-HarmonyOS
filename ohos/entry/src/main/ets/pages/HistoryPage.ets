// pages/HistoryPage.ets - 阅读历史（连接数据库）
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';
import { Database, HistoryItem } from '../data/database/Database';

@Entry
@Component
struct HistoryPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State items: HistoryItem[] = []
  @State loading: boolean = true

  aboutToAppear(): void { this.loadData(); }

  async loadData(): Promise<void> {
    this.loading = true;
    this.items = await Database.queryHistory();
    this.loading = false;
  }

  build() {
    Column() {
      Row() {
        Image($rawfile('icons/ic_back.svg')).width(24).height(24).objectFit(ImageFit.Contain).onClick(() => { router.back(); })
        Text(Translations.t('tab_history')).fontSize(22).fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF').margin({ left: 12 })
      }.width('100%').height(64).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      if (this.loading) { Column() { LoadingProgress().width(48).height(48) }.layoutWeight(1).justifyContent(FlexAlign.Center) }
      else if (this.items.length === 0) { Column() { Text(Translations.t('no_data')).fontSize(14).fontColor(this.isDarkMode ? '#8E8E93' : '#666666') }.layoutWeight(1).justifyContent(FlexAlign.Center) }
      else {
        List({ space: 1 }) {
          ForEach(this.items, (item: HistoryItem) => {
            ListItem() {
              Row() {
                Image(item.coverUrl).width(70).height(100).objectFit(ImageFit.Cover).borderRadius(6).backgroundColor('#F0F0F0')
                Column() {
                  Text(item.title).fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
                  if (item.lastChapter.length > 0) { Text(item.lastChapter).fontSize(12).fontColor(this.isDarkMode ? '#8E8E93' : '#666666').margin({ top: 4 }) }
                  Text(item.source).fontSize(11).fontColor(this.isDarkMode ? '#4DA6FF' : '#007AFF').margin({ top: 2 })
                }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 12 })
              }.width('100%').padding(12)
            }
          })
        }.layoutWeight(1)
      }
    }.width('100%').height('100%').backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
  }
}
