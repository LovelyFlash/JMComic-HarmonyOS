// common/ReadingConfig.ets - 阅读设置持久化
import { Settings } from '../data/preferences/Settings';
import { SettingsKeys } from './Constants';

export class ReadingConfig {
  static readMode: number = 2;
  static tapTurnPage: boolean = true;
  static invertTap: boolean = false;
  static volumeKeyTurnPage: boolean = true;
  static keepScreenOn: boolean = true;
  static pageAnimation: boolean = true;
  static showPageInfo: boolean = true;
  static doubleTapZoom: boolean = true;
  static pinchZoom: boolean = true;
  static autoPreloadNext: boolean = true;
  static preloadChapterCount: number = 1;
  static imageQuality: number = 0;
  static imageLayout: number = 0;
  static fontSize: number = 16;
  static autoPageTime: number = 5;

  static async load(): Promise<void> {
    ReadingConfig.readMode = await Settings.getNumber(SettingsKeys.READ_MODE, 2);
    ReadingConfig.tapTurnPage = await Settings.getBool(SettingsKeys.TAP_TURN_PAGE, true);
    ReadingConfig.invertTap = await Settings.getBool(SettingsKeys.INVERT_TAP, false);
    ReadingConfig.volumeKeyTurnPage = await Settings.getBool(SettingsKeys.VOLUME_KEY_TURN, true);
    ReadingConfig.keepScreenOn = await Settings.getBool(SettingsKeys.KEEP_SCREEN_ON, true);
    ReadingConfig.pageAnimation = await Settings.getBool(SettingsKeys.PAGE_ANIMATION, true);
    ReadingConfig.showPageInfo = await Settings.getBool(SettingsKeys.SHOW_PAGE_INFO, true);
    ReadingConfig.doubleTapZoom = await Settings.getBool(SettingsKeys.DOUBLE_TAP_ZOOM, true);
    ReadingConfig.pinchZoom = await Settings.getBool(SettingsKeys.PINCH_ZOOM, true);
    ReadingConfig.autoPreloadNext = await Settings.getBool(SettingsKeys.AUTO_PRELOAD_NEXT, true);
    ReadingConfig.preloadChapterCount = await Settings.getNumber(SettingsKeys.PRELOAD_CHAPTER_COUNT, 1);
    ReadingConfig.imageQuality = await Settings.getNumber(SettingsKeys.IMAGE_QUALITY, 0);
    ReadingConfig.imageLayout = await Settings.getNumber(SettingsKeys.IMAGE_LAYOUT, 0);
    ReadingConfig.fontSize = await Settings.getNumber(SettingsKeys.FONT_SIZE, 16);
    ReadingConfig.autoPageTime = await Settings.getNumber(SettingsKeys.AUTO_PAGE_TIME, 5);
    AppStorage.setOrCreate('imageQuality', ReadingConfig.imageQuality);
  }

  static async saveAll(): Promise<void> {
    await Settings.putNumberNoFlush(SettingsKeys.READ_MODE, ReadingConfig.readMode);
    await Settings.putBoolNoFlush(SettingsKeys.TAP_TURN_PAGE, ReadingConfig.tapTurnPage);
    await Settings.putBoolNoFlush(SettingsKeys.INVERT_TAP, ReadingConfig.invertTap);
    await Settings.putBoolNoFlush(SettingsKeys.VOLUME_KEY_TURN, ReadingConfig.volumeKeyTurnPage);
    await Settings.putBoolNoFlush(SettingsKeys.KEEP_SCREEN_ON, ReadingConfig.keepScreenOn);
    await Settings.putBoolNoFlush(SettingsKeys.PAGE_ANIMATION, ReadingConfig.pageAnimation);
    await Settings.putBoolNoFlush(SettingsKeys.SHOW_PAGE_INFO, ReadingConfig.showPageInfo);
    await Settings.putBoolNoFlush(SettingsKeys.DOUBLE_TAP_ZOOM, ReadingConfig.doubleTapZoom);
    await Settings.putBoolNoFlush(SettingsKeys.PINCH_ZOOM, ReadingConfig.pinchZoom);
    await Settings.putBoolNoFlush(SettingsKeys.AUTO_PRELOAD_NEXT, ReadingConfig.autoPreloadNext);
    await Settings.putNumberNoFlush(SettingsKeys.PRELOAD_CHAPTER_COUNT, ReadingConfig.preloadChapterCount);
    await Settings.putNumberNoFlush(SettingsKeys.IMAGE_QUALITY, ReadingConfig.imageQuality);
    await Settings.putNumberNoFlush(SettingsKeys.IMAGE_LAYOUT, ReadingConfig.imageLayout);
    await Settings.putNumberNoFlush(SettingsKeys.FONT_SIZE, ReadingConfig.fontSize);
    await Settings.putNumberNoFlush(SettingsKeys.AUTO_PAGE_TIME, ReadingConfig.autoPageTime);
    await Settings.flush();
    AppStorage.setOrCreate('imageQuality', ReadingConfig.imageQuality);
  }
}
