// common/Constants.ets - API 地址、常量定义
export class ApiConstants {
  // JM (禁漫)
  /** 对齐 jm_config.py JmMagicConstants.APP_VERSION（tokenparam 版本号，运行时可被 version.json 覆盖） */
  static readonly JM_APP_VERSION = '2.1.7';
  /** jm_config.py APP_TOKEN_SECRET_2：仅 /chapter_view_template（scramble_id）接口的 token 密钥 */
  static readonly JM_AUTH_KEY = '18comicAPPContent';
  /** jm_config.py APP_TOKEN_SECRET = APP_DATA_SECRET：普通接口 token 密钥 + 响应 data 解密密钥 */
  static readonly JM_SECRET = '185Hcomic3PAPP7R';
  static readonly JM_SCRAMBLE_FALLBACK = '220980';
  /** jm_config.py API_DOMAIN_SERVER_SECRET（'diosfjckwpqpdfjkvnqQjsik' 的字节数组，域名列表解密用） */
  static readonly JM_DOMAIN_SECRET: number[] = [
    100, 105, 111, 115, 102, 106, 99, 107, 119, 112, 113, 112,
    100, 102, 106, 107, 118, 110, 113, 81, 106, 115, 105, 107
  ];
  static readonly JM_DOMAIN_URLS: string[] = [
    'https://rup4a04-c02.tos-cn-hongkong.bytepluses.com/newsvr-2025.txt',
    'https://rup4a04-c01.tos-ap-southeast-1.bytepluses.com/newsvr-2025.txt'
  ];
  /** 内置 API 域名（裸主机名，与原版 base.dart settings[85] 一致） */
  static readonly JM_BUILTIN_API_DOMAINS: string[] = [
    'www.cdntwice.org',
    'www.cdnsha.org',
    'www.cdnaspa.cc',
    'www.cdnntr.cc'
  ];
  /** 远端域名获取失败时的回退列表（与原版 jm_settings.dart builtInApiDomains 一致） */
  static readonly JM_FALLBACK_API_DOMAINS: string[] = [
    'www.cdnaspa.vip',
    'www.cdnaspa.club',
    'www.cdnplaystation6.vip',
    'www.cdnplaystation6.cc'
  ];
  /** 图片分流候选（与原版 builtInImgUrls 一致，updateImgUrl 失败时回退用） */
  static readonly JM_IMG_URLS: string[] = [
    'https://cdn-msp3.jmapiproxy1.cc',
    'https://cdn-msp.jmapiproxy3.cc',
    'https://cdn-msp2.jmapiproxy2.cc',
    'https://cdn-msp3.jmapiproxy3.cc'
  ];
  /** 默认图床（与原版 settings[86] 默认值一致） */
  static readonly JM_DEFAULT_IMG_HOST = 'https://cdn-msp.jmapiproxy3.cc';
  static readonly JM_USER_AGENT = 'Mozilla/5.0 (Linux; Android 10; K; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/138.0.0.0 Mobile Safari/537.36';
  static readonly JM_PACKAGE_NAME = 'com.example.app';

  // App
  static readonly APP_VERSION = '1.0.0';
  static readonly APP_NAME = 'JMComic';
}

export class DatabaseConstants {
  static readonly DB_NAME = 'pica_comic.db';
  static readonly TABLE_HISTORY = 'history';
  static readonly TABLE_FAVORITES = 'favorites';
  static readonly TABLE_DOWNLOADS = 'downloads';
}

export class SettingsKeys {
  static readonly DARK_MODE = 'darkMode';
  static readonly THEME_COLOR = 'themeColor';
  static readonly SHOW_HISTORY_IMAGES = 'showHistoryImages';
  static readonly LANGUAGE = 'language';
  static readonly VOLUME_KEY = 'volumeKey';
  static readonly KEEP_SCREEN_ON = 'keepScreenOn';
  static readonly FONT_SIZE = 'fontSize';
  static readonly IMAGE_QUALITY = 'imageQuality';
  static readonly JM_DOMAIN_INDEX = 'jmDomainIndex';
  static readonly JM_DOMAINS = 'jmDomains';
  static readonly JM_DOMAIN_UPDATE_TIME = 'jmDomainUpdateTime';
  static readonly JM_ACCOUNT = 'jm_account';
  static readonly JM_PASSWORD = 'jm_password';
  static readonly JM_USER_NAME = 'jm_user_name';
  static readonly JM_USER_ID = 'jm_user_id';
  static readonly JM_AUTO_SELECT_DOMAIN = 'jm_auto_select_domain';
  static readonly JM_IMG_LINE_INDEX = 'jm_img_line_index';
  static readonly JM_IMG_HOST = 'jm_img_host';
  static readonly JM_APP_VERSION = 'jm_app_version';
  static readonly JM_AUTO_CHECKIN = 'jm_auto_checkin';
  static readonly JM_FAVORITE_ORDER = 'jm_favorite_order';
  // Reading settings
  static readonly READ_MODE = 'readMode';
  static readonly TAP_TURN_PAGE = 'tapTurnPage';
  static readonly INVERT_TAP = 'invertTap';
  static readonly VOLUME_KEY_TURN = 'volumeKeyTurnPage';
  static readonly SIDE_PAGE_TURN = 'sidePageTurn';
  static readonly PAGE_ANIMATION = 'pageAnimation';
  static readonly SHOW_PAGE_INFO = 'showPageInfo';
  static readonly DOUBLE_TAP_ZOOM = 'doubleTapZoom';
  static readonly LONG_PRESS_ZOOM = 'longPressZoom';
  static readonly IMAGE_LAYOUT = 'imageLayout';
  static readonly AUTO_PAGE_TIME = 'autoPageTime';
  static readonly SEARCH_HISTORY = 'searchHistory';
}
