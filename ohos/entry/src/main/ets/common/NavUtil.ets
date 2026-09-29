// common/NavUtil.ets - Navigation 路由栈单例（全项目统一导航入口）
export class NavUtil {
  private static _stack: NavPathStack = new NavPathStack();

  static get stack(): NavPathStack {
    return NavUtil._stack;
  }

  static push(name: string, param?: Object): void {
    NavUtil._stack.pushPathByName(name, param === undefined ? new Map<string, Object>() : param);
  }

  static replace(name: string, param?: Object): void {
    NavUtil._stack.replacePathByName(name, param === undefined ? new Map<string, Object>() : param);
  }

  static back(): void {
    NavUtil._stack.pop();
  }
}
