// pages/CommentsPage.ets - 评论页（禁漫网络评论，已下载漫画支持本地缓存秒开）- NavDestination
import { Translations } from '../common/Translations';
import { ToastUtil } from '../common/ToastUtil';
import { JmApi, JmComment, JmCommentPage } from '../data/api/JmApi';
import { DetailCache } from '../data/cache/DetailCache';
import { Settings } from '../data/preferences/Settings';
import { SettingsKeys } from '../common/Constants';
import { ArrayDataSource } from '../common/ArrayDataSource';
import { DEFAULT_THEME_COLOR } from '../common/Constants';
import { uiMaterial } from '@kit.ArkUI';

@Builder
export function CommentsPageBuilder(name: string, param: object) {
  CommentsPage({ pageParam: param })
}

@Component
export struct CommentsPage {
  pageParam: object | undefined = undefined;
  @State comicId: string = ''
  @State title: string = ''
  @State dataSource: ArrayDataSource<JmComment> = new ArrayDataSource<JmComment>()
  @State inputText: string = ''
  @State loading: boolean = true
  @State loadingMore: boolean = false
  @State error: string = ''
  @State currentPage: number = 1
  @State maxPage: number = 1
  @State sending: boolean = false
  
  @StorageProp('bottomAvoidHeight') bottomAvoid: number = 0
  @StorageProp('themeColor') themeColor: string = DEFAULT_THEME_COLOR

  aboutToAppear(): void {
    if (this.pageParam !== undefined && this.pageParam !== null) {
      const params = this.pageParam as Record<string, Object>;
      this.comicId = params['comicId'] !== undefined && params['comicId'] !== null ? String(params['comicId']) : '';
      this.title = params['title'] !== undefined && params['title'] !== null ? String(params['title']) : '';
    }
    this.loadPage(1, true);
  }

  /**
   * 本地秒开 + 后台刷新：
   * - 首页有缓存 → 立即渲染缓存；「离线优先」开则到此为止，否则继续联网刷新并回写缓存
   * - 无缓存 / 翻页 → 走网络（原逻辑）；联网失败且已有缓存内容时静默保留，不清空
   */
  async loadPage(page: number, replace: boolean): Promise<void> {
    let fromCache: boolean = false;
    if (page === 1 && replace) {
      const cached: JmCommentPage | null = await DetailCache.loadComments(this.comicId, 'jm');
      if (cached !== null) {
        fromCache = true;
        this.maxPage = cached.maxPage > 0 ? cached.maxPage : 1;
        this.currentPage = 1;
        this.dataSource = new ArrayDataSource<JmComment>(cached.comments);
        this.loading = false;
        this.error = '';
        const offline: boolean = await Settings.getBool(SettingsKeys.OFFLINE_FIRST, false);
        if (offline) {
          return;
        }
      }
    }
    if (replace && !fromCache) {
      this.loading = true;
      this.error = '';
    }
    try {
      const result: JmCommentPage = await JmApi.getComments(this.comicId, page);
      this.maxPage = result.maxPage > 0 ? result.maxPage : 1;
      this.currentPage = page;
      if (replace) {
        this.dataSource = new ArrayDataSource<JmComment>(result.comments);
      } else {
        this.dataSource.addAll(result.comments);
      }
      if (page === 1 && replace) {
        DetailCache.saveComments(this.comicId, 'jm', result.comments, this.maxPage);
      }
    } catch (e) {
      if (replace && !fromCache) {
        this.error = String(e);
        this.dataSource = new ArrayDataSource<JmComment>();
      }
      // 已有缓存兜底（fromCache）→ 静默保留缓存内容
    }
    if (replace) {
      this.loading = false;
    }
  }

  async loadMore(): Promise<void> {
    if (this.loadingMore || this.loading) return;
    if (this.currentPage >= this.maxPage) return;
    this.loadingMore = true;
    try {
      await this.loadPage(this.currentPage + 1, false);
    } catch (e) {
      // 忽略加载更多错误
    }
    this.loadingMore = false;
  }

  async sendComment(): Promise<void> {
    const text: string = this.inputText.trim();
    if (text.length === 0) {
      ToastUtil.show(Translations.t('comment_empty_input'), 1500);
      return;
    }
    if (!JmApi.isLoggedIn()) {
      ToastUtil.show(Translations.t('please_login'), 1500);
      return;
    }
    if (this.sending) {
      return;
    }
    this.sending = true;
    try {
      await JmApi.postComment(this.comicId, text);
      this.inputText = '';
      ToastUtil.show(Translations.t('comment_success'), 1500);
      this.loadPage(1, true);
    } catch (e) {
      ToastUtil.fail(e);
    }
    this.sending = false;
  }

  @Builder
  avatarOrFallback(url: string, size: number) {
    if (url.length > 0) {
      Image(url)
        .width(size).height(size)
        .objectFit(ImageFit.Cover)
        .borderRadius(size / 2)
        .backgroundColor($r('app.color.bg_fill'))
        .id('avatarImage')
    } else {
      Column() {
        SymbolGlyph($r('sys.symbol.person'))
          .fontSize(size * 0.6)
          .fontColor([this.themeColor])
      }
      .width(size).height(size)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor($r('app.color.bg_fill'))
      .borderRadius(size / 2)
      .id('avatarFallback')
    }
  }

  @Builder
  replyItem(reply: JmComment) {
    Row({ space: 8 }) {
      this.avatarOrFallback(reply.avatar, 24)
      Column({ space: 4 }) {
        Row({ space: 8 }) {
          Text(reply.username)
            .fontSize(12).fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          Text(reply.time)
            .fontSize(10).fontColor($r('app.color.text_tertiary'))
        }
        .width('100%')
        Text(reply.content)
          .fontSize(13).fontColor($r('app.color.text_primary'))
          .width('100%')
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8, left: 8 })
    .backgroundColor($r('app.color.bg_surface'))
    .borderRadius(8)
    .id('replyItem' + reply.id)
  }

  @Builder
  commentItem(comment: JmComment) {
    Column({ space: 8 }) {
      Row({ space: 12 }) {
        this.avatarOrFallback(comment.avatar, 36)
        Column({ space: 6 }) {
          Row({ space: 8 }) {
            Text(comment.username)
              .fontSize(14).fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .layoutWeight(1)
            Text(comment.time)
              .fontSize(11).fontColor($r('app.color.text_tertiary'))
          }
          .width('100%')
          Text(comment.content)
            .fontSize(14).fontColor($r('app.color.text_primary'))
            .width('100%')
          if (comment.replies.length > 0) {
            Column({ space: 6 }) {
              ForEach(comment.replies, (reply: JmComment) => {
                this.replyItem(reply)
              }, (reply: JmComment) => reply.id + reply.username)
            }
            .width('100%')
          }
        }
        .layoutWeight(1).alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .id('commentItem' + comment.id)
  }

  build() {
    NavDestination() {
      
        Column({ space: 0 }) {
          if (this.loading) {
            Column() {
              LoadingProgress().width(40).height(40)
            }
            .layoutWeight(1).justifyContent(FlexAlign.Center)
          } else if (this.error.length > 0) {
            Column({ space: 12 }) {
              Text(this.error).fontSize(14).fontColor($r('app.color.danger'))
              Button(Translations.t('retry'))
                .fontSize(14)
                .backgroundColor(this.themeColor)
                .fontColor($r('app.color.text_on_brand'))
                .onClick(() => { this.loadPage(1, true); })
            }
            .layoutWeight(1).justifyContent(FlexAlign.Center)
          } else if (this.dataSource.totalCount() === 0) {
            Column({ space: 12 }) {
              SymbolGlyph($r('sys.symbol.message'))
                .fontSize(44)
                .fontColor([$r('app.color.text_tertiary')])
              Text(Translations.t('comment_empty'))
                .fontSize(14).fontColor($r('app.color.text_secondary'))
            }
            .layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
          } else {
            List({ space: 1 }) {
              LazyForEach(this.dataSource, (comment: JmComment) => {
                ListItem() {
                  this.commentItem(comment)
                }
              }, (comment: JmComment) => comment.id + comment.username)

              ListItem() {
                if (this.loadingMore) {
                  Column({ space: 8 }) {
                    LoadingProgress().width(32).height(32)
                  }
                  .width('100%').height(48).justifyContent(FlexAlign.Center)
                } else if (this.currentPage < this.maxPage) {
                  Text(Translations.t('load_more'))
                    .fontSize(13)
                    .fontColor(this.themeColor)
                    .width('100%').height(48)
                    .textAlign(TextAlign.Center)
                    .onClick(() => { this.loadMore(); })
                }
              }
            }
            .layoutWeight(1)
            .divider({ strokeWidth: 0.5, color: $r('app.color.divider') })
            .edgeEffect(EdgeEffect.Spring)
            .onReachEnd(() => { this.loadMore(); })
            .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
            .padding({ bottom: this.bottomAvoid })
          }

          Row({ space: 8 }) {
            TextInput({ placeholder: Translations.t('comment_placeholder'), text: this.inputText })
              .layoutWeight(1).height(40)
              .fontSize(14)
              .fontColor($r('app.color.text_primary'))
              .placeholderColor($r('app.color.text_secondary'))
              .caretColor(this.themeColor)
              .backgroundColor($r('app.color.bg_fill'))
              .borderRadius(20)
              .onChange((v: string) => {
                this.inputText = v;
              })
            Button(this.sending ? '...' : Translations.t('send'))
              .height(40).fontSize(14)
              .backgroundColor(this.themeColor)
              .fontColor($r('app.color.text_on_brand'))
              .onClick(() => {
                this.sendComment();
              })
          }
          .width('100%').padding({ left: 12, right: 12, top: 12, bottom: this.bottomAvoid + 12 })
          .backgroundColor($r('app.color.bg_page'))
          .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM])
        }
        .width('100%').height('100%')
        .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
      
    }
    .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.BOTTOM,SafeAreaEdge.TOP])
    .title(this.title.length > 0 ? this.title : Translations.t('comments'),
      { backgroundColor: $r('app.color.bg_page') })
    .hideTitleBar(false)
    .backgroundColor($r('app.color.bg_page'))
    .systemMaterial(new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    }))
  }
}
