// data/api/ImgLineSpeedTest.ets - 图片线路测速与自动切换（并发探测最快图床）
// 候选 = 内置 4 条图床（JM_IMG_URLS，首次真正启用）+ 当前 host，去重并发 GET 固定封面计时；
// 触发点：启动自动（默认开 + 24h 保鲜，EntryAbility 后台）/ 设置页手动按钮 / 阅读图片连失败兜底（1h 冷却）。
import { Network } from '../../common/Network';
import { JmImage } from '../../common/JmImage';
import { JmApi } from './JmApi';
import { Settings } from '../preferences/Settings';
import { ApiConstants, SettingsKeys } from '../../common/Constants';
import { Logger } from '../../common/Logger';

const TAG = 'ImgLineSpeedTest';
/** 固定探测封面（真实存在，已验证各候选均返回 image/jpeg） */
const PROBE_PATH: string = '/media/albums/1203553_3x4.jpg';
/** 启动自动测速保鲜期 */
const AUTO_TTL: number = 24 * 60 * 60 * 1000;
/** 失败兜底测速冷却（距上次测速尝试不足则跳过） */
const FALLBACK_COOLDOWN: number = 60 * 60 * 1000;

/** 单线路测速结果：latency<0 或 isImage=false 视为不可用 */
export class ImgLineSpeed {
  host: string = '';
  latency: number = -1;
  isImage: boolean = false;
}

/** 测速报告：all 按延迟升序（失败排末尾），best 为最快可用线路（全部失败时为空） */
export class ImgLineSpeedReport {
  best: ImgLineSpeed = new ImgLineSpeed();
  all: ImgLineSpeed[] = [];
}

export class ImgLineSpeedTest {
  private static running: boolean = false;

  /** 自动切换开关（默认开） */
  static async autoSelectEnabled(): Promise<boolean> {
    return Settings.getBool(SettingsKeys.JM_AUTO_SELECT_IMG_LINE, true);
  }

  /** 启动自动测速：开关开 + 距上次尝试超过 24h 才跑（EntryAbility 后台调用，不阻塞启动） */
  static async autoTestOnStartup(): Promise<void> {
    if (!(await ImgLineSpeedTest.autoSelectEnabled())) {
      return;
    }
    const last: number = await Settings.getNumber(SettingsKeys.JM_IMG_SPEED_TEST_TIME, 0);
    if (Date.now() - last < AUTO_TTL) {
      return;
    }
    const report: ImgLineSpeedReport = await ImgLineSpeedTest.run();
    Logger.info(TAG, `startup auto test: host=${report.best.host} latency=${report.best.latency}` +
      ` image=${report.best.isImage}`);
  }

  /** 阅读图片连失败兜底：开关开 + 距上次测速尝试 1h 冷却（ReaderImage 双栈失败时调用） */
  static async respeedIfNeeded(): Promise<void> {
    if (ImgLineSpeedTest.running || !(await ImgLineSpeedTest.autoSelectEnabled())) {
      return;
    }
    const last: number = await Settings.getNumber(SettingsKeys.JM_IMG_SPEED_TEST_TIME, 0);
    if (Date.now() - last < FALLBACK_COOLDOWN) {
      return;
    }
    const report: ImgLineSpeedReport = await ImgLineSpeedTest.run();
    Logger.info(TAG, `failure fallback test: host=${report.best.host} latency=${report.best.latency}`);
  }

  /**
   * 测速并自动切换：并发探测候选，最快且返回真图者胜出并应用为当前 host。
   * 全部失败保留当前 host；两种情况都记录测速时间与延迟（失败记 -1，防疯狂重试 + 设置页展示）。
   * 返回完整报告供 UI 展示各节点速度（并发进行中/异常时返回空报告，best 失败且 all 为空）。
   */
  static async run(): Promise<ImgLineSpeedReport> {
    const fail: ImgLineSpeedReport = new ImgLineSpeedReport();
    if (ImgLineSpeedTest.running) {
      return fail;
    }
    ImgLineSpeedTest.running = true;
    try {
      const candidates: string[] = ImgLineSpeedTest.candidates();
      const promises: Array<Promise<ImgLineSpeed>> = [];
      for (let i = 0; i < candidates.length; i++) {
        promises.push(ImgLineSpeedTest.probe(candidates[i]));
      }
      const results: ImgLineSpeed[] = await Promise.all(promises);
      // 按延迟升序，失败（不可用）排末尾
      results.sort((a: ImgLineSpeed, b: ImgLineSpeed) => {
        const aOk: boolean = a.isImage && a.latency >= 0;
        const bOk: boolean = b.isImage && b.latency >= 0;
        if (aOk !== bOk) {
          return aOk ? -1 : 1;
        }
        return aOk ? a.latency - b.latency : 0;
      });
      const report: ImgLineSpeedReport = new ImgLineSpeedReport();
      report.all = results;
      const ok: boolean = results.length > 0 && results[0].isImage && results[0].latency >= 0;
      if (!ok) {
        // 全部失败：保留当前 host，只记时间与失败延迟
        await ImgLineSpeedTest.record(-1);
        return report;
      }
      const best: ImgLineSpeed = results[0];
      if (best.host !== JmApi.getImgHost()) {
        await JmApi.applyImgHost(best.host);
      }
      await ImgLineSpeedTest.record(best.latency);
      report.best = best;
      return report;
    } catch (e) {
      Logger.warn(TAG, `run failed: ${Logger.describe(e)}`);
      await ImgLineSpeedTest.record(-1);
      return fail;
    } finally {
      ImgLineSpeedTest.running = false;
    }
  }

  /** 候选去重：当前 host + 内置 4 条图床 */
  private static candidates(): string[] {
    const out: string[] = [];
    const seen: Set<string> = new Set<string>();
    const current: string = JmApi.getImgHost();
    if (current.length > 0 && !seen.has(current)) {
      seen.add(current);
      out.push(current);
    }
    for (let i = 0; i < ApiConstants.JM_IMG_URLS.length; i++) {
      const host: string = ApiConstants.JM_IMG_URLS[i];
      if (!seen.has(host)) {
        seen.add(host);
        out.push(host);
      }
    }
    return out;
  }

  /** 探测单线路：GET 固定封面计时；200 且魔数为真图才算可用（防反爬 HTML 混入） */
  private static async probe(host: string): Promise<ImgLineSpeed> {
    const r: ImgLineSpeed = new ImgLineSpeed();
    r.host = host;
    const started: number = Date.now();
    try {
      const bytes: Uint8Array | null = await Network.getBytes(
        `${host}${PROBE_PATH}`, JmImage.imgHeaders());
      r.latency = Date.now() - started;
      r.isImage = bytes !== null && JmImage.looksLikeImage(bytes);
      if (!r.isImage) {
        r.latency = -1;
      }
    } catch (e) {
      r.latency = -1;
      r.isImage = false;
    }
    return r;
  }

  /** 持久化测速时间与延迟 + 广播（设置页延迟展示实时刷新） */
  private static async record(latency: number): Promise<void> {
    try {
      await Settings.putNumber(SettingsKeys.JM_IMG_SPEED_TEST_TIME, Date.now());
      await Settings.putNumber(SettingsKeys.JM_IMG_SPEED_LATENCY, latency);
      const prev: number | undefined = AppStorage.get<number>('imgSpeedChanged');
      AppStorage.setOrCreate('imgSpeedChanged', prev === undefined ? 1 : prev + 1);
    } catch (e) {
      Logger.warn(TAG, `record failed: ${Logger.describe(e)}`);
    }
  }
}
