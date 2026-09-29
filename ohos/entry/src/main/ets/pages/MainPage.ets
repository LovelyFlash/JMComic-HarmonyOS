// pages/MainPage.ets
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { MePage } from './MePage';
import { FavoritesContent } from './FavoritesContent';
import { DiscoverPage } from './DiscoverPage';
import { CategoryPage } from './CategoryPage';
import { HdsTabs, HdsTabsController, hdsMaterial} from '@kit.UIDesignKit';

@Entry
@Component
struct MainPage {
  @State currentTab: number=0
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @StorageLink('themeVersion') themeVersion: number = 0
  @StorageProp('topAvoidHeight') topAvoid: number = 0
  @StorageProp('bottomAvoidHeight') bottomAvoid: number = 0
  @State shadowGlow: number = 0.25;
  private controller: HdsTabsController = new HdsTabsController();

  build() {
    Navigation(NavUtil.stack) {
        // 底部 Tab 导航栏，使用 HdsTabs 组件
        HdsTabs({
          controller: this.controller,
          index: this.currentTab
        }) {
          // Tab 0 - 首页
          TabContent() {
            Stack({ alignContent: Alignment.Bottom }){MePage()}
          }.tabBar(this.TabBarContent(0))
          // Tab 1 - 收藏
          TabContent() {
            Stack({ alignContent: Alignment.Bottom }){FavoritesContent()}
          }.tabBar(this.TabBarContent(1))
          // Tab 2 - 探索
          TabContent() {
            Stack({ alignContent: Alignment.Bottom }){DiscoverPage()}
          }.tabBar(this.TabBarContent(2))
          // Tab 3 - 分类
          TabContent() {
            Stack({ alignContent: Alignment.Bottom }){CategoryPage()}
          }.tabBar(this.TabBarContent(3))
        }.onAnimationStart((index :number) => {
          this.currentTab = index;})
        .onChange((index :number) => {
          this.currentTab = index;})
        .barOverlap(true)
        .vertical(false)
        .barPosition(BarPosition.End)
        .barFloatingStyle({
          barBottomMargin: 36,
          adaptToHandedness: true,
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        })
        this.FabContent()
      }
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .backgroundColor(this.themeVersion >= 0 ? ThemeManager.background : '')
    .padding({ top: this.topAvoid, bottom: this.bottomAvoid })
    .width('100%')
    .height('100%')
  }

  @Builder
  TabBarContent(currentTab:number){
    if(currentTab==0)
    Column({ space: 3 }) {
      SymbolGlyph(this.currentTab === 0 ? $r('sys.symbol.house_fill') : $r('sys.symbol.house'))
        .fontSize(22)
        .fontColor([this.currentTab === 0 ? ThemeManager.primary : ThemeManager.textTertiary])
      Text(Translations.t('tab_home'))
        .fontSize(10)
        .fontColor(this.currentTab === 0 ? ThemeManager.primary : ThemeManager.textTertiary)
    }
    else if(currentTab == 1)
    Column({ space: 3 }) {
      SymbolGlyph(this.currentTab === 1 ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
        .fontSize(22)
        .fontColor([this.currentTab === 1 ? ThemeManager.primary : ThemeManager.textTertiary])
      Text(Translations.t('tab_favorites'))
        .fontSize(10)
        .fontColor(this.currentTab === 1 ? ThemeManager.primary : ThemeManager.textTertiary)
    }
    else if(currentTab == 2)
    Column({ space: 3 }) {
      SymbolGlyph($r('sys.symbol.square_grid_2x2'))
        .fontSize(22)
        .fontColor([this.currentTab === 2 ? ThemeManager.primary : ThemeManager.textTertiary])
      Text(Translations.t('tab_explore'))
        .fontColor(this.currentTab === 2 ? ThemeManager.primary : ThemeManager.textTertiary)
        .fontSize(10)
    }
    else if(currentTab == 3)
    Column({ space: 3 }) {
      SymbolGlyph(this.currentTab === 3 ? $r('sys.symbol.folder_fill') : $r('sys.symbol.folder'))
        .fontSize(22)
        .fontColor([this.currentTab === 3 ? ThemeManager.primary : ThemeManager.textTertiary])
      Text(Translations.t('tab_category'))
        .fontSize(10)
        .fontColor(this.currentTab === 3 ? ThemeManager.primary : ThemeManager.textTertiary)
    }
  }

  @Builder
  FabContent() {
    ForEach([this.themeVersion], (v: number) => {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(22)
          .fontColor([Color.White])
      }
      .width(48)
      .height(48)
      .backgroundColor(ThemeManager.primary)
      .shadow({ radius: 12, color: 'rgba(0,0,0,0.3)', offsetX: 0, offsetY: 4 })
      .position({ right: 16, top: 12 })
      .onClick(() => { NavUtil.push('preSearch'); })
      .id('fabSearch')
    }, (v: number) => `theme-${v}`)
  }
}