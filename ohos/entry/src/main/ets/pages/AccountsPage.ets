// pages/AccountsPage.ets - 禁漫账号页（登录/签到/登出）- NavDestination
import { promptAction } from '@kit.ArkUI';
import { ThemeManager } from '../common/ThemeManager';
import { Translations } from '../common/Translations';
import { JmApi } from '../data/api/JmApi';
import { NavTitleBar } from '../components/NavTitleBar';

@Builder
export function AccountsPageBuilder(name: string, param: object) {
  AccountsPage()
}

@Component
export struct AccountsPage {
  @State account: string = ''
  @State password: string = ''
  @State loading: boolean = false
  @State loggedIn: boolean = false
  @State userName: string = ''
  @State userId: string = ''
  @State checkingIn: boolean = false
  @StorageLink('isDarkMode') isDarkMode: boolean = false
  @StorageLink('themeVersion') themeVersion: number = 0

  aboutToAppear(): void {
    this.refreshLoginState();
  }

  private refreshLoginState(): void {
    this.loggedIn = JmApi.isLoggedIn();
    this.userName = JmApi.getUserName();
    this.userId = JmApi.getUserId();
  }

  private notifyAccountChanged(): void {
    const prev: number | undefined = AppStorage.get<number>('jmAccountChanged');
    AppStorage.setOrCreate('jmAccountChanged', prev === undefined ? 1 : prev + 1);
  }

  async doLogin(): Promise<void> {
    if (this.account.length === 0 || this.password.length === 0) {
      promptAction.showToast({ message: Translations.t('input_account_password'), duration: 1500 });
      return;
    }
    this.loading = true;
    try {
      await JmApi.login(this.account, this.password);
      this.refreshLoginState();
      this.notifyAccountChanged();
      promptAction.showToast({ message: Translations.t('login_success'), duration: 1500 });
    } catch (e) {
      promptAction.showToast({ message: `${Translations.t('login_failed')}: ${String(e)}`, duration: 2000 });
    }
    this.loading = false;
  }

  async doLogout(): Promise<void> {
    try {
      await JmApi.logout();
    } catch (e) {
      // 忽略登出网络错误
    }
    this.refreshLoginState();
    this.notifyAccountChanged();
    promptAction.showToast({ message: Translations.t('logout_success'), duration: 1500 });
  }

  async doCheckIn(): Promise<void> {
    if (this.checkingIn) {
      return;
    }
    this.checkingIn = true;
    try {
      const msg: string = await JmApi.dailyChk();
      this.getUIContext().showAlertDialog({
        title: Translations.t('check_in'),
        message: msg,
        confirm: {
          value: Translations.t('confirm'),
          action: () => {
          }
        }
      });
    } catch (e) {
      this.getUIContext().showAlertDialog({
        title: Translations.t('check_in'),
        message: `${Translations.t('check_in_failed')}: ${String(e)}`,
        confirm: {
          value: Translations.t('confirm'),
          action: () => {
          }
        }
      });
    }
    this.checkingIn = false;
  }

  @Builder
  profileCard() {
    Column({ space: 16 }) {
      Row({ space: 16 }) {
        Stack() {
          SymbolGlyph($r('sys.symbol.person'))
            .fontSize(36)
            .fontColor(['#FFFFFF'])
        }
        .width(64).height(64)
        .borderRadius(32)
        .backgroundColor(ThemeManager.primary)

        Column({ space: 6 }) {
          Text(this.userName.length > 0 ? this.userName : Translations.t('jm_name'))
            .fontSize(19).fontWeight(FontWeight.Bold)
            .fontColor(ThemeManager.textPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .constraintSize({ maxWidth: '80%' })
          if (this.userId.length > 0) {
            Text(`UID: ${this.userId}`)
              .fontSize(13).fontColor(ThemeManager.textSecondary)
          }
          Text(Translations.t('jm_name'))
            .fontSize(11).fontColor(ThemeManager.primary)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor(ThemeManager.surface)
            .borderRadius(8)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      if (this.checkingIn) {
        Row({ space: 8 }) {
          LoadingProgress().width(20).height(20)
          Text(Translations.t('check_in'))
            .fontSize(14).fontColor(ThemeManager.textSecondary)
        }
      } else {
        Button(Translations.t('check_in'))
          .width('100%').height(44)
          .fontSize(15)
          .backgroundColor(ThemeManager.primary)
          .fontColor('#FFFFFF')
          .onClick(() => {
            this.doCheckIn();
          })
      }

      Button(Translations.t('logout'))
        .width('100%').height(44)
        .fontSize(15)
        .backgroundColor(ThemeManager.danger)
        .fontColor('#FFFFFF')
        .onClick(() => {
          this.doLogout();
        })
    }
    .width('100%')
    .padding(20)
    .backgroundColor(ThemeManager.surface)
    .borderRadius(16)
    .id('profileCard' + this.themeVersion)
  }

  @Builder
  loginForm() {
    Column({ space: 16 }) {
      Text(Translations.t('jm_name'))
        .fontSize(19).fontWeight(FontWeight.Bold)
        .fontColor(ThemeManager.textPrimary)
        .width('100%')

      TextInput({ placeholder: Translations.t('username') })
        .width('100%').height(46)
        .fontSize(15)
        .fontColor(ThemeManager.textPrimary)
        .placeholderColor(ThemeManager.textSecondary)
        .caretColor(ThemeManager.primary)
        .backgroundColor(ThemeManager.surface)
        .borderRadius(12)
        .onChange((v: string) => {
          this.account = v;
        })

      TextInput({ placeholder: Translations.t('password') })
        .width('100%').height(46)
        .fontSize(15)
        .fontColor(ThemeManager.textPrimary)
        .placeholderColor(ThemeManager.textSecondary)
        .caretColor(ThemeManager.primary)
        .type(InputType.Password)
        .backgroundColor(ThemeManager.surface)
        .borderRadius(12)
        .onChange((v: string) => {
          this.password = v;
        })

      if (this.loading) {
        LoadingProgress().width(32).height(32)
      } else {
        Button(Translations.t('login'))
          .width('100%').height(46)
          .fontSize(16)
          .backgroundColor(ThemeManager.primary)
          .fontColor('#FFFFFF')
          .borderRadius(23)
          .onClick(() => {
            this.doLogin();
          })
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(ThemeManager.surface)
    .borderRadius(16)
    .id('loginForm' + this.themeVersion)
  }

  build() {
    NavDestination() {
      ForEach([this.themeVersion], (v: number) => {
        Column() {
          NavTitleBar({ title: Translations.t('account') })
          Scroll() {
            Column({ space: 16 }) {
              if (this.loggedIn) {
                this.profileCard()
              } else {
                this.loginForm()
              }
            }
            .width('100%')
            .padding(16)
          }
          .width('100%').layoutWeight(1)
          .scrollBar(BarState.Off)
          .edgeEffect(EdgeEffect.Spring)
        }
        .width('100%').height('100%')
      }, (v: number) => `theme-${v}`)
    }
    .hideTitleBar(true)
    .backgroundColor(this.themeVersion >= 0 ? ThemeManager.background : '')
  }
}
