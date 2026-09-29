

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

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, 'Ability onCreate');
  }

  private async initAsync(): Promise<void> {
    await Settings.init(this.context);
    await Database.init(this.context);
    await ThemeManager.restore();
    await ReadingConfig.load();
    JmApi.init();
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
    // 串行化：初始化 → 同步系统深色 → 加载页面，避免首帧主题竞态闪烁
    this.initAsync().then(() => {
      this.syncSystemDark();
      this.loadMainPage(windowStage);
    }).catch((e: Object) => {
      hilog.error(DOMAIN, TAG, 'initAsync failed: %{public}s', String(e));
      // 初始化失败也要兜底加载页面
      this.loadMainPage(windowStage);
    });
  }

  /** 加载主页面；loadContent 回调承载窗口设置（须在初始化完成后调用） */
  private loadMainPage(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/MainPage', (err: Error): void => {
      if (err) {
        hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Content loaded successfully');
      try {
        const win: window.Window = windowStage.getMainWindowSync();
        EntryAbility.mainWindow = win;
        // 1. 沉浸式：窗口全屏布局，界面延伸至状态栏与导航条
        win.setWindowLayoutFullScreen(true).then(() => {
          hilog.info(DOMAIN, TAG, 'setWindowLayoutFullScreen success');
          EntryAbility.updateAvoidAreas(win);
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
    });
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
        EntryAbility.mainWindow.setWindowBackgroundColor(ThemeManager.background);
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
