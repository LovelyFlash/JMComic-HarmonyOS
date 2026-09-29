// pages/CommentsPage.ets - 评论页（禁漫网络评论）- NavDestination
import { promptAction } from '@kit.ArkUI';
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';
import { JmApi, JmComment } from '../data/api/JmApi';
import { NavTitleBar } from '../components/NavTitleBar';

@Builder
export function CommentsPageBuilder(name: string, param: object) {
  CommentsPage({ pageParam: param })
}

@Component
export struct CommentsPage {
  pageParam: object | undefined = undefined;
  @State comicId: string = ''
  @State title: string = ''
  @State comments: JmComment[] = []
  @State inputText: string = ''
  @State loading: boolean = true
  @State loadingMore: boolean = false
  @State error: string = ''
  @State currentPage: number = 1
  @State maxPage: number = 1
  @State sending: boolean = false
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @StorageLink('themeVersion') themeVersion: number = 0

  aboutToAppear(): void {
    if (this.pageParam !== undefined && this.pageParam !== null) {
      const params = this.pageParam as Record<string, Object>;
      this.comicId = params['comicId'] !== undefined && params['comicId'] !== null ? String(params['comicId']) : '';
      this.title = params['title'] !== undefined && params['title'] !== null ? String(params['title']) : '';
    }
    this.loadPage(1, true);
  }

  async loadPage(page: number, replace: boolean): Promise<void> {
    if (replace) {
      this.loading = true;
      this.error = '';
    }
    try {
      const result = await JmApi.getComments(this.comicId, page);
      this.maxPage = result.maxPage > 0 ? result.maxPage : 1;
      this.currentPage = page;
      if (replace) {
        this.comments = result.comments;
      } else {
        const merged: JmComment[] = this.comments.slice();
        for (let i = 0; i < result.comments.length; i++) {
          merged.push(result.comments[i]);
        }
        this.comments = merged;
      }
    } catch (e) {
      if (replace) {
        this.error = String(e);
        this.comments = [];
      }
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
      promptAction.showToast({ message: Translations.t('comment_empty_input'), duration: 1500 });
      return;
    }
    if (!JmApi.isLoggedIn()) {
      promptAction.showToast({ message: Translations.t('please_login'), duration: 1500 });
      return;
    }
    if (this.sending) {
      return;
    }
    this.sending = true;
    try {
      await JmApi.postComment(this.comicId, text);
      this.inputText = '';
      promptAction.showToast({ message: Translations.t('comment_success'), duration: 1500 });
      this.loadPage(1, true);
    } catch (e) {
      promptAction.showToast({ message: String(e), duration: 2000 });
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
        .backgroundColor(ThemeManager.surface)
        .id('avatarOrFallback' + this.themeVersion)
    } else {
      Column() {
        SymbolGlyph($r('sys.symbol.person'))
          .fontSize(size * 0.6)
          .fontColor([ThemeManager.primary])
      }
      .width(size).height(size)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(ThemeManager.surface)
      .borderRadius(size / 2)
      .id('avatarOrFallback' + this.themeVersion)
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
            .fontColor(ThemeManager.textPrimary)
          Text(reply.time)
            .fontSize(10).fontColor(ThemeManager.textTertiary)
        }
        .width('100%')
        Text(reply.content)
          .fontSize(13).fontColor(ThemeManager.textPrimary)
          .width('100%')
      }
      .layoutWeight(1).alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8, left: 8 })
    .backgroundColor(ThemeManager.surfaceSecondary)
    .borderRadius(8)
    .id('replyItem' + reply.id + this.themeVersion)
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
              .fontColor(ThemeManager.textPrimary)
              .layoutWeight(1)
            Text(comment.time)
              .fontSize(11).fontColor(ThemeManager.textTertiary)
          }
          .width('100%')
          Text(comment.content)
            .fontSize(14).fontColor(ThemeManager.textPrimary)
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
    .id('commentItem' + comment.id + this.themeVersion)
  }

  build() {
    NavDestination() {
      ForEach([this.themeVersion], (v: number) => {
        Column({ space: 0 }) {
          NavTitleBar({ title: this.title.length > 0 ? this.title : Translations.t('comments') })
          if (this.loading) {
            Column() {
              LoadingProgress().width(40).height(40)
            }
            .layoutWeight(1).justifyContent(FlexAlign.Center)
          } else if (this.error.length > 0) {
            Column({ space: 12 }) {
              Text(this.error).fontSize(14).fontColor(ThemeManager.danger)
              Button(Translations.t('retry'))
                .fontSize(14)
                .backgroundColor(ThemeManager.primary)
                .fontColor('#FFFFFF')
                .onClick(() => { this.loadPage(1, true); })
            }
            .layoutWeight(1).justifyContent(FlexAlign.Center)
          } else if (this.comments.length === 0) {
            Column({ space: 12 }) {
              SymbolGlyph($r('sys.symbol.message'))
                .fontSize(44)
                .fontColor([ThemeManager.textTertiary])
              Text(Translations.t('comment_empty'))
                .fontSize(14).fontColor(ThemeManager.textSecondary)
            }
            .layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
          } else {
            List({ space: 1 }) {
              ForEach(this.comments, (comment: JmComment) => {
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
                    .fontColor(ThemeManager.primary)
                    .width('100%').height(48)
                    .textAlign(TextAlign.Center)
                    .onClick(() => { this.loadMore(); })
                }
              }
            }
            .layoutWeight(1)
            .divider({ strokeWidth: 0.5, color: ThemeManager.divider })
            .edgeEffect(EdgeEffect.Spring)
            .onReachEnd(() => { this.loadMore(); })
          }

          Row({ space: 8 }) {
            TextInput({ placeholder: Translations.t('comment_placeholder'), text: this.inputText })
              .layoutWeight(1).height(40)
              .fontSize(14)
              .fontColor(ThemeManager.textPrimary)
              .placeholderColor(ThemeManager.textSecondary)
              .caretColor(ThemeManager.primary)
              .backgroundColor(ThemeManager.surface)
              .borderRadius(20)
              .onChange((v: string) => {
                this.inputText = v;
              })
            Button(this.sending ? '...' : Translations.t('send'))
              .height(40).fontSize(14)
              .backgroundColor(ThemeManager.primary)
              .fontColor('#FFFFFF')
              .onClick(() => {
                this.sendComment();
              })
          }
          .width('100%').padding(12)
          .backgroundColor(ThemeManager.background)
        }
        .width('100%').height('100%')
        .backgroundColor(ThemeManager.background)
      }, (v: number) => `theme-${v}`)
    }
    .hideTitleBar(true)
    .backgroundColor(this.themeVersion >= 0 ? ThemeManager.background : '')
  }
}
