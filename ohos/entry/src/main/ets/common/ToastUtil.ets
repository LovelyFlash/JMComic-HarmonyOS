// common/ToastUtil.ets - 统一 toast 封装（官方 UIContext.getPromptAction / 空文案兜底 / 异常转日志+友好文案）
import { UIContext } from '@kit.ArkUI';
import { Logger } from './Logger';
import { Translations } from './Translations';

const TAG = 'Toast';
const DEFAULT_DURATION: number = 1500;
const ERROR_DURATION: number = 2000;

export class ToastUtil {
  /** 官方非废弃调用链：UIContext.getPromptAction().showToast()（promptAction.showToast 自 API 18 废弃） */
  private static uiContext: UIContext | null = null;

  /** 由 EntryAbility 在窗口就绪后注入 */
  static init(ctx: UIContext): void {
    ToastUtil.uiContext = ctx;
  }

  /**
   * 通用提示。特殊情况处理：
   * - 空/非法文案 → 回退通用错误文案
   * - 翻译 key 缺失 → Translations.t 自身回退 key 原文（不会空串）
   * - UIContext 未就绪（理论不可达）→ 落日志跳过
   * - showToast 自身异常 → 捕获落日志，不向上抛
   */
  static show(message: string, duration: number = DEFAULT_DURATION): void {
    const text: string = message.length > 0 ? message : Translations.t('error');
    if (ToastUtil.uiContext === null) {
      Logger.warn(TAG, 'UIContext not ready, toast skipped');
      return;
    }
    try {
      ToastUtil.uiContext.getPromptAction().showToast({ message: text, duration: duration });
    } catch (e) {
      Logger.warn(TAG, `showToast failed: ${Logger.describe(e)}`);
    }
  }

  /** 操作失败：原始异常落日志，向用户只展示统一错误文案（不暴露 String(e) 内部细节） */
  static fail(e: Object): void {
    Logger.error(TAG, `operation failed: ${Logger.describe(e)}`);
    ToastUtil.show(Translations.t('error'), ERROR_DURATION);
  }

  /** 带业务前缀的失败提示：「登录失败: 出错了」这类场景（prefix 为翻译 key） */
  static failDetail(prefix: string, e: Object): void {
    Logger.error(TAG, `${prefix} failed: ${Logger.describe(e)}`);
    ToastUtil.show(`${Translations.t(prefix)}: ${Translations.t('error')}`, ERROR_DURATION);
  }
}
