// pages/FavoritesPage.ets - 收藏夹（连接数据库）
import { router } from '@kit.ArkUI';
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';
import { Database, FavoriteItem } from '../data/database/Database';

@Entry
@Component
struct FavoritesPage {
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @State items: FavoriteItem[] = []
  @State loading: boolean = true

  aboutToAppear(): void { this.loadData(); }

  async loadData(): Promise<void> {
    this.loading = true;
    this.items = await Database.queryFavorites();
    this.loading = false;
  }

  build() {
    Column() {
      Row() {
        Image($rawfile('icons/ic_back.svg')).width(24).height(24).objectFit(ImageFit.Contain).onClick(() => { router.back(); })
        Text(Translations.t('tab_favorites')).fontSize(22).fontWeight(FontWeight.Bold)
          .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000').margin({ left: 12 })
      }.width('100%').height(64).padding({ left: 16, right: 16 }).alignItems(VerticalAlign.Center)

      if (this.loading) { Column() { LoadingProgress().width(48).height(48) }.layoutWeight(1).justifyContent(FlexAlign.Center) }
      else if (this.items.length === 0) { Column() { Text(Translations.t('no_data')).fontSize(14).fontColor(this.isDarkMode ? '#999999' : '#666666') }.layoutWeight(1).justifyContent(FlexAlign.Center) }
      else {
        List() {
          ForEach(this.items, (item: FavoriteItem) => {
            ListItem() {
              Row() {
                Image(item.coverUrl).width(70).height(100).objectFit(ImageFit.Cover).borderRadius(6).backgroundColor('#F0F0F0')
                Column() {
                  Text(item.title).fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.isDarkMode ? '#FFFFFF' : '#000000').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
                  Text(item.source).fontSize(11).fontColor('#007AFF').margin({ top: 4 })
                }.layoutWeight(1).alignItems(HorizontalAlign.Start).margin({ left: 12 })
                Image($rawfile('icons/ic_close.svg')).width(20).height(20).objectFit(ImageFit.Contain)
                  .onClick(async () => { await Database.removeFavorite(item.id, item.source); this.loadData(); })
              }.width('100%').padding(12)
            }
          })
        }.layoutWeight(1)
      }
    }.width('100%').height('100%').backgroundColor(this.isDarkMode ? '#000000' : '#F5F5F5')
  }
}
