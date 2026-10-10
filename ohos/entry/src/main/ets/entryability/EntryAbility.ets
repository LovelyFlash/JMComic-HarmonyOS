

// entryability/EntryAbility.ets - 入口 Ability（初始化链 + 沉浸式全屏 + 避让区 + 系统深色模式监听）
import { AbilityConstant, Configuration, ConfigurationConstant, errorManager, UIAbility, Want } from '@kit.AbilityKit';
import { window, display } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { Database } from '../data/database/Database';
import { Settings } from '../data/preferences/Settings';
import { ThemeManager } from '../common/ThemeManager';
import { ReadingConfig } from '../common/ReadingConfig';
import { JmApi } from '../data/api/JmApi';
import { DetailCache } from '../data/cache/DetailCache';
import { DownloadManager } from '../data/download/DownloadManager';
import { Logger } from '../common/Logger';
import { ToastUtil } from '../common/ToastUtil';

const TAG = 'JMComic';

export default class EntryAbility extends UIAbility {
  private static mainWindow: window.Window | null = null;
  /** 窗口配置只做一次（启动页与主页 loadContent 回调各会调用一次） */
  private windowConfigured: boolean = false;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info(TAG, 'Ability onCreate');
    this.registerErrorObservers();
  }

  /** 注册全局异常观测：JS 崩溃/未捕获异常、全局线程异常统一落 Logger.error */
  private registerErrorObservers(): void {
    try {
      const observer: errorManager.ErrorObserver = {
        onUnhandledException: (errorMsg: string): void => {
          Logger.error(TAG, `unhandledException: ${errorMsg}`);
        },
        onException: (err: Error): void => {
          Logger.exception(TAG, 'exception', err);
        }
      };
      errorManager.on('error', observer);
    } catch (e) {
      Logger.warn(TAG, `error observer register failed: ${Logger.describe(e)}`);
    }
    try {
      errorManager.on('globalErrorOccurred', (reason: errorManager.GlobalError): void => {
        Logger.error(TAG, `globalError ${reason.name}: ${reason.message}\n${reason.stack ?? ''} [${reason.instanceName}]`);
      });
    } catch (e) {
      Logger.warn(TAG, `globalError observer register failed: ${Logger.describe(e)}`);
    }
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
    // 下载队列恢复：须在 JmApi.init 之后（恢复的任务立即拉起网络请求）
    DetailCache.init(this.context);
    await DownloadManager.init(this.context);
  }

  onDestroy(): void {
    Logger.info(TAG, 'Ability onDestroy');
  }

  /** 读取系统深色状态并同步到主题（跟随系统策略生效） */
  private syncSystemDark(): void {
    try {
      const config = this.context.config;
      const isSystemDark = config?.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
      AppStorage.setOrCreate('systemIsDark', isSystemDark);
      ThemeManager.applySystemDark(isSystemDark);
    } catch (e) {
      Logger.exception(TAG, 'colorMode read failed', e);
    }
  }


  onWindowStageCreate(windowStage: window.WindowStage): void {
    Logger.info(TAG, 'Ability onWindowStageCreate');
    // 串行化：初始化 → 同步系统深色 → 加载启动页，避免首帧主题竞态闪烁
    this.initAsync().then(() => {
      this.syncSystemDark();
      this.loadLaunchPage(windowStage);
    }).catch((e: Object) => {
      Logger.exception(TAG, 'initAsync failed', e);
      // 初始化失败兜底加载页面
      this.loadMainPage(windowStage);
    });
  }

  /** 加载启动页：首帧显示后预热首 Tab（我的页）数据，最短展示达标即切换主页 */
  private loadLaunchPage(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/LaunchPage', (err: Error): void => {
      if (err) {
        Logger.error(TAG, `Failed to load launch content: ${JSON.stringify(err)}`);
        this.loadMainPage(windowStage);
        return;
      }
      Logger.info(TAG, 'Launch page loaded');
      this.setupWindow(windowStage);
      const startedAt: number = Date.now();
      // 首个 Tab（我的页）历史数据预热，完成后 MainPage 查询走页缓存
      const homeData: Promise<void> = Database.queryHistory().then(() => {
        Logger.info(TAG, 'home data warm ready');
      }, (e: Object) => {
        Logger.warn(TAG, `home data warm failed: ${Logger.describe(e)}`);
      });
      const minShow: Promise<void> = new Promise<void>((resolve) => {
        setTimeout(() => {
          resolve();
        }, 600);
      });
      Promise.all([homeData, minShow]).then(() => {
        Logger.info(TAG, `launch finished in ${Date.now() - startedAt}ms`);
        this.loadMainPage(windowStage);
      });
    });
  }

  /** 加载主页面；窗口配置在启动页阶段已完成（init 失败兜底时由本回调完成） */
  private loadMainPage(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/MainPage', (err: Error): void => {
      if (err) {
        Logger.error(TAG, `Failed to load content: ${JSON.stringify(err)}`);
        return;
      }
      Logger.info(TAG, 'Content loaded successfully');
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
      // 官方 toast 调用链注入：UIContext.getPromptAction()（API 18 起 promptAction.showToast 废弃）
      ToastUtil.init(win.getUIContext());
      // 1. 沉浸式：窗口全屏布局，界面延伸至状态栏与导航条
      win.setWindowLayoutFullScreen(true).then(() => {
        Logger.info(TAG, 'setWindowLayoutFullScreen success');
        EntryAbility.updateAvoidAreas(win, 'setupWindow');
      }).catch((e: BusinessError) => {
        Logger.error(TAG, `setWindowLayoutFullScreen failed: ${String(e.code)}`);
      });
      // 2. 监听避让区变化（旋转/分屏/折叠）
      win.on('avoidAreaChange', (data: window.AvoidAreaOptions) => {
        EntryAbility.updateAvoidAreas(win, 'avoidAreaChange');
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
      Logger.exception(TAG, 'window setup failed', e);
    }
  }

  /** 更新避让区高度（vp）到 AppStorage，供各页面避让状态栏/导航条 */
  static updateAvoidAreas(win: window.Window, caller: string = 'unknown'): void {
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
      Logger.info(TAG, `avoidArea caller=${caller} density=${density} topPx=${sysArea.topRect.height} bottomPx=${navArea.bottomRect.height} topVp=${topVp.toFixed(2)} bottomVp=${bottomVp.toFixed(2)}`);
    } catch (e) {
      Logger.exception(TAG, 'updateAvoidAreas failed', e);
    }
  }

  /** 按深色模式设置状态栏内容颜色（深色模式浅字 / 浅色模式深字） */
  static applySystemBarColor(dark: boolean): void {
    try {
      if (EntryAbility.mainWindow !== null) {
        // @SuppressWarnings syscap
        EntryAbility.mainWindow.setWindowSystemBarProperties({
          statusBarContentColor: dark ? '#FFFFFF' : '#000000'
        });
        // 同步窗口底色，兜底所有未绘制区域（避让条/页面根部残留），随主题即时切换
        // @SuppressWarnings syscap
        EntryAbility.mainWindow.setWindowBackgroundColor(ThemeManager.windowBackground);
      }
    } catch (e) {
      Logger.exception(TAG, 'applySystemBarColor failed', e);
    }
  }

  // 实时监听系统配置变化（深色模式切换）；
  // forced（enabled/disabled）策略下 setColorMode 会自触发本回调，须忽略以免污染真实系统状态记录
  onConfigurationUpdate(config: Configuration): void {
    try {
      const isSystemDark = config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
      Logger.info(TAG, `onConfigurationUpdate: colorMode=${String(config.colorMode)}`);
      if (ThemeManager.darkMode !== 'system') {
        return;
      }
      AppStorage.setOrCreate('systemIsDark', isSystemDark);
      ThemeManager.applySystemDark(isSystemDark);
    } catch (e) {
      Logger.exception(TAG, 'onConfigurationUpdate failed', e);
    }
  }

  onWindowStageDestroy(): void {
    Logger.info(TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    Logger.info(TAG, 'Ability onForeground');
  }

  onBackground(): void {
    Logger.info(TAG, 'Ability onBackground');
  }
}
