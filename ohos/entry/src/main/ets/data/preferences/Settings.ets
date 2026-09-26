// data/preferences/Settings.ets - 偏好设置封装
import dataPreferences from '@ohos.data.preferences';
import { Logger } from '../../common/Logger';
import { common } from '@kit.AbilityKit';

const TAG = 'Settings';
const PREFERENCES_NAME = 'pica_settings';

export class Settings {
  private static store: dataPreferences.Preferences | null = null;
  private static initialized: boolean = false;

  static async init(context: common.UIAbilityContext): Promise<void> {
    if (Settings.initialized) return;
    try {
      Settings.store = await dataPreferences.getPreferences(context, PREFERENCES_NAME);
      Settings.initialized = true;
      Logger.info(TAG, 'Settings initialized');
    } catch (e) {
      Logger.error(TAG, `Settings init failed: ${String(e)}`);
    }
  }

  static async getString(key: string, defaultValue: string = ''): Promise<string> {
    if (!Settings.store) return defaultValue;
    try {
      const value = await Settings.store.get(key, defaultValue) as string;
      return value;
    } catch (e) {
      Logger.error(TAG, `getString failed for key=${key}: ${String(e)}`);
      return defaultValue;
    }
  }

  static async setString(key: string, value: string): Promise<void> {
    if (!Settings.store) return;
    try {
      await Settings.store.put(key, value);
      await Settings.store.flush();
    } catch (e) {
      Logger.error(TAG, `setString failed for key=${key}: ${String(e)}`);
    }
  }

  static async getBool(key: string, defaultValue: boolean = false): Promise<boolean> {
    if (!Settings.store) return defaultValue;
    try {
      const value = await Settings.store.get(key, defaultValue) as boolean;
      return value;
    } catch (e) {
      Logger.error(TAG, `getBool failed for key=${key}: ${String(e)}`);
      return defaultValue;
    }
  }

  static async setBool(key: string, value: boolean): Promise<void> {
    if (!Settings.store) return;
    try {
      await Settings.store.put(key, value);
      await Settings.store.flush();
    } catch (e) {
      Logger.error(TAG, `setBool failed for key=${key}: ${String(e)}`);
    }
  }

  static async getNumber(key: string, defaultValue: number = 0): Promise<number> {
    if (!Settings.store) return defaultValue;
    try {
      const value = await Settings.store.get(key, defaultValue) as number;
      return value;
    } catch (e) {
      Logger.error(TAG, `getNumber failed for key=${key}: ${String(e)}`);
      return defaultValue;
    }
  }

  static async setNumber(key: string, value: number): Promise<void> {
    if (!Settings.store) return;
    try {
      await Settings.store.put(key, value);
      await Settings.store.flush();
    } catch (e) {
      Logger.error(TAG, `setNumber failed for key=${key}: ${String(e)}`);
    }
  }

  static async getStringList(key: string, defaultValue: string[] = []): Promise<string[]> {
    if (!Settings.store) return defaultValue;
    try {
      const value = await Settings.store.get(key, defaultValue) as string[];
      return value;
    } catch (e) {
      Logger.error(TAG, `getStringList failed for key=${key}: ${String(e)}`);
      return defaultValue;
    }
  }

  static async putString(key: string, value: string): Promise<void> {
    if (!Settings.store) return;
    try {
      await Settings.store.put(key, value);
      await Settings.store.flush();
    } catch (e) {
      Logger.error(TAG, `putString failed for key=${key}: ${String(e)}`);
    }
  }

  static async putNumber(key: string, value: number): Promise<void> {
    if (!Settings.store) return;
    try {
      await Settings.store.put(key, value);
      await Settings.store.flush();
    } catch (e) {
      Logger.error(TAG, `putNumber failed for key=${key}: ${String(e)}`);
    }
  }

  static async putStringList(key: string, value: string[]): Promise<void> {
    if (!Settings.store) return;
    try {
      await Settings.store.put(key, value);
      await Settings.store.flush();
    } catch (e) {
      Logger.error(TAG, `putStringList failed for key=${key}: ${String(e)}`);
    }
  }
}
