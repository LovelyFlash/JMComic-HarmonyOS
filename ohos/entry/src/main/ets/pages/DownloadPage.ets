// pages/DownloadPage.ets - 下载管理（连接数据库）
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';
import { Database, DownloadItem } from '../data/database/Database';

@Entry
@Component
struct DownloadPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State items: DownloadItem[] = []
  @State loading: boolean = true

  aboutToAppear(): void { this.loadData(); }

  async loadData(): Promise<void> {
    this.loading = true;
    this.items = await Database.queryDownloads();
    this.loading = false;
  }

  build() {
    Column({ space: 8 }) {
      Row() {
        Image($rawfile('icons/ic_back.svg')).width(24).height(24).objectFit(ImageFit.Contain).onClick(() => { router.back(); })
        Text(Translations.t('download')).fontSize(22).fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF').margin({ left: 12 })
      }.width('100%').height(64).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      if (this.loading) { Column({ space: 8 }) { LoadingProgress().width(48).height(48) }.layoutWeight(1).justifyContent(FlexAlign.Center) }
      else if (this.items.length === 0) { Column({ space: 8 }) { Text(Translations.t('no_data')).fontSize(14).fontColor(this.isDarkMode ? '#8E8E93' : '#666666') }.layoutWeight(1).justifyContent(FlexAlign.Center) }
      else {
        List({ space: 1 }) {
          ForEach(this.items, (item: DownloadItem) => {
            ListItem() {
              Row() {
                Image(item.coverUrl).width(70).height(100).objectFit(ImageFit.Cover).borderRadius(6).backgroundColor('#F0F0F0')
                Column({ space: 8 }) {
                  Text(item.title).fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.isDarkMode ? '#FFFFFF' : this.isDarkMode ? '#000000' : '#FFFFFF').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
                  Text(item.source).fontSize(11).fontColor(this.isDarkMode ? '#4DA6FF' : '#007AFF').margin({ top: 4 })
                  if (item.downloadPath.length > 0) { Text(item.downloadPath).fontSize(11).fontColor(this.isDarkMode ? '#8E8E93' : '#666666').margin({ top: 2 }).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }) }
                }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 12 })
              }.width('100%').padding(12)
            }
          })
        }.layoutWeight(1)
      }
    }.width('100%').height('100%').backgroundColor(this.isDarkMode ? '#000000' : '#FFFFFF')
  }
}
