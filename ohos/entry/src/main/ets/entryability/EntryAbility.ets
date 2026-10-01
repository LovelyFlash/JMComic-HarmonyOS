

// entryability/EntryAbility.ets - 入口 Ability（初始化链 + 沉浸式全屏 + 避让区 + 系统深色模式监听）
import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window, display } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { Database } from '../data/database/Database';
import { Settings } from '../data/preferences/Settings';
import { ThemeManager } from '../common/ThemeManager';
import { ReadingConfig } from '../common/ReadingConfig';
import { JmApi } from '../data/api/JmApi';

const DOMAIN = 0x0000;
const TAG = 'JMComic';

export default class EntryAbility extends UIAbility {
  private static mainWindow: window.Window | null = null;
  /** 窗口配置只做一次（启动页与主页 loadContent 回调各会调用一次） */
  private windowConfigured: boolean = false;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'Ability onCreate');
  }

  private async initAsync(): Promise<void> {
    await Settings.init(this.context);
    await Database.init(this.context);
    await ThemeManager.restore();
    // loadContent 之前应用颜色模式，避免手动策略下首帧按系统色渲染闪烁
    ThemeManager.attachApplicationContext(this.context.getApplicationContext());
    ThemeManager.applyColorModeToSystem();
    await ReadingConfig.load();
    // 必须 await：登录态/用户名从持久化恢复完成后才能加载页面，
    // 否则 MePage 首帧读到未登录（网络重登仍在 init 内后台执行，不阻塞）
    await JmApi.init();
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');
  }

  /** 读取系统深色状态并同步到主题（跟随系统策略生效） */
  private syncSystemDark(): void {
    try {
      const config = this.context.config;
      const isSystemDark = config?.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
      AppStorage.setOrCreate('systemIsDark', isSystemDark);
      ThemeManager.applySystemDark(isSystemDark);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'colorMode read failed: %{public}s', String(e));
    }
  }


  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageCreate');
    // 串行化：初始化 → 同步系统深色 → 加载启动页，避免首帧主题竞态闪烁
    this.initAsync().then(() => {
      this.syncSystemDark();
      this.loadLaunchPage(windowStage);
    }).catch((e: Object) => {
      hilog.error(DOMAIN, TAG, 'initAsync failed: %{public}s', String(e));
      // 初始化失败兜底加载页面
      this.loadMainPage(windowStage);
    });
  }

  /** 加载启动页：首帧显示后预热首 Tab（我的页）数据，最短展示达标即切换主页 */
  private loadLaunchPage(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/LaunchPage', (err: Error): void => {
      if (err) {
        hilog.error(DOMAIN, TAG, 'Failed to load launch content: %{public}s', JSON.stringify(err));
        this.loadMainPage(windowStage);
        return;
      }
      hilog.info(DOMAIN, TAG, 'Launch page loaded');
      this.setupWindow(windowStage);
      const startedAt: number = Date.now();
      // 首个 Tab（我的页）历史数据预热，完成后 MainPage 查询走页缓存
      const homeData: Promise<void> = Database.queryHistory().then(() => {
        hilog.info(DOMAIN, TAG, 'home data warm ready');
      }, (e: Object) => {
        hilog.warn(DOMAIN, TAG, 'home data warm failed: %{public}s', String(e));
      });
      const minShow: Promise<void> = new Promise<void>((resolve) => {
        setTimeout(() => {
          resolve();
        }, 600);
      });
      Promise.all([homeData, minShow]).then(() => {
        hilog.info(DOMAIN, TAG, 'launch finished in %{public}dms', Date.now() - startedAt);
        this.loadMainPage(windowStage);
      });
    });
  }

  /** 加载主页面；窗口配置在启动页阶段已完成（init 失败兜底时由本回调完成） */
  private loadMainPage(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/MainPage', (err: Error): void => {
      if (err) {
        hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Content loaded successfully');
      this.setupWindow(windowStage);
    });
  }

  /** 窗口设置（须在任一 loadContent 完成后调用，幂等） */
  private setupWindow(windowStage: window.WindowStage): void {
    if (this.windowConfigured) {
      return;
    }
    this.windowConfigured = true;
    try {
      const win: window.Window = windowStage.getMainWindowSync();
      EntryAbility.mainWindow = win;
      // 1. 沉浸式：窗口全屏布局，界面延伸至状态栏与导航条
      win.setWindowLayoutFullScreen(true).then(() => {
        hilog.info(DOMAIN, TAG, 'setWindowLayoutFullScreen success');
        EntryAbility.updateAvoidAreas(win);
        // 兜底：显式恢复状态栏显示（防止上次会话阅读器隐藏状态残留）
        win.setSpecificSystemBarEnabled('status', true, false).catch((e: BusinessError) => {
          hilog.warn(DOMAIN, TAG, 'restore status bar failed: %{public}s', String(e.code));
        });
      }).catch((e: BusinessError) => {
        hilog.error(DOMAIN, TAG, 'setWindowLayoutFullScreen failed: %{public}s', String(e.code));
      });
      // 2. 监听避让区变化（旋转/分屏/折叠）
      win.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
        EntryAbility.updateAvoidAreas(win);
      });
      // 3. 主题切换时联动系统栏字色
      ThemeManager.systemBarNotifier = (dark: boolean) => {
        EntryAbility.applySystemBarColor(dark);
      };
      // 4. 兜底再读一次系统深色状态（此时 config 必定就绪）
      this.syncSystemDark();
      // 5. 同步应用级颜色模式（须在 loadContent 之后调用），使弹窗/半模态/toast 跟随应用深色设置
      ThemeManager.attachApplicationContext(this.context.getApplicationContext());
      ThemeManager.applyColorModeToSystem();
      // 6. setColorMode 之后重设状态栏字色（色模式切换可能重置系统栏样式）
      EntryAbility.applySystemBarColor(ThemeManager.isDark);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'window setup failed: %{public}s', String(e));
    }
  }

  /** 更新避让区高度（vp）到 AppStorage，供各页面避让状态栏/导航条 */
  static updateAvoidAreas(win: window.Window): void {
    try {
      const density: number = display.getDefaultDisplaySync().densityPixels;
      const sysArea: window.AvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const navArea: window.AvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      const topVp: number = sysArea.topRect.height / density;
      const bottomVp: number = navArea.bottomRect.height / density;
      AppStorage.setOrCreate('topAvoidHeight', topVp);
      AppStorage.setOrCreate('bottomAvoidHeight', bottomVp);
      // 兼容别名（CategoryPage 等使用），与 topAvoidHeight/bottomAvoidHeight 同为 vp
      AppStorage.setOrCreate('topRectHeight', topVp);
      AppStorage.setOrCreate('bottomRectHeight', bottomVp);
      hilog.info(DOMAIN, TAG, 'avoidArea top=%{public}f bottom=%{public}f', topVp, bottomVp);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'updateAvoidAreas failed: %{public}s', String(e));
    }
  }

  /** 按深色模式设置状态栏内容颜色（深色模式浅字 / 浅色模式深字） */
  static applySystemBarColor(dark: boolean): void {
    try {
      if (EntryAbility.mainWindow !== null) {
        EntryAbility.mainWindow.setWindowSystemBarProperties({
          statusBarContentColor: dark ? '#FFFFFF' : '#000000'
        });
        // 同步窗口底色，兜底所有未绘制区域（避让条/页面根部残留），随主题即时切换
        EntryAbility.mainWindow.setWindowBackgroundColor(ThemeManager.windowBackground);
      }
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'applySystemBarColor failed: %{public}s', String(e));
    }
  }

  // 实时监听系统配置变化（深色模式切换）；
  // forced（enabled/disabled）策略下 setColorMode 会自触发本回调，须忽略以免污染真实系统状态记录
  onConfigurationUpdate(config: Configuration): void {
    try {
      const isSystemDark = config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
      hilog.info(DOMAIN, TAG, 'onConfigurationUpdate: colorMode=%{public}s', String(config.colorMode));
      if (ThemeManager.darkMode !== 'system') {
        return;
      }
      AppStorage.setOrCreate('systemIsDark', isSystemDark);
      ThemeManager.applySystemDark(isSystemDark);
    } catch (e) {
      hilog.warn(DOMAIN, TAG, 'onConfigurationUpdate failed: %{public}s', String(e));
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'Ability onBackground');
  }
}
