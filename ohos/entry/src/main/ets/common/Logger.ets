// common/Logger.ets - 日志管理（全局级别过滤 + 异常统一落日志）
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;

/** 日志级别：数值越小越详细，低于 minLevel 的日志被过滤 */
export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  NONE = 4
}

export class Logger {
  /** 全局最低输出级别（排障时调低；正式版可 setLevel(INFO) 降噪） */
  static minLevel: LogLevel = LogLevel.DEBUG;

  static setLevel(level: LogLevel): void {
    Logger.minLevel = level;
  }

  static debug(tag: string, msg: string): void {
    if (Logger.minLevel <= LogLevel.DEBUG) {
      hilog.debug(DOMAIN, tag, msg);
    }
  }

  static info(tag: string, msg: string): void {
    if (Logger.minLevel <= LogLevel.INFO) {
      hilog.info(DOMAIN, tag, msg);
    }
  }

  static warn(tag: string, msg: string): void {
    if (Logger.minLevel <= LogLevel.WARN) {
      hilog.warn(DOMAIN, tag, msg);
    }
  }

  static error(tag: string, msg: string): void {
    if (Logger.minLevel <= LogLevel.ERROR) {
      hilog.error(DOMAIN, tag, msg);
    }
  }

  /** 异常转可读文本（日志用）：Error 取 stack（回退 message），其余 JSON 化，兜底 String() */
  static describe(e: Object): string {
    if (e instanceof Error) {
      const err: Error = e;
      return err.stack !== undefined && err.stack.length > 0 ? err.stack : err.message;
    }
    try {
      const s: string = JSON.stringify(e);
      if (s.length > 2) {
        return s;
      }
    } catch (ser) {
      // 序列化失败（循环引用等）走 String 兜底
    }
    return String(e);
  }

  /** 异常统一落日志（error 级，带前缀） */
  static exception(tag: string, prefix: string, e: Object): void {
    if (Logger.minLevel > LogLevel.ERROR) {
      return;
    }
    hilog.error(DOMAIN, tag, `${prefix}: ${Logger.describe(e)}`);
  }
}
