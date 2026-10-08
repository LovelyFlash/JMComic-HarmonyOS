// pages/MainPage.ets
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { MePage } from './MePage';
import { FavoritesContent } from './FavoritesContent';
import { DiscoverPage } from './DiscoverPage';
import { CategoryPage } from './CategoryPage';
import { HdsTabs, HdsTabsAttribute, HdsTabsController, hdsMaterial} from '@kit.UIDesignKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { DEFAULT_THEME_COLOR } from '../common/Constants';

/** 页签栏悬浮样式修饰器：barFloatingStyle 自 API 6.1.0(23) 起可用，低版本设备降级为常规底栏 */
class TabsFloatingModifier implements AttributeModifier<HdsTabsAttribute> {
  applyNormalAttribute(instance: HdsTabsAttribute): void {
    if (deviceInfo.sdkApiVersion >= 23) {
      instance.barFloatingStyle({
        barBottomMargin: 16,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        }
      });
    }
  }
}

@Entry
@Component
struct MainPage {
  @State currentTab: number=0
  
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR
  @StorageProp('topAvoidHeight') topAvoid: number = 0
  @StorageProp('bottomAvoidHeight') bottomAvoid: number = 0
  @State shadowGlow: number = 0.25;
  private controller: HdsTabsController = new HdsTabsController();
  private floatingModifier: TabsFloatingModifier = new TabsFloatingModifier();

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
            .height('100%')
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
          }.tabBar(this.TabBarContent(0))
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
          // Tab 1 - 收藏
          TabContent() {
            Stack({ alignContent: Alignment.Bottom }){FavoritesContent()}
            .height('100%')
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
          }.tabBar(this.TabBarContent(1))
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
          // Tab 2 - 探索
          TabContent() {
            Stack({ alignContent: Alignment.Bottom }){DiscoverPage()}
            .height('100%')
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
          }.tabBar(this.TabBarContent(2))
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
          // Tab 3 - 分类
          TabContent() {
            Stack({ alignContent: Alignment.Bottom }){CategoryPage()}
            .height('100%')
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
          }.tabBar(this.TabBarContent(3))
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
        }
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
        .onAnimationStart((index :number) => {
          this.currentTab = index;})
        .onChange((index :number) => {
          this.currentTab = index;})
        .barOverlap(true)
        .vertical(false)
        .barPosition(BarPosition.End)
        .attributeModifier(this.floatingModifier)
      }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .hideTitleBar(true)
    .mode(NavigationMode.Stack)
    .backgroundColor($r('app.color.bg_page'))
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
        .fontColor([this.currentTab === 0 ? this.themeColor : $r('app.color.text_tertiary')])
      Text(Translations.t('tab_home'))
        .fontSize(10)
        .fontColor(this.currentTab === 0 ? this.themeColor : $r('app.color.text_tertiary'))
    }
    else if(currentTab == 1)
    Column({ space: 3 }) {
      SymbolGlyph(this.currentTab === 1 ? $r('sys.symbol.heart_fill') : $r('sys.symbol.heart'))
        .fontSize(22)
        .fontColor([this.currentTab === 1 ? this.themeColor : $r('app.color.text_tertiary')])
      Text(Translations.t('tab_favorites'))
        .fontSize(10)
        .fontColor(this.currentTab === 1 ? this.themeColor : $r('app.color.text_tertiary'))
    }
    else if(currentTab == 2)
    Column({ space: 3 }) {
      SymbolGlyph($r('sys.symbol.square_grid_2x2'))
        .fontSize(22)
        .fontColor([this.currentTab === 2 ? this.themeColor : $r('app.color.text_tertiary')])
      Text(Translations.t('tab_explore'))
        .fontColor(this.currentTab === 2 ? this.themeColor : $r('app.color.text_tertiary'))
        .fontSize(10)
    }
    else if(currentTab == 3)
    Column({ space: 3 }) {
      SymbolGlyph(this.currentTab === 3 ? $r('sys.symbol.folder_fill') : $r('sys.symbol.folder'))
        .fontSize(22)
        .fontColor([this.currentTab === 3 ? this.themeColor : $r('app.color.text_tertiary')])
      Text(Translations.t('tab_category'))
        .fontSize(10)
        .fontColor(this.currentTab === 3 ? this.themeColor : $r('app.color.text_tertiary'))
    }
  }

}