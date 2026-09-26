// pages/ComicDetailPage.ets - 漫画详情页
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../common/ThemeManager';
import { Comic } from '../data/model/Comic';
import { NetworkImage } from '../components/NetworkImage';

@Entry
@Component
struct ComicDetailPage {
  @State comicId: string = ''
  @State comic: Comic = new Comic()
  @StorageLink('isDarkMode') isDarkMode: boolean = false

  aboutToAppear(): void {
    const params = router.getParams() as Record<string, string>;
    if (params !== null && params !== undefined) {
      this.comicId = params['comicId'] ?? '';
      this.comic.id = this.comicId;
      this.comic.title = params['title'] ?? '未知漫画';
      this.comic.source = params['source'] ?? '';
    }
  }

  build() {
    Column() {
      // Top bar
      Row() {
        Text('<')
          .fontSize(20)
          .fontColor(ThemeManager.colors.primary)
          .onClick(() => { router.back(); })
        Text(this.comic.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(ThemeManager.colors.textPrimary)
          .layoutWeight(1)
          .margin({ left: 12 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          // Cover + Info
          Row() {
            NetworkImage({ url: this.comic.coverUrl, imgWidth: 130, imgHeight: 180, imgBorderRadius: 8 })
            Column() {
              Text(this.comic.title)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(ThemeManager.colors.textPrimary)
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              if (this.comic.author.length > 0) {
                Text('作者: ' + this.comic.author)
                  .fontSize(13)
                  .fontColor(ThemeManager.colors.textSecondary)
                  .margin({ top: 8 })
              }
              if (this.comic.likes > 0) {
                Text('❤ ' + this.comic.likes.toString())
                  .fontSize(13)
                  .fontColor('#FF3B30')
                  .margin({ top: 4 })
              }
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 16 })
          }
          .width('100%')
          .padding(16)

          // Description
          if (this.comic.description.length > 0) {
            Text(this.comic.description)
              .fontSize(14)
              .fontColor(ThemeManager.colors.textPrimary)
              .width('100%')
              .padding({ left: 16, right: 16, bottom: 16 })
          }

          // Chapters placeholder
          Text('章节列表')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(ThemeManager.colors.textPrimary)
            .width('100%')
            .padding({ left: 16, top: 16, bottom: 8 })

          Text('暂无章节数据')
            .fontSize(14)
            .fontColor(ThemeManager.colors.textSecondary)
            .width('100%')
            .padding({ left: 16, bottom: 16 })
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ThemeManager.colors.background)
  }
}
