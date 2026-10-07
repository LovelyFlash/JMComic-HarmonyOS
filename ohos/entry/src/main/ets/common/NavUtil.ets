// common/NavUtil.ets - Navigation 路由栈单例（全项目统一导航入口）
import { Logger } from './Logger';

const TAG = 'Nav';

export class NavUtil {
  private static _stack: NavPathStack = new NavPathStack();

  static get stack(): NavPathStack {
    return NavUtil._stack;
  }

  static push(name: string, param?: Object): void {
    Logger.debug(TAG, `push ${name} ${NavUtil.describe(param)}`);
    NavUtil._stack.pushPathByName(name, param === undefined ? new Map<string, Object>() : param);
  }

  static replace(name: string, param?: Object): void {
    Logger.debug(TAG, `replace ${name} ${NavUtil.describe(param)}`);
    NavUtil._stack.replacePathByName(name, param === undefined ? new Map<string, Object>() : param);
  }

  static back(): void {
    Logger.debug(TAG, `back size=${NavUtil._stack.size()}`);
    NavUtil._stack.pop();
  }

  /** 路由参数摘要（仅用于日志，序列化失败时降级） */
  private static describe(param?: Object): string {
    if (param === undefined) {
      return '';
    }
    try {
      return JSON.stringify(param);
    } catch (e) {
      return '[unstringifiable]';
    }
  }
}
