// data/download/DownloadManager.ets - 章节下载队列（下载→反打乱→编码→落盘 + 后台长时任务）
// 存储位置：优先系统公共下载目录 Download/包名（DocumentViewPicker DOWNLOAD 模式无感授权，
// 系统文件管理器可见）；未授权/失败回退沙箱 filesDir/download。旧沙箱章节目录启动后后台迁移到公共目录，
// 迁移期间双根回读（localHit/chapterDir 均先主根后旧根），detail 封面子目录仍留沙箱。
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { bundleManager, common, wantAgent, WantAgent } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { image } from '@kit.ImageKit';
import { util } from '@kit.ArkTS';
import fs from '@ohos.file.fs';
import { fileUri, picker } from '@kit.CoreFileKit';
import { ChapterTask, ChapterDlStatus, Database } from '../database/Database';
import { Chapter } from '../model/Chapter';
import { Comic } from '../model/Comic';
import { DetailCache } from '../cache/DetailCache';
import { ImageCache } from '../cache/ImageCache';
import { JmApi } from '../api/JmApi';
import { JmImage } from '../../common/JmImage';
import { Network } from '../../common/Network';
import { Logger } from '../../common/Logger';
import { Translations } from '../../common/Translations';
import { Settings } from '../preferences/Settings';
import { SettingsKeys } from '../../common/Constants';

const TAG = 'Download';
/** 旧沙箱根目录名（filesDir/download/{photoId}/{文件名}，路径由图片 URL 推导，与漫画 id 无关） */
const ROOT_DIR = 'download';
/** 公共下载目录授权等待上限（DOWNLOAD 模式应无 UI 即返回；超时按失败回退沙箱根） */
const PUBLIC_ROOT_TIMEOUT = 6000;
/** 旧沙箱根下的详情封面子目录名（不参与章节迁移；与 DetailCache/CacheManager 口径一致） */
const DETAIL_SUBDIR = 'detail';
/** 章节级并发上限：章内页串行，最多同时跑两章 */
const MAX_ACTIVE = 2;
/** 落盘 JPEG 质量：下载时已反打乱，阅读端直接解码，取接近原图的质量 */
const PACK_QUALITY = 92;
/** 实况窗进度发布节流（毫秒）：dataTransfer 长时任务 10 分钟内必须有进度更新，2s 节流足够 */
const PUBLISH_INTERVAL = 2000;

export class DownloadManager {
  private static ctx: common.UIAbilityContext | null = null;
  /** 主根：公共下载目录（成功授权后切换），失败回退 = legacyRoot */
  private static filesRoot: string = '';
  /** 旧沙箱根（filesDir/download）：迁移完成前双根回读；detail 封面始终在其下 */
  private static legacyRoot: string = '';
  private static readonly PAGES_FILE: string = 'pages.json';
  private static initialized: boolean = false;
  private static queue: ChapterTask[] = [];
  private static active: Map<string, ChapterTask> = new Map();
  private static listeners: Array<() => void> = [];
  private static bgStarted: boolean = false;
  private static bgStarting: boolean = false;
  private static notificationId: number = -1;
  private static wantAgentObj: WantAgent | null = null;
  private static lastPublishAt: number = 0;

  /** 启动接入：恢复被杀进程中断的 RUNNING 任务（断点续传），重新拉起排队任务 */
  static async init(context: common.UIAbilityContext): Promise<void> {
    if (DownloadManager.initialized) {
      return;
    }
    DownloadManager.initialized = true;
    DownloadManager.ctx = context;
    DownloadManager.legacyRoot = `${context.filesDir}/${ROOT_DIR}`;
    DownloadManager.filesRoot = DownloadManager.legacyRoot;
    await Database.requeueInterruptedDownloads();
    const all: ChapterTask[] = await Database.queryAllChapterTasks();
    for (const task of all) {
      if (task.status === ChapterDlStatus.QUEUED) {
        DownloadManager.queue.push(task);
      }
    }
    if (DownloadManager.queue.length > 0) {
      DownloadManager.ensureBg();
      DownloadManager.pump();
    }
    Logger.info(TAG, `init done, queued=${DownloadManager.queue.length}`);
    // 公共下载目录切换（带超时兜底）+ 旧沙箱章节目录迁移；均不阻塞启动
    DownloadManager.setupPublicRootThenMigrate();
  }

  /** 主根是否为系统公共下载目录（false=沙箱回退） */
  static usingPublicRoot(): boolean {
    return DownloadManager.filesRoot.length > 0 &&
      DownloadManager.filesRoot !== DownloadManager.legacyRoot;
  }

  /** 章节目录根列表（主根 + 旧沙箱根，去重；统计/删除遍历用） */
  static chapterRoots(): string[] {
    const out: string[] = [];
    if (DownloadManager.filesRoot.length > 0) {
      out.push(DownloadManager.filesRoot);
    }
    if (DownloadManager.legacyRoot.length > 0 && DownloadManager.legacyRoot !== DownloadManager.filesRoot) {
      out.push(DownloadManager.legacyRoot);
    }
    return out;
  }

  /** 章节目录（主根；下载写入/回填 pages.json 用） */
  static chapterDir(chapterId: string): string {
    if (DownloadManager.filesRoot.length === 0 || chapterId.length === 0) {
      return '';
    }
    return `${DownloadManager.filesRoot}/${chapterId}`;
  }

  /** 解析已下载图片的本地路径：主根命中 → 旧根回退 → 都无返回 ''（迁移窗口期回读靠旧根） */
  static localHit(url: string): string {
    const primary: string = DownloadManager.localPathFor(url);
    if (primary.length > 0 && DownloadManager.localExists(primary)) {
      return primary;
    }
    const legacy: string = DownloadManager.pathFor(url, DownloadManager.legacyRoot);
    if (legacy.length > 0 && legacy !== primary && DownloadManager.localExists(legacy)) {
      return legacy;
    }
    return '';
  }

  /**
   * 公共下载目录接入（启动后台执行，带超时）：
   * ① 复用已持久化的授权 URI（持久权限跨启动有效，目录被外删则重新授权）；
   * ② 未授权则调 DocumentViewPicker DOWNLOAD 模式（官方语义：无选择界面直达 Download/包名，
   *    返回 URI 具持久写权限）。任一环节失败/超时保持沙箱根，功能不受影响。
   * 成功切换主根后把旧沙箱章节目录迁移到公共目录（rename 优先，跨分区拷贝兜底）。
   */
  private static setupPublicRootThenMigrate(): void {
    DownloadManager.setupPublicRoot().then(() => {
      if (DownloadManager.usingPublicRoot()) {
        Logger.info(TAG, `download root = public: ${DownloadManager.filesRoot}`);
        DownloadManager.migrateLegacy().then(() => {
          Logger.info(TAG, 'legacy download dir migrated');
        }, (e: Object) => {
          Logger.warn(TAG, `migrate legacy failed: ${Logger.describe(e)}`);
        });
      } else {
        Logger.info(TAG, 'download root = sandbox fallback');
      }
    }, (e: Object) => {
      Logger.warn(TAG, `setupPublicRoot rejected: ${Logger.describe(e)}`);
    });
  }

  private static async setupPublicRoot(): Promise<void> {
    try {
      const saved: string = await Settings.getString(SettingsKeys.DOWNLOAD_ROOT_URI, '');
      if (saved.length > 0) {
        const path: string = DownloadManager.uriToPath(saved);
        if (path.length > 0 && DownloadManager.localExists(path)) {
          DownloadManager.filesRoot = DownloadManager.trimSlash(path);
          return;
        }
      }
      const uri: string = await DownloadManager.requestDownloadDir();
      if (uri.length > 0) {
        const path: string = DownloadManager.uriToPath(uri);
        if (path.length > 0) {
          const root: string = DownloadManager.trimSlash(path);
          DownloadManager.ensureDir(root);
          if (DownloadManager.localExists(root)) {
            DownloadManager.filesRoot = root;
            await Settings.putString(SettingsKeys.DOWNLOAD_ROOT_URI, uri);
          }
        }
      }
    } catch (e) {
      Logger.warn(TAG, `setupPublicRoot failed, keep sandbox: ${Logger.describe(e)}`);
    }
  }

  /** DOWNLOAD 模式取公共下载目录 URI（应无 UI 直达；整体带超时防呆滞阻塞） */
  private static requestDownloadDir(): Promise<string> {
    return new Promise<string>((resolve: (uri: string) => void) => {
      let settled: boolean = false;
      const guard: number = setTimeout(() => {
        if (!settled) {
          settled = true;
          Logger.warn(TAG, 'requestDownloadDir timeout');
          resolve('');
        }
      }, PUBLIC_ROOT_TIMEOUT);
      const finish: (uri: string) => void = (uri: string) => {
        if (settled) {
          return;
        }
        settled = true;
        clearTimeout(guard);
        resolve(uri);
      };
      try {
        if (DownloadManager.ctx === null) {
          finish('');
          return;
        }
        const options: picker.DocumentSaveOptions = new picker.DocumentSaveOptions();
        options.pickerMode = picker.DocumentPickerMode.DOWNLOAD;
        const viewPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker(DownloadManager.ctx);
        viewPicker.save(options).then((uris: Array<string>) => {
          finish(uris.length > 0 ? uris[0] : '');
        }, (e: BusinessError) => {
          Logger.warn(TAG, `DOWNLOAD picker failed: ${e.code} ${e.message}`);
          finish('');
        });
      } catch (e) {
        Logger.warn(TAG, `DOWNLOAD picker throw: ${Logger.describe(e)}`);
        finish('');
      }
    });
  }

  private static uriToPath(uri: string): string {
    try {
      return new fileUri.FileUri(uri).path;
    } catch (e) {
      return '';
    }
  }

  private static trimSlash(path: string): string {
    let out: string = path;
    while (out.length > 1 && out.endsWith('/')) {
      out = out.substring(0, out.length - 1);
    }
    return out;
  }

  /** 旧沙箱章节目录 → 公共目录（迁移中断可重入：已存在的目标按拷贝合并） */
  private static async migrateLegacy(): Promise<void> {
    const legacy: string = DownloadManager.legacyRoot;
    if (legacy.length === 0 || legacy === DownloadManager.filesRoot) {
      return;
    }
    let names: string[] = [];
    try {
      if (!fs.accessSync(legacy)) {
        return;
      }
      names = fs.listFileSync(legacy);
    } catch (e) {
      return;
    }
    for (const name of names) {
      if (name === DETAIL_SUBDIR) {
        continue;
      }
      const src: string = `${legacy}/${name}`;
      const dst: string = `${DownloadManager.filesRoot}/${name}`;
      try {
        DownloadManager.ensureDir(DownloadManager.filesRoot);
        if (DownloadManager.localExists(dst)) {
          DownloadManager.copyTree(src, dst);
          DownloadManager.removePathQuiet(src);
        } else {
          fs.renameSync(src, dst);
        }
      } catch (e) {
        try {
          DownloadManager.copyTree(src, dst);
          DownloadManager.removePathQuiet(src);
        } catch (e2) {
          Logger.warn(TAG, `migrate ${name} failed: ${Logger.describe(e2)}`);
        }
      }
      // 让出事件循环，避免大目录迁移时同步 IO 卡死 UI
      await new Promise<void>((resolve: () => void) => {
        setTimeout(resolve, 0);
      });
    }
  }

  /** 目录树拷贝（文件级 copyFileSync；目标已存在的文件覆盖为旧副本，内容同 URL 同名） */
  private static copyTree(src: string, dst: string): void {
    const st: fs.Stat = fs.statSync(src);
    if (st.isDirectory()) {
      DownloadManager.ensureDir(dst);
      const children: string[] = fs.listFileSync(src);
      for (const child of children) {
        DownloadManager.copyTree(`${src}/${child}`, `${dst}/${child}`);
      }
    } else {
      const idx: number = dst.lastIndexOf('/');
      if (idx > 0) {
        DownloadManager.ensureDir(dst.substring(0, idx));
      }
      fs.copyFileSync(src, dst);
    }
  }

  /** 递归删除文件/目录（rmdirSync 对目录递归；文件走 unlinkSync） */
  private static removePathQuiet(path: string): void {
    try {
      if (path.length === 0 || !DownloadManager.localExists(path)) {
        return;
      }
      if (fs.statSync(path).isDirectory()) {
        fs.rmdirSync(path);
      } else {
        fs.unlinkSync(path);
      }
    } catch (e) {
    }
  }

  static subscribe(fn: () => void): void {
    DownloadManager.listeners.push(fn);
  }

  static unsubscribe(fn: () => void): void {
    const idx: number = DownloadManager.listeners.indexOf(fn);
    if (idx >= 0) {
      DownloadManager.listeners.splice(idx, 1);
    }
  }

  /** 入队整本漫画的选中章节；返回真正新入队的数量（DONE/RUNNING 跳过，其余保留断点重新排队）。
   *  detail 为详情页已加载的完整 Comic（可选）：用于入队后异步保存详情/封面/首页评论缓存。 */
  static async enqueueComic(comicId: string, title: string, coverUrl: string, source: string,
    chapters: Chapter[], detail?: Comic): Promise<number> {
    if (DownloadManager.filesRoot.length === 0 || chapters.length === 0) {
      return 0;
    }
    const existing: ChapterTask[] = await Database.queryChapterTasks(comicId);
    const byId: Map<string, ChapterTask> = new Map();
    for (const task of existing) {
      byId.set(task.chapterId, task);
    }
    let queued: number = 0;
    for (const chapter of chapters) {
      const found: ChapterTask | undefined = byId.get(chapter.id);
      if (found !== undefined) {
        if (found.status === ChapterDlStatus.DONE || found.status === ChapterDlStatus.RUNNING) {
          continue;
        }
        found.status = ChapterDlStatus.QUEUED;
        await Database.updateChapterTask(found);
        if (!DownloadManager.inQueue(found.chapterId, found.comicId)) {
          DownloadManager.queue.push(found);
        }
        queued++;
        continue;
      }
      const task: ChapterTask = new ChapterTask();
      task.chapterId = chapter.id;
      task.comicId = comicId;
      task.title = chapter.title;
      task.sortOrder = chapter.order;
      task.pageCount = chapter.pages;
      task.status = ChapterDlStatus.QUEUED;
      task.localDir = DownloadManager.chapterDir(chapter.id);
      await Database.upsertChapterTask(task);
      DownloadManager.queue.push(task);
      queued++;
    }
    if (queued > 0) {
      await Database.insertDownload(comicId, title, coverUrl, source, DownloadManager.filesRoot);
      // 异步保存详情/封面/首页评论（受「下载时保存详情数据」开关控制），不阻塞入队
      DetailCache.capture(comicId, source, detail).catch((e: Object) => {
        Logger.warn(TAG, `detail capture rejected: ${Logger.describe(e)}`);
      });
      // 详情可用时顺带预取相关推荐封面（离线详情页相关推荐不灰块）
      if (detail !== undefined) {
        const relatedUrls: string[] = [];
        for (const c of detail.relatedComics) {
          if (c.coverUrl.length > 0) {
            relatedUrls.push(c.coverUrl);
          }
        }
        ImageCache.prefetchCovers(relatedUrls, comicId).catch((e: Object) => {
          Logger.warn(TAG, `related cover prefetch rejected: ${Logger.describe(e)}`);
        });
      }
      DownloadManager.ensureBg();
      DownloadManager.pump();
      DownloadManager.notify();
    }
    return queued;
  }

  /** 暂停单章：内存任务改状态即可，runner 每页检查后自行停下 */
  static async pause(chapterId: string, comicId: string): Promise<void> {
    const running: ChapterTask | undefined = DownloadManager.active.get(DownloadManager.taskKey(chapterId, comicId));
    if (running !== undefined) {
      running.status = ChapterDlStatus.PAUSED;
      await Database.updateChapterTask(running);
      DownloadManager.notify();
      return;
    }
    for (const task of DownloadManager.queue) {
      if (task.chapterId === chapterId && task.comicId === comicId) {
        task.status = ChapterDlStatus.PAUSED;
        await Database.updateChapterTask(task);
        DownloadManager.notify();
        return;
      }
    }
    const stored: ChapterTask | null = await Database.queryChapterTask(chapterId, comicId);
    if (stored !== null && (stored.status === ChapterDlStatus.QUEUED || stored.status === ChapterDlStatus.RUNNING)) {
      stored.status = ChapterDlStatus.PAUSED;
      await Database.updateChapterTask(stored);
      DownloadManager.notify();
    }
  }

  /** 继续/重试单章（PAUSED、FAILED 均可），已下载页面按文件存在直接跳过 */
  static async resume(chapterId: string, comicId: string): Promise<void> {
    if (DownloadManager.active.has(DownloadManager.taskKey(chapterId, comicId))) {
      return;
    }
    const stored: ChapterTask | null = await Database.queryChapterTask(chapterId, comicId);
    if (stored === null || stored.status === ChapterDlStatus.DONE) {
      return;
    }
    stored.status = ChapterDlStatus.QUEUED;
    await Database.updateChapterTask(stored);
    if (!DownloadManager.inQueue(chapterId, comicId)) {
      DownloadManager.queue.push(stored);
    }
    DownloadManager.ensureBg();
    DownloadManager.pump();
    DownloadManager.notify();
  }

  /** 暂停整本漫画的排队与下载中章节 */
  static async pauseComic(comicId: string): Promise<void> {
    const tasks: ChapterTask[] = await Database.queryChapterTasks(comicId);
    for (const task of tasks) {
      if (task.status === ChapterDlStatus.QUEUED || task.status === ChapterDlStatus.RUNNING) {
        await DownloadManager.pause(task.chapterId, comicId);
      }
    }
  }

  /** 继续整本漫画（含失败章节重试） */
  static async resumeComic(comicId: string): Promise<void> {
    const tasks: ChapterTask[] = await Database.queryChapterTasks(comicId);
    for (const task of tasks) {
      if (task.status === ChapterDlStatus.PAUSED || task.status === ChapterDlStatus.FAILED) {
        await DownloadManager.resume(task.chapterId, comicId);
      }
    }
  }

  /** 取消单章并删除其本地文件（主根/旧沙箱根/库内存储路径全清，防迁移窗口期残留） */
  static async cancel(chapterId: string, comicId: string): Promise<void> {
    const running: ChapterTask | undefined = DownloadManager.active.get(DownloadManager.taskKey(chapterId, comicId));
    if (running !== undefined) {
      running.status = ChapterDlStatus.CANCELED;
    }
    DownloadManager.queue = DownloadManager.queue.filter(
      (task: ChapterTask) => !(task.chapterId === chapterId && task.comicId === comicId));
    const stored: ChapterTask | null = await Database.queryChapterTask(chapterId, comicId);
    const paths: string[] = [`${DownloadManager.filesRoot}/${chapterId}`];
    if (DownloadManager.legacyRoot.length > 0) {
      paths.push(`${DownloadManager.legacyRoot}/${chapterId}`);
    }
    if (stored !== null && stored.localDir.length > 0) {
      paths.push(stored.localDir);
    }
    for (const path of paths) {
      DownloadManager.removeDirQuiet(path);
    }
    await Database.removeChapterTask(chapterId, comicId);
    DownloadManager.notify();
    DownloadManager.maybeStopBg();
  }

  /** 删除整本漫画：所有章节任务 + 本地文件 + 详情/封面缓存 + 图片缓存归因条目 + downloads 记录 */
  static async removeComic(comicId: string, source: string): Promise<void> {
    const tasks: ChapterTask[] = await Database.queryChapterTasks(comicId);
    for (const task of tasks) {
      await DownloadManager.cancel(task.chapterId, comicId);
    }
    await DetailCache.remove(comicId, source);
    // 该漫画的 img_cache 归因条目（在线读页/封面缩略图缓存）一并删除，避免删除后缓存仍占空间
    await ImageCache.removeByComic(comicId);
    await Database.removeDownload(comicId, source);
    DownloadManager.notify();
    DownloadManager.maybeStopBg();
  }

  /** 图片 URL → 主根本地绝对路径（{root}/{photoId}/{文件名}）；无法推导时返回空串 */
  static localPathFor(url: string): string {
    return DownloadManager.pathFor(url, DownloadManager.filesRoot);
  }

  /** 图片 URL → 指定根下本地绝对路径；root/url 无效时返回空串 */
  private static pathFor(url: string, root: string): string {
    if (root.length === 0) {
      return '';
    }
    const photoId: string = JmImage.photoIdFromUrl(url);
    if (photoId.length === 0) {
      return '';
    }
    const q: number = url.indexOf('?');
    let name: string = q >= 0 ? url.substring(0, q) : url;
    const slash: number = name.lastIndexOf('/');
    if (slash >= 0) {
      name = name.substring(slash + 1);
    }
    name = DownloadManager.sanitize(name);
    if (name.length === 0) {
      return '';
    }
    return `${root}/${photoId}/${name}`;
  }

  static localExists(path: string): boolean {
    if (path.length === 0) {
      return false;
    }
    try {
      return fs.accessSync(path);
    } catch (e) {
      return false;
    }
  }

  static readLocal(path: string): Uint8Array | null {
    if (path.length === 0) {
      return null;
    }
    let file: fs.File | null = null;
    try {
      if (!fs.accessSync(path)) {
        return null;
      }
      const size: number = fs.statSync(path).size;
      if (size <= 0) {
        return null;
      }
      file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      const buf: ArrayBuffer = new ArrayBuffer(size);
      const read: number = fs.readSync(file.fd, buf, { offset: 0 });
      if (read <= 0) {
        return null;
      }
      return new Uint8Array(buf, 0, read);
    } catch (e) {
      Logger.warn(TAG, `read local failed: ${path} ${Logger.describe(e)}`);
      return null;
    } finally {
      if (file !== null) {
        try {
          fs.closeSync(file);
        } catch (e) {
        }
      }
    }
  }

  /** 下载启动时把章节页 URL 列表写入 pages.json（离线阅读兜底），失败不阻断下载 */
  private static writePagesFile(localDir: string, urls: string[]): void {
    if (localDir.length === 0) {
      return;
    }
    try {
      DownloadManager.ensureDir(localDir);
      const text: string = JSON.stringify(urls);
      const bytes: Uint8Array = new Uint8Array(text.length);
      for (let i: number = 0; i < text.length; i++) {
        bytes[i] = text.charCodeAt(i) & 0xFF;
      }
      const path: string = `${localDir}/${DownloadManager.PAGES_FILE}`;
      const file: fs.File = fs.openSync(path,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        const buf: ArrayBuffer = bytes.buffer.slice(0);
        fs.writeSync(file.fd, buf);
      } finally {
        fs.closeSync(file);
      }
    } catch (e) {
      Logger.warn(TAG, `write pages.json failed: ${localDir} ${Logger.describe(e)}`);
    }
  }

  /** 章节目录候选（主根优先、旧沙箱根在后，仅含实际存在的；读取/回填/删除遍历用） */
  private static existingChapterDirs(chapterId: string): string[] {
    const out: string[] = [];
    const primary: string = DownloadManager.chapterDir(chapterId);
    if (primary.length > 0 && DownloadManager.localExists(primary)) {
      out.push(primary);
    }
    if (DownloadManager.legacyRoot.length > 0 && DownloadManager.legacyRoot !== DownloadManager.filesRoot) {
      const legacy: string = `${DownloadManager.legacyRoot}/${chapterId}`;
      if (DownloadManager.localExists(legacy)) {
        out.push(legacy);
      }
    }
    return out;
  }

  /** 在线取章成功后回填 pages.json（旧版本下载的章节补写离线页列表）；章节目录不存在=未下载，跳过 */
  static cacheChapterPages(chapterId: string, urls: string[]): void {
    if (DownloadManager.filesRoot.length === 0 || chapterId.length === 0 || urls.length === 0) {
      return;
    }
    const dirs: string[] = DownloadManager.existingChapterDirs(chapterId);
    for (const dir of dirs) {
      DownloadManager.writePagesFile(dir, urls);
    }
  }

  /** 离线读取章节页 URL 列表（下载时写入的 pages.json）；无文件/坏文件返回空数组。主根优先，迁移窗口期回读旧根 */
  static readChapterPages(chapterId: string): string[] {
    if (DownloadManager.filesRoot.length === 0 || chapterId.length === 0) {
      return [];
    }
    const dirs: string[] = DownloadManager.existingChapterDirs(chapterId);
    for (const dir of dirs) {
      const urls: string[] = DownloadManager.readPagesFile(dir);
      if (urls.length > 0) {
        return urls;
      }
    }
    return [];
  }

  private static readPagesFile(dir: string): string[] {
    if (dir.length === 0) {
      return [];
    }
    const path: string = `${dir}/${DownloadManager.PAGES_FILE}`;
    let file: fs.File | null = null;
    try {
      if (!fs.accessSync(path)) {
        return [];
      }
      file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      const size: number = fs.statSync(path).size;
      if (size <= 0) {
        return [];
      }
      const buf: ArrayBuffer = new ArrayBuffer(size);
      const read: number = fs.readSync(file.fd, buf, { offset: 0 });
      if (read <= 0) {
        return [];
      }
      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
      const text: string = decoder.decodeToString(new Uint8Array(buf, 0, read));
      if (text.length === 0) {
        return [];
      }
      const arr: Object[] = JSON.parse(text) as Object[];
      const urls: string[] = [];
      for (const item of arr) {
        const s: string = String(item);
        if (s.length > 0) {
          urls.push(s);
        }
      }
      return urls;
    } catch (e) {
      Logger.warn(TAG, `read pages.json failed: ${dir} ${Logger.describe(e)}`);
      return [];
    } finally {
      if (file !== null) {
        try {
          fs.closeSync(file);
        } catch (e) {
        }
      }
    }
  }

  private static async runChapter(task: ChapterTask): Promise<void> {
    if (task.status !== ChapterDlStatus.QUEUED) {
      return;
    }
    // 运行时重算章节目录（主根可能在入队后从沙箱切换到公共下载目录，不信旧存储值）
    task.localDir = DownloadManager.chapterDir(task.chapterId);
    task.status = ChapterDlStatus.RUNNING;
    await Database.updateChapterTask(task);
    DownloadManager.notify();
    DownloadManager.publishProgress(true);
    try {
      const chapter: Chapter = await JmApi.getChapter(task.chapterId);
      const urls: string[] = chapter.imageUrls;
      if (urls.length === 0) {
        throw new Error('empty imageUrls');
      }
      if (task.pageCount !== urls.length) {
        task.pageCount = urls.length;
        await Database.updateChapterTask(task);
      }
      DownloadManager.ensureDir(task.localDir);
      DownloadManager.writePagesFile(task.localDir, urls);
      let failed: boolean = false;
      for (let i: number = 0; i < urls.length; i++) {
        if (task.status !== ChapterDlStatus.RUNNING) {
          break;
        }
        const url: string = urls[i];
        const dest: string = DownloadManager.localPathFor(url);
        // 已存在（含迁移窗口期还在旧沙箱根的同名文件）直接跳过，避免重复下载
        let ok: boolean = dest.length > 0 && DownloadManager.localHit(url).length > 0;
        if (!ok && dest.length > 0) {
          ok = await DownloadManager.savePage(url, dest);
          if (!ok) {
            ok = await DownloadManager.savePage(url, dest);
          }
        }
        if (!ok) {
          failed = true;
          Logger.warn(TAG, `page failed: ch=${task.chapterId} idx=${i}`);
          break;
        }
        if (task.progress !== i + 1) {
          task.progress = i + 1;
          await Database.updateChapterTask(task);
        }
        DownloadManager.notify();
        DownloadManager.publishProgress(false);
      }
      if (task.status === ChapterDlStatus.RUNNING || task.status === ChapterDlStatus.PAUSED) {
        if (task.status === ChapterDlStatus.RUNNING) {
          task.status = failed ? ChapterDlStatus.FAILED : ChapterDlStatus.DONE;
        }
        await Database.updateChapterTask(task);
      }
    } catch (e) {
      Logger.error(TAG, `run chapter failed: ${task.chapterId} ${Logger.describe(e)}`);
      if (task.status === ChapterDlStatus.RUNNING) {
        task.status = ChapterDlStatus.FAILED;
        await Database.updateChapterTask(task);
      } else if (task.status === ChapterDlStatus.PAUSED) {
        await Database.updateChapterTask(task);
      }
    }
    DownloadManager.notify();
    DownloadManager.publishProgress(true);
  }

  /** 抓取一页 → （GIF 原样 / 静图解码→反打乱→JPEG 编码）→ .tmp → rename 原子落盘 */
  private static async savePage(url: string, dest: string): Promise<boolean> {
    const tmp: string = `${dest}.tmp`;
    try {
      const bytes: Uint8Array | null = await DownloadManager.fetchImage(url);
      if (bytes === null) {
        return false;
      }
      if (JmImage.isGif(url)) {
        DownloadManager.writeBuffer(tmp, bytes);
      } else {
        let pm: image.PixelMap | null = await JmImage.decode(bytes, 0);
        let combined: image.PixelMap | null = null;
        const packer: image.ImagePacker = image.createImagePacker();
        try {
          combined = await JmImage.recombine(pm, url);
          pm = null;
          const opts: image.PackingOption = { format: 'image/jpeg', quality: PACK_QUALITY };
          const out: ArrayBuffer = await packer.packToData(combined, opts);
          DownloadManager.writeBuffer(tmp, new Uint8Array(out));
        } finally {
          packer.release();
          if (combined !== null) {
            combined.release();
          } else if (pm !== null) {
            pm.release();
          }
        }
      }
      fs.renameSync(tmp, dest);
      return true;
    } catch (e) {
      Logger.error(TAG, `save page failed: ${url} ${Logger.describe(e)}`);
      DownloadManager.removeFileQuiet(tmp);
      return false;
    }
  }

  private static async fetchImage(url: string): Promise<Uint8Array | null> {
    const headers: Record<string, string> = JmImage.imgHeaders();
    let bytes: Uint8Array | null = await Network.getBytes(url, headers);
    if (bytes !== null && bytes.length > 0 && !JmImage.looksLikeImage(bytes)) {
      bytes = null;
    }
    if ((bytes === null || bytes.length === 0) && DownloadManager.ctx !== null) {
      try {
        bytes = await Network.getBytesViaDownload(url, headers, DownloadManager.ctx);
      } catch (e) {
        bytes = null;
      }
      if (bytes !== null && bytes.length > 0 && !JmImage.looksLikeImage(bytes)) {
        bytes = null;
      }
    }
    if (bytes === null || bytes.length === 0) {
      return null;
    }
    return bytes;
  }

  private static pump(): void {
    while (DownloadManager.active.size < MAX_ACTIVE && DownloadManager.queue.length > 0) {
      const next: ChapterTask | undefined = DownloadManager.queue.shift();
      if (next === undefined) {
        break;
      }
      if (next.status !== ChapterDlStatus.QUEUED) {
        continue;
      }
      const key: string = DownloadManager.taskKey(next.chapterId, next.comicId);
      DownloadManager.active.set(key, next);
      DownloadManager.runChapter(next).then(() => {
        DownloadManager.active.delete(key);
        DownloadManager.pump();
        DownloadManager.maybeStopBg();
      });
    }
    DownloadManager.maybeStopBg();
  }

  private static ensureBg(): void {
    if (DownloadManager.bgStarted || DownloadManager.bgStarting || DownloadManager.ctx === null) {
      return;
    }
    DownloadManager.bgStarting = true;
    const start = (wa: WantAgent): void => {
      const ctx: common.UIAbilityContext | null = DownloadManager.ctx;
      if (ctx === null) {
        DownloadManager.bgStarting = false;
        return;
      }
      const modes: Array<string> = ['dataTransfer'];
      backgroundTaskManager.startBackgroundRunning(ctx, modes, wa)
        .then((res: backgroundTaskManager.ContinuousTaskNotification) => {
          DownloadManager.notificationId = res.notificationId;
          DownloadManager.bgStarted = true;
          DownloadManager.bgStarting = false;
          DownloadManager.lastPublishAt = 0;
          DownloadManager.publishProgress(true);
          Logger.info(TAG, `bg task started, notificationId=${res.notificationId}`);
        })
        .catch((e: BusinessError) => {
          DownloadManager.bgStarting = false;
          Logger.warn(TAG, `startBackgroundRunning failed: ${e.code} ${e.message}`);
        });
    };
    if (DownloadManager.wantAgentObj !== null) {
      start(DownloadManager.wantAgentObj);
      return;
    }
    let bundleName: string = '';
    try {
      bundleName = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION).name;
    } catch (e) {
      DownloadManager.bgStarting = false;
      Logger.warn(TAG, `getBundleInfoForSelfSync failed: ${Logger.describe(e)}`);
      return;
    }
    const info: wantAgent.WantAgentInfo = {
      wants: [{
        bundleName: bundleName,
        abilityName: 'EntryAbility'
      }],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };
    wantAgent.getWantAgent(info)
      .then((wa: WantAgent) => {
        DownloadManager.wantAgentObj = wa;
        start(wa);
      })
      .catch((e: BusinessError) => {
        DownloadManager.bgStarting = false;
        Logger.warn(TAG, `getWantAgent failed: ${e.code} ${e.message}`);
      });
  }

  private static maybeStopBg(): void {
    if (!DownloadManager.bgStarted || DownloadManager.active.size > 0 || DownloadManager.queue.length > 0) {
      return;
    }
    DownloadManager.bgStarted = false;
    DownloadManager.notificationId = -1;
    const ctx: common.UIAbilityContext | null = DownloadManager.ctx;
    if (ctx === null) {
      return;
    }
    backgroundTaskManager.stopBackgroundRunning(ctx)
      .then(() => {
        Logger.info(TAG, 'bg task stopped');
      })
      .catch((e: BusinessError) => {
        Logger.warn(TAG, `stopBackgroundRunning failed: ${e.code} ${e.message}`);
      });
  }

  /** 进度实况窗：dataTransfer 长时任务依赖持续进度更新，节流 2s 发布一次 */
  private static async publishProgress(force: boolean): Promise<void> {
    if (!DownloadManager.bgStarted || DownloadManager.notificationId < 0) {
      return;
    }
    const now: number = Date.now();
    if (!force && now - DownloadManager.lastPublishAt < PUBLISH_INTERVAL) {
      return;
    }
    DownloadManager.lastPublishAt = now;
    const percent: number = await DownloadManager.overallPercent();
    const template: notificationManager.NotificationTemplate = {
      name: 'downloadTemplate',
      data: {
        'title': Translations.t('download_manager'),
        'fileName': `${percent}%`,
        'progressValue': percent
      }
    };
    const request: notificationManager.NotificationRequest = {
      id: DownloadManager.notificationId,
      notificationSlotType: notificationManager.SlotType.LIVE_VIEW,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
        systemLiveView: {
          typeCode: 8,
          title: Translations.t('download_manager'),
          text: `${percent}%`
        }
      },
      template: template
    };
    try {
      await notificationManager.publish(request);
    } catch (e) {
      Logger.debug(TAG, `publish progress failed: ${Logger.describe(e)}`);
    }
  }

  private static async overallPercent(): Promise<number> {
    const tasks: ChapterTask[] = await Database.queryAllChapterTasks();
    let pagesDone: number = 0;
    let pagesTotal: number = 0;
    let chaptersDone: number = 0;
    let chaptersTotal: number = 0;
    for (const task of tasks) {
      chaptersTotal++;
      if (task.status === ChapterDlStatus.DONE) {
        chaptersDone++;
      }
      if (task.pageCount > 0) {
        pagesTotal += task.pageCount;
        pagesDone += task.progress < task.pageCount ? task.progress : task.pageCount;
      }
    }
    if (pagesTotal > 0) {
      return Math.floor(pagesDone * 100 / pagesTotal);
    }
    if (chaptersTotal > 0) {
      return Math.floor(chaptersDone * 100 / chaptersTotal);
    }
    return 0;
  }

  private static notify(): void {
    for (const fn of DownloadManager.listeners) {
      fn();
    }
  }

  private static taskKey(chapterId: string, comicId: string): string {
    return `${chapterId}|${comicId}`;
  }

  private static inQueue(chapterId: string, comicId: string): boolean {
    for (const task of DownloadManager.queue) {
      if (task.chapterId === chapterId && task.comicId === comicId) {
        return true;
      }
    }
    return false;
  }

  private static ensureDir(path: string): void {
    if (path.length === 0) {
      return;
    }
    try {
      fs.mkdirSync(path, true);
    } catch (e) {
      Logger.warn(TAG, `mkdir failed: ${path} ${Logger.describe(e)}`);
    }
  }

  private static writeBuffer(path: string, data: Uint8Array): void {
    try {
      const file: fs.File = fs.openSync(path,
        fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      try {
        let offset: number = 0;
        while (offset < data.byteLength) {
          const buf: ArrayBuffer = data.buffer.slice(data.byteOffset + offset, data.byteOffset + data.byteLength);
          const written: number = fs.writeSync(file.fd, buf);
          if (written <= 0) {
            throw new Error('write returned 0');
          }
          offset += written;
        }
      } finally {
        fs.closeSync(file);
      }
    } catch (e) {
      throw new Error(`writeBuffer failed: ${Logger.describe(e)}`);
    }
  }

  private static removeFileQuiet(path: string): void {
    try {
      if (DownloadManager.localExists(path)) {
        fs.unlinkSync(path);
      }
    } catch (e) {
    }
  }

  private static removeDirQuiet(path: string): void {
    try {
      if (path.length > 0 && DownloadManager.localExists(path)) {
        fs.rmdirSync(path);
      }
    } catch (e) {
    }
  }

  private static sanitize(name: string): string {
    let out: string = '';
    for (let i: number = 0; i < name.length; i++) {
      const c: string = name.charAt(i);
      const ok: boolean = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
        || (c >= '0' && c <= '9') || c === '.' || c === '-' || c === '_';
      out += ok ? c : '_';
    }
    return out;
  }
}
