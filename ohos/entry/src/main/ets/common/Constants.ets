// common/Constants.ets - API 地址、常量定义
export class ApiConstants {
  // Picacg
  static readonly PICACG_API = 'https://picaapi.picacomic.com';
  static readonly PICACG_API_KEY = 'C69BAF41DA5ABD1FFEDC6D2FEA56B';
  static readonly PICACG_SIGN_KEY = '~d}$Q7$eIni=V)9\\RK/P.RM4;9[7|@/CA}b~OW!3?EV`:<>M7pddUBL5n|0/*Cn';
  static readonly PICACG_VERSION = 'v1.4.1';
  static readonly PICACG_APP_VERSION = '2.2.1.3.3.4';
  static readonly PICACG_BUILD_VERSION = '45';
  static readonly PICACG_APP_CHANNEL = '3';
  static readonly PICACG_APP_PLATFORM = 'android';

  // EHentai
  static readonly EHENTAI_BASE = 'https://e-hentai.org';
  static readonly EHENTAI_API = 'https://api.e-hentai.org/api.php';
  static readonly EXHENTAI_BASE = 'https://exhentai.org';
  static readonly EXHENTAI_API = 'https://exhentai.org/api.php';

  // NHentai
  static readonly NHENTAI_BASE = 'https://nhentai.net';
  static readonly NHENTAI_API = 'https://nhentai.net/api/v2';

  // Hitomi
  static readonly HITOMI_BASE = 'https://hitomi.la';

  // JM (禁漫)
  static readonly JM_DEFAULT_BASE = 'https://jmcomic.me';
  static readonly JM_APP_VERSION = '1.7.1';
  static readonly JM_AUTH_KEY = '18comicAPPContent';
  static readonly JM_SECRET = '185Hcomic3PAPP7R';
  static readonly JM_DOMAIN_SECRET: number[] = [
    100, 105, 111, 115, 102, 106, 99, 107, 119, 112, 113, 112,
    100, 102, 106, 107, 118, 110, 113, 81, 106, 115, 105, 107
  ];
  static readonly JM_DOMAIN_URLS: string[] = [
    'https://rup4a04-c02.tos-cn-hongkong.bytepluses.com/newsvr-2025.txt',
    'https://rup4a04-c01.tos-ap-southeast-1.bytepluses.com/newsvr-2025.txt'
  ];
  static readonly JM_CDN_URLS: string[] = [
    'https://cdn-msp3.jmapiproxy1.cc',
    'https://cdn-msp.jmapiproxy3.cc',
    'https://cdn-msp2.jmapiproxy2.cc',
    'https://cdn-msp3.jmapiproxy3.cc'
  ];

  // HT (绅士漫画)
  static readonly HT_DEFAULT_BASE = 'https://www.wnacg.com';
  static readonly HT_DOMAIN_URL = 'https://raw.githubusercontent.com/ccbkv/PicaComicapitxt/refs/heads/main/htmanga_api_list.txt';

  // App
  static readonly APP_VERSION = '1.0.0';
  static readonly APP_NAME = 'PicaComic';
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
  static readonly LANGUAGE = 'language';
  static readonly VOLUME_KEY = 'volumeKey';
  static readonly KEEP_SCREEN_ON = 'keepScreenOn';
  static readonly FONT_SIZE = 'fontSize';
  static readonly IMAGE_QUALITY = 'imageQuality';
  static readonly JM_DOMAIN_INDEX = 'jmDomainIndex';
  static readonly JM_DOMAINS = 'jmDomains';
  static readonly JM_DOMAIN_UPDATE_TIME = 'jmDomainUpdateTime';
  static readonly HT_BASE_URL = 'htBaseUrl';
  static readonly LAST_VERSION = 'lastVersion';
}
