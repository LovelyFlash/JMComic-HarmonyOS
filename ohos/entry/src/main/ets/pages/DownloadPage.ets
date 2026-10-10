// pages/DownloadPage.ets - 下载管理（漫画聚合进度 + 章节展开/暂停/继续/重试 + 删除连带清理文件）- NavDestination
import { Translations } from '../common/Translations';
import { NavUtil } from '../common/NavUtil';
import { ToastUtil } from '../common/ToastUtil';
import { ChapterDlStatus, ChapterTask, Database, DownloadItem } from '../data/database/Database';
import { DownloadManager } from '../data/download/DownloadManager';
import { DetailCache } from '../data/cache/DetailCache';
import { DEFAULT_THEME_COLOR } from '../common/Constants';
import { uiMaterial } from '@kit.ArkUI';
import { fileUri } from '@kit.CoreFileKit';

/** 单本漫画的章节任务聚合（进度条与状态展示） */
class ComicAgg {
  chapters: number = 0;
  done: number = 0;
  pagesDone: number = 0;
  pagesTotal: number = 0;
  /** 聚合状态：优先级 RUNNING > QUEUED > FAILED > PAUSED > DONE */
  status: number = ChapterDlStatus.DONE;
  hasTasks: boolean = false;
}

@Builder
export function DownloadPageBuilder(name: string, param: object) {
  DownloadPage()
}

@Component
export struct DownloadPage {
  @State items: DownloadItem[] = []
  @State loading: boolean = true
  @State aggMap: Map<string, ComicAgg> = new Map()
  @State expandedId: string = ''
  @State chapterTasks: ChapterTask[] = []
  @StorageProp('bottomAvoidHeight') bottomAvoid: number = 0
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR
  private reloadTimer: number = -1;
  private notifyListener: () => void = (): void => {
    this.scheduleReload();
  }

  aboutToAppear(): void {
    this.loadData(true);
    DownloadManager.subscribe(this.notifyListener);
  }

  aboutToDisappear(): void {
    DownloadManager.unsubscribe(this.notifyListener);
    if (this.reloadTimer >= 0) {
      clearTimeout(this.reloadTimer);
      this.reloadTimer = -1;
    }
  }

  /** 下载进度回调防抖重载（400ms），避免逐页进度触发整树重绘 */
  private scheduleReload(): void {
    if (this.reloadTimer >= 0) {
      clearTimeout(this.reloadTimer);
    }
    this.reloadTimer = setTimeout(() => {
      this.reloadTimer = -1;
      this.loadData(false);
    }, 400);
  }

  async loadData(showLoading: boolean): Promise<void> {
    if (showLoading) {
      this.loading = true;
    }
    const items: DownloadItem[] = await Database.queryDownloads();
    const tasks: ChapterTask[] = await Database.queryAllChapterTasks();
    this.aggMap = DownloadPage.buildAggregates(tasks);
    this.items = items;
    if (this.expandedId.length > 0) {
      this.chapterTasks = await Database.queryChapterTasks(this.expandedId);
    }
    if (showLoading) {
      this.loading = false;
    }
  }

  private static buildAggregates(tasks: ChapterTask[]): Map<string, ComicAgg> {
    const map: Map<string, ComicAgg> = new Map();
    for (const task of tasks) {
      let agg: ComicAgg | undefined = map.get(task.comicId);
      if (agg === undefined) {
        agg = new ComicAgg();
        map.set(task.comicId, agg);
      }
      agg.hasTasks = true;
      agg.chapters++;
      if (task.status === ChapterDlStatus.DONE) {
        agg.done++;
      }
      if (task.pageCount > 0) {
        agg.pagesTotal += task.pageCount;
        agg.pagesDone += task.progress < task.pageCount ? task.progress : task.pageCount;
      }
      agg.status = DownloadPage.mergeStatus(agg.status, task.status);
    }
    return map;
  }

  private static mergeStatus(current: number, next: number): number {
    if (current === ChapterDlStatus.RUNNING || next === ChapterDlStatus.RUNNING) {
      return ChapterDlStatus.RUNNING;
    }
    if (current === ChapterDlStatus.QUEUED || next === ChapterDlStatus.QUEUED) {
      return ChapterDlStatus.QUEUED;
    }
    if (current === ChapterDlStatus.FAILED || next === ChapterDlStatus.FAILED) {
      return ChapterDlStatus.FAILED;
    }
    if (current === ChapterDlStatus.PAUSED || next === ChapterDlStatus.PAUSED) {
      return ChapterDlStatus.PAUSED;
    }
    return ChapterDlStatus.DONE;
  }

  private aggPercent(agg: ComicAgg): number {
    if (agg.pagesTotal > 0) {
      return Math.floor(agg.pagesDone * 100 / agg.pagesTotal);
    }
    if (agg.chapters > 0) {
      return Math.floor(agg.done * 100 / agg.chapters);
    }
    return 0;
  }

  /** 漫画行进度文案：优先页数「12/48 页」，页数未知时回退章节数「1/3」 */
  private aggPagesLabel(agg: ComicAgg): string {
    if (agg.pagesTotal > 0) {
      return `${agg.pagesDone}/${agg.pagesTotal}${Translations.t('pages_suffix')}`;
    }
    if (agg.chapters > 0) {
      return `${agg.done}/${agg.chapters}`;
    }
    return '';
  }

  /** 章节行进度百分比（无总页数时：完成 100%，其余 0%） */
  private taskPercent(task: ChapterTask): number {
    if (task.pageCount > 0) {
      return Math.floor(task.progress * 100 / task.pageCount);
    }
    return task.status === ChapterDlStatus.DONE ? 100 : 0;
  }

  /** 取聚合（无任务记录返回空聚合，避免构建器内做空值判断） */
  private aggOf(comicId: string): ComicAgg {
    const agg: ComicAgg | undefined = this.aggMap.get(comicId);
    if (agg !== undefined) {
      return agg;
    }
    return new ComicAgg();
  }

  /** 封面数据源：本地已下载封面优先（沙箱路径需转 file:// URI 才能渲染），回退网络 URL */
  private coverSource(item: DownloadItem): string {
    const local: string = DetailCache.localCoverPath(item.id);
    return local.length > 0 ? fileUri.getUriFromPath(local) : item.coverUrl;
  }

  private statusLabel(status: number): string {
    if (status === ChapterDlStatus.DONE) {
      return Translations.t('dl_done');
    }
    if (status === ChapterDlStatus.FAILED) {
      return Translations.t('dl_failed');
    }
    if (status === ChapterDlStatus.PAUSED) {
      return Translations.t('dl_paused');
    }
    if (status === ChapterDlStatus.RUNNING) {
      return Translations.t('dl_running');
    }
    return Translations.t('dl_queued');
  }

  private statusColor(status: number): ResourceColor {
    if (status === ChapterDlStatus.FAILED) {
      return $r('app.color.danger');
    }
    if (status === ChapterDlStatus.RUNNING || status === ChapterDlStatus.QUEUED) {
      return this.themeColor;
    }
    if (status === ChapterDlStatus.PAUSED) {
      return $r('app.color.text_secondary');
    }
    return $r('app.color.text_tertiary');
  }

  private async toggleExpand(comicId: string): Promise<void> {
    if (this.expandedId === comicId) {
      this.expandedId = '';
      this.chapterTasks = [];
      return;
    }
    this.expandedId = comicId;
    this.chapterTasks = await Database.queryChapterTasks(comicId);
  }

  private taskAction(task: ChapterTask): void {
    if (task.status === ChapterDlStatus.QUEUED || task.status === ChapterDlStatus.RUNNING) {
      DownloadManager.pause(task.chapterId, task.comicId);
    } else {
      DownloadManager.resume(task.chapterId, task.comicId);
    }
  }

  private comicAction(item: DownloadItem): void {
    const agg: ComicAgg | undefined = this.aggMap.get(item.id);
    if (agg === undefined) {
      return;
    }
    if (agg.status === ChapterDlStatus.RUNNING || agg.status === ChapterDlStatus.QUEUED) {
      DownloadManager.pauseComic(item.id);
    } else {
      DownloadManager.resumeComic(item.id);
    }
  }

  private isComicBusy(agg: ComicAgg): boolean {
    return agg.status === ChapterDlStatus.RUNNING || agg.status === ChapterDlStatus.QUEUED;
  }

  removeDownload(item: DownloadItem): void {
    this.getUIContext().showAlertDialog({
      title: Translations.t('delete_download'),
      message: `${Translations.t('delete_confirm_prefix')}${item.title}${Translations.t('delete_confirm_suffix')}`,
      primaryButton: {
        value: Translations.t('cancel'),
        action: () => {
        }
      },
      secondaryButton: {
        value: Translations.t('delete'),
        fontColor: $r('app.color.danger'),
        action: () => {
          DownloadManager.removeComic(item.id, item.source).then(() => {
            ToastUtil.show(Translations.t('deleted'), 1500);
            if (this.expandedId === item.id) {
              this.expandedId = '';
              this.chapterTasks = [];
            }
            this.loadData(false);
          });
        }
      }
    });
  }

  @Builder
  chapterRow(task: ChapterTask) {
    Row({ space: 10 }) {
      Column({ space: 2 }) {
        Text(task.title.length > 0 ? task.title : `${task.sortOrder}`)
          .fontSize(14)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
          .textAlign(TextAlign.Start)
        Row({ space: 6 }) {
          Text(this.statusLabel(task.status))
            .fontSize(11)
            .fontColor(this.statusColor(task.status))
          if (task.pageCount > 0 && task.status !== ChapterDlStatus.DONE) {
            Text(`${task.progress}/${task.pageCount}${Translations.t('pages_suffix')} (${this.taskPercent(task)}%)`)
              .fontSize(11)
              .fontColor($r('app.color.text_tertiary'))
          }
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      if (task.status === ChapterDlStatus.DONE) {
        SymbolGlyph($r('sys.symbol.checkmark'))
          .fontSize(18)
          .fontColor([$r('app.color.text_tertiary')])
      } else if (task.status === ChapterDlStatus.QUEUED || task.status === ChapterDlStatus.RUNNING) {
        SymbolGlyph($r('sys.symbol.pause'))
          .fontSize(18)
          .fontColor([this.themeColor])
          .onClick(() => { this.taskAction(task); })
      } else {
        SymbolGlyph(task.status === ChapterDlStatus.FAILED
          ? $r('sys.symbol.arrow_clockwise') : $r('sys.symbol.play_fill'))
          .fontSize(18)
          .fontColor([this.themeColor])
          .onClick(() => { this.taskAction(task); })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
    .id('dlChapter' + task.chapterId)
  }

  @Builder
  expandedPanel(item: DownloadItem) {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text(this.statusLabel(this.aggOf(item.id).status))
          .fontSize(12)
          .fontColor(this.statusColor(this.aggOf(item.id).status))
        Blank().layoutWeight(1)
        Text(this.isComicBusy(this.aggOf(item.id))
          ? Translations.t('pause') : Translations.t('resume'))
          .fontSize(12)
          .fontColor(this.themeColor)
          .padding({ left: 10, right: 10, top: 4, bottom: 4 })
          .backgroundColor($r('app.color.bg_fill'))
          .borderRadius(10)
          .onClick(() => { this.comicAction(item); })
      }
      .width('100%')
      .padding({ left: 92, right: 16 })

      Divider().color($r('app.color.divider'))

      ForEach(this.chapterTasks, (task: ChapterTask) => {
        this.chapterRow(task)
      }, (task: ChapterTask): string => task.chapterId)
    }
    .width('100%')
    .padding({ top: 4, bottom: 8 })
    .backgroundColor($r('app.color.bg_fill'))
  }

  build() {
    NavDestination() {
      Column({ space: 0 }) {
        if (this.loading) {
          Column() {
            LoadingProgress().width(40).height(40)
          }
          .width('100%').layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else if (this.items.length === 0) {
          Column({ space: 12 }) {
            SymbolGlyph($r('sys.symbol.arrow_down_circle'))
              .fontSize(44)
              .fontColor([$r('app.color.text_tertiary')])
            Text(Translations.t('no_downloads'))
              .fontSize(14).fontColor($r('app.color.text_secondary'))
            Text(Translations.t('download_hint'))
              .fontSize(12).fontColor($r('app.color.text_tertiary'))
          }
          .width('100%').layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        } else {
          List({ space: 1 }) {
            ForEach(this.items, (item: DownloadItem) => {
              ListItem() {
                Column({ space: 0 }) {
                  Row({ space: 12 }) {
                    Image(this.coverSource(item))
                      .width(64).height(88).objectFit(ImageFit.Cover)
                      .borderRadius(6)
                      .backgroundColor($r('app.color.bg_fill'))
                    Column({ space: 6 }) {
                      Text(item.title)
                        .fontSize(15).fontWeight(FontWeight.Medium)
                        .fontColor($r('app.color.text_primary'))
                        .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
                        .width('100%')
                      if (this.aggOf(item.id).hasTasks) {
                        Row({ space: 6 }) {
                          Text(this.statusLabel(this.aggOf(item.id).status))
                            .fontSize(12)
                            .fontColor(this.statusColor(this.aggOf(item.id).status))
                          Text(this.aggPagesLabel(this.aggOf(item.id)))
                            .fontSize(12)
                            .fontColor($r('app.color.text_secondary'))
                          Text(`${this.aggPercent(this.aggOf(item.id))}%`)
                            .fontSize(12)
                            .fontColor($r('app.color.text_tertiary'))
                        }
                        .width('100%')
                        .justifyContent(FlexAlign.Start)
                        Progress({
                          value: this.aggPercent(this.aggOf(item.id)),
                          total: 100,
                          type: ProgressType.Linear
                        })
                          .width('100%')
                          .height(4)
                          .color(this.isComicBusy(this.aggOf(item.id)) ? this.themeColor : $r('app.color.text_tertiary'))
                          .backgroundColor($r('app.color.bg_fill'))
                      } else {
                        Text(item.source)
                          .fontSize(12).fontColor(this.themeColor)
                      }
                    }
                    .layoutWeight(1).alignItems(HorizontalAlign.Start)
                    SymbolGlyph($r('sys.symbol.chevron_right'))
                      .fontSize(16)
                      .fontColor([$r('app.color.text_tertiary')])
                      .rotate({ x: 0, y: 0, z: 1, angle: this.expandedId === item.id ? 90 : 0 })
                      .onClick(() => {
                        this.toggleExpand(item.id);
                      })
                    SymbolGlyph($r('sys.symbol.trash'))
                      .fontSize(20)
                      .fontColor([$r('app.color.text_tertiary')])
                      .onClick(() => {
                        this.removeDownload(item);
                      })
                  }
                  .width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 })
                  .onClick(() => {
                    const param: Record<string, Object> = {
                      'comicId': item.id, 'title': item.title, 'source': item.source
                    };
                    NavUtil.push('comicDetail', param);
                  })
                  if (this.expandedId === item.id) {
                    this.expandedPanel(item)
                  }
                }
                .width('100%')
              }
              .id('download' + item.id + item.source)
            }, (item: DownloadItem) => item.id + item.source)
          }
          .width('100%').layoutWeight(1)
          .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
          .padding({ bottom: this.bottomAvoid })
        }
      }
      .width('100%').height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .title(Translations.t('download_manager'), { backgroundColor: Color.Transparent })
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .hideTitleBar(false)
    .backgroundColor($r('app.color.bg_page'))
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    }))
  }
}
