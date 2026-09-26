// common/Translations.ets - 国际化翻译
class TranslationData {
    app_name: string = '';
    tab_explore: string = '';
    tab_history: string = '';
    tab_favorites: string = '';
    tab_settings: string = '';
    search_hint: string = '';
    loading: string = '';
    error: string = '';
    retry: string = '';
    no_data: string = '';
    dark_mode: string = '';
    theme_color: string = '';
    language: string = '';
    about: string = '';
    version: string = '';
    download: string = '';
    settings_appearance: string = '';
    settings_reading: string = '';
    settings_comic_source: string = '';
    settings_system: string = '';
    volume_key: string = '';
    keep_screen_on: string = '';
    font_size: string = '';
    image_quality: string = '';
    cache: string = '';
    jm_domain_update: string = '';
    ht_domain_update: string = '';
}
const zhData: TranslationData = new TranslationData();
zhData.app_name = 'PicaComic';
zhData.tab_explore = '探索';
zhData.tab_history = '历史';
zhData.tab_favorites = '收藏';
zhData.tab_settings = '设置';
zhData.search_hint = '搜索漫画...';
zhData.loading = '加载中...';
zhData.error = '出错了';
zhData.retry = '重试';
zhData.no_data = '暂无数据';
zhData.dark_mode = '深色模式';
zhData.theme_color = '主题颜色';
zhData.language = '语言';
zhData.about = '关于';
zhData.version = '版本';
zhData.download = '下载';
zhData.settings_appearance = '外观设置';
zhData.settings_reading = '阅读设置';
zhData.settings_comic_source = '漫画源设置';
zhData.settings_system = '系统设置';
zhData.volume_key = '音量键翻页';
zhData.keep_screen_on = '屏幕常亮';
zhData.font_size = '字体大小';
zhData.image_quality = '图片质量';
zhData.cache = '缓存';
zhData.jm_domain_update = '域名更新';
zhData.ht_domain_update = '域名更新';
const enData: TranslationData = new TranslationData();
enData.app_name = 'PicaComic';
enData.tab_explore = 'Explore';
enData.tab_history = 'History';
enData.tab_favorites = 'Favorites';
enData.tab_settings = 'Settings';
enData.search_hint = 'Search comics...';
enData.loading = 'Loading...';
enData.error = 'Something went wrong';
enData.retry = 'Retry';
enData.no_data = 'No data available';
enData.dark_mode = 'Dark Mode';
enData.theme_color = 'Theme Color';
enData.language = 'Language';
enData.about = 'About';
enData.version = 'Version';
enData.download = 'Download';
enData.settings_appearance = 'Appearance';
enData.settings_reading = 'Reading';
enData.settings_comic_source = 'Comic Sources';
enData.settings_system = 'System';
enData.volume_key = 'Volume Key Page Turn';
enData.keep_screen_on = 'Keep Screen On';
enData.font_size = 'Font Size';
enData.image_quality = 'Image Quality';
enData.cache = 'Cache';
enData.jm_domain_update = 'Domain Update';
enData.ht_domain_update = 'Domain Update';
export class Translations {
    private static currentLocale: string = 'zh_CN';
    static setLocale(locale: string): void {
        if (locale === 'zh_CN' || locale === 'en_US') {
            Translations.currentLocale = locale;
        }
    }
    static getLocale(): string {
        return Translations.currentLocale;
    }
    static t(key: string): string {
        const d = Translations.currentLocale === 'en_US' ? enData : zhData;
        switch (key) {
            case 'app_name': return d.app_name;
            case 'tab_explore': return d.tab_explore;
            case 'tab_history': return d.tab_history;
            case 'tab_favorites': return d.tab_favorites;
            case 'tab_settings': return d.tab_settings;
            case 'search_hint': return d.search_hint;
            case 'loading': return d.loading;
            case 'error': return d.error;
            case 'retry': return d.retry;
            case 'no_data': return d.no_data;
            case 'dark_mode': return d.dark_mode;
            case 'theme_color': return d.theme_color;
            case 'language': return d.language;
            case 'about': return d.about;
            case 'version': return d.version;
            case 'download': return d.download;
            case 'settings_appearance': return d.settings_appearance;
            case 'settings_reading': return d.settings_reading;
            case 'settings_comic_source': return d.settings_comic_source;
            case 'settings_system': return d.settings_system;
            case 'volume_key': return d.volume_key;
            case 'keep_screen_on': return d.keep_screen_on;
            case 'font_size': return d.font_size;
            case 'image_quality': return d.image_quality;
            case 'cache': return d.cache;
            case 'jm_domain_update': return d.jm_domain_update;
            case 'ht_domain_update': return d.ht_domain_update;
            default: return key;
        }
    }
    static getLanguages(): string[] {
        return ['zh_CN', 'en_US'];
    }
}
