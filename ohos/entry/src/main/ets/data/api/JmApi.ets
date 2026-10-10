// data/api/JmApi.ets - 禁漫天堂 API 客户端（对照原版 jm_network.dart 完整重写）
import { Network, NetworkResp } from '../../common/Network';
import { Logger } from '../../common/Logger';
import { Comic } from '../model/Comic';
import { Chapter } from '../model/Chapter';
import { ApiConstants, SettingsKeys } from '../../common/Constants';
import { Settings } from '../preferences/Settings';
import cryptoFramework from '@ohos.security.cryptoFramework';
import { util } from '@kit.ArkTS';

const TAG = 'JmApi';

export class JmPagedResult {
  comics: Comic[] = [];
  maxPage: number = 0;
}

export class JmHomeSection {
  title: string = '';
  id: string = '';
  comics: Comic[] = [];
}

export class JmFolder {
  id: string = '';
  name: string = '';
}

export class JmComment {
  id: string = '';
  avatar: string = '';
  username: string = '';
  time: string = '';
  content: string = '';
  replies: JmComment[] = [];
}

export class JmCommentPage {
  comments: JmComment[] = [];
  maxPage: number = 1;
}

export class JmWeekCategory {
  id: string = '';
  label: string = '';
}

export class JmApi {
  // ========== State ==========
  private static domains: string[] = [];
  private static domainIndex: number = 0;
  private static currentDomain: string = `https://${ApiConstants.JM_BUILTIN_API_DOMAINS[0]}`;
  private static imgHost: string = ApiConstants.JM_DEFAULT_IMG_HOST;
  private static scramblePromises: Map<string, Promise<string>> = new Map();
  private static imgLineIndex: number = 1;
  private static appVersion: string = ApiConstants.JM_APP_VERSION;
  private static account: string = '';
  private static password: string = '';
  private static userName: string = '';
  private static userId: string = '';
  private static loggedIn: boolean = false;
  private static performingLogin: boolean = false;
  private static initialized: boolean = false;
  private static readonly DOMAIN_UPDATE_INTERVAL: number = 24 * 60 * 60 * 1000;

  // ========== Helpers ==========

  private static safeStr(obj: Object | undefined, key: string, def: string = ''): string {
    if (obj === undefined || obj === null) {
      return def;
    }
    const rec = obj as Record<string, Object>;
    const val = rec[key];
    return val !== undefined && val !== null ? String(val) : def;
  }

  private static safeNum(obj: Object | undefined, key: string, def: number = 0): number {
    if (obj === undefined || obj === null) {
      return def;
    }
    const rec = obj as Record<string, Object>;
    const val = rec[key];
    return val !== undefined && val !== null ? Number(val) : def;
  }

  private static toInt(val: Object | undefined, def: number): number {
    if (val === undefined || val === null) {
      return def;
    }
    const n: number = Number(val);
    return Number.isNaN(n) ? def : n;
  }

  private static isTruthy(val: Object | undefined): boolean {
    return val === true || val === 1 || val === 'true' || val === '1';
  }

  private static toStringArray(val: Object | undefined): string[] {
    const result: string[] = [];
    if (val !== undefined && val !== null && Array.isArray(val)) {
      const arr: Object[] = val as Object[];
      for (let i = 0; i < arr.length; i++) {
        result.push(String(arr[i]));
      }
    }
    return result;
  }

  private static normalizeDomain(domain: string): string {
    let d: string = domain.trim();
    while (d.endsWith('/')) {
      d = d.substring(0, d.length - 1);
    }
    if (d.length > 0 && d.indexOf('http') !== 0) {
      d = `https://${d}`;
    }
    return d;
  }

  /** 查询参数编码：encodeURIComponent + 空格转 +（与原版搜索一致） */
  private static encodeValue(v: string): string {
    return encodeURIComponent(v).replace(/%20/g, '+');
  }

  private static htmlToText(html: string): string {
    let s: string = html;
    s = s.replace(/<br\s*\/?>/gi, '\n');
    s = s.replace(/<[^>]+>/g, '');
    s = s.replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&quot;/g, '"')
      .replace(/&#39;/g, '\'')
      .replace(/&nbsp;/g, ' ')
      .replace(/&amp;/g, '&');
    return s.trim();
  }

  private static avatarUrl(photo: string): string {
    if (photo === '') {
      return '';
    }
    if (photo.indexOf('http') === 0) {
      return photo;
    }
    return `${JmApi.imgHost}/media/users/${photo}`;
  }

  // ========== Accessors（供设置页/我的页使用） ==========

  static getDomains(): string[] {
    return JmApi.domains;
  }

  static getDomainIndex(): number {
    return JmApi.domainIndex;
  }

  static getDomain(): string {
    return JmApi.currentDomain;
  }

  static getImgHost(): string {
    return JmApi.imgHost;
  }

  static getImgLineIndex(): number {
    return JmApi.imgLineIndex;
  }

  static getAppVersion(): string {
    return JmApi.appVersion;
  }

  static isLoggedIn(): boolean {
    return JmApi.loggedIn;
  }

  static getUserName(): string {
    return JmApi.userName;
  }

  static getUserId(): string {
    return JmApi.userId;
  }

  static getAccount(): string {
    return JmApi.account;
  }

  /** 登录态变更广播：bump AppStorage jmAccountChanged，驱动 MePage/FavoritesContent/AccountsPage 等页面刷新 */
  private static notifyAccountChanged(): void {
    try {
      const prev: number | undefined = AppStorage.get<number>('jmAccountChanged');
      AppStorage.setOrCreate('jmAccountChanged', prev === undefined ? 1 : prev + 1);
    } catch (e) {
      Logger.warn(TAG, `notifyAccountChanged failed: ${Logger.describe(e)}`);
    }
  }

  // ========== Init ==========

  static async init(): Promise<void> {
    if (JmApi.initialized) {
      return;
    }
    JmApi.initialized = true;
    const savedDomains: string[] = await Settings.getStringList(SettingsKeys.JM_DOMAINS, []);
    const normalized: string[] = [];
    for (let i = 0; i < savedDomains.length; i++) {
      const d: string = JmApi.normalizeDomain(savedDomains[i]);
      if (d !== '') {
        normalized.push(d);
      }
    }
    if (normalized.length > 0) {
      JmApi.domains = normalized;
    } else {
      JmApi.domains = JmApi.builtinDomains();
    }
    JmApi.domainIndex = await Settings.getNumber(SettingsKeys.JM_DOMAIN_INDEX, 0);
    if (JmApi.domainIndex < 0 || JmApi.domainIndex >= JmApi.domains.length) {
      JmApi.domainIndex = 0;
    }
    JmApi.currentDomain = JmApi.domains[JmApi.domainIndex];
    JmApi.imgHost = await Settings.getString(SettingsKeys.JM_IMG_HOST, ApiConstants.JM_DEFAULT_IMG_HOST);
    JmApi.imgLineIndex = await Settings.getNumber(SettingsKeys.JM_IMG_LINE_INDEX, 1);
    JmApi.appVersion = await Settings.getString(SettingsKeys.JM_APP_VERSION, ApiConstants.JM_APP_VERSION);
    JmApi.account = await Settings.getString(SettingsKeys.JM_ACCOUNT, '');
    JmApi.password = await Settings.getString(SettingsKeys.JM_PASSWORD, '');
    JmApi.userName = await Settings.getString(SettingsKeys.JM_USER_NAME, '');
    JmApi.userId = await Settings.getString(SettingsKeys.JM_USER_ID, '');
    JmApi.loggedIn = JmApi.account !== '' && JmApi.password !== '';
    // 持久化恢复完成，广播登录态（驱动已创建页面刷新，避免"重进显示未登录"）
    JmApi.notifyAccountChanged();
    if (JmApi.loggedIn) {
      // cookie 短效，每次启动重新登录（与原版一致），后台执行不阻塞启动
      JmApi.reLogin().catch((e: Object) => {
        Logger.warn(TAG, `reLogin on init failed: ${Logger.describe(e)}`);
      });
    }
    // 后台域名保鲜：24h 周期外拉取新鲜域名，替换可能过期的内置列表
    JmApi.updateDomainsIfStale().catch((e: Object) => {
      Logger.warn(TAG, `updateDomainsIfStale failed: ${Logger.describe(e)}`);
    });
  }

  private static builtinDomains(): string[] {
    const result: string[] = [];
    for (let i = 0; i < ApiConstants.JM_BUILTIN_API_DOMAINS.length; i++) {
      result.push(JmApi.normalizeDomain(ApiConstants.JM_BUILTIN_API_DOMAINS[i]));
    }
    return result;
  }

  // ========== Domain Management ==========

  /** 应用域名列表（规范化 + 持久化） */
  static async applyDomains(rawList: string[]): Promise<void> {
    const normalized: string[] = [];
    for (let i = 0; i < rawList.length; i++) {
      const d: string = JmApi.normalizeDomain(rawList[i]);
      if (d !== '') {
        normalized.push(d);
      }
    }
    if (normalized.length === 0) {
      return;
    }
    JmApi.domains = normalized;
    if (JmApi.domainIndex >= JmApi.domains.length) {
      JmApi.domainIndex = 0;
    }
    JmApi.currentDomain = JmApi.domains[JmApi.domainIndex];
    await Settings.putStringList(SettingsKeys.JM_DOMAINS, JmApi.domains);
  }

  /** 手动选择域名（设置页点击）；已登录时按原版行为静默重登 */
  static async selectDomainAt(index: number): Promise<void> {
    if (index < 0 || index >= JmApi.domains.length) {
      return;
    }
    JmApi.domainIndex = index;
    JmApi.currentDomain = JmApi.domains[index];
    await Settings.putNumber(SettingsKeys.JM_DOMAIN_INDEX, index);
    if (JmApi.loggedIn) {
      JmApi.reLogin().catch((e: Object) => {
        Logger.warn(TAG, `reLogin after selectDomainAt failed: ${Logger.describe(e)}`);
      });
    }
  }

  /** 从远端拉取域名密文并解密，返回裸主机名列表（失败返回 []，无副作用） */
  static async fetchDomains(): Promise<string[]> {
    const secretStr: string = JmApi.bytesToString(ApiConstants.JM_DOMAIN_SECRET);
    for (let i = 0; i < ApiConstants.JM_DOMAIN_URLS.length; i++) {
      try {
        const resp: string = await Network.get(ApiConstants.JM_DOMAIN_URLS[i]);
        if (resp === '') {
          continue;
        }
        // 对齐 req_api_domain_server：去掉开头非 ASCII 字符
        let text: string = resp;
        while (text.length > 0 && text.charCodeAt(0) > 0x7F) {
          text = text.substring(1);
        }
        const decrypted: string = await JmApi.aesEcbDecrypt(text, secretStr);
        if (decrypted === '') {
          continue;
        }
        const parsed: Record<string, Object> = JSON.parse(decrypted) as Record<string, Object>;
        const serverList: string[] = JmApi.toStringArray(parsed['Server']);
        if (serverList.length > 0) {
          return serverList.slice(0, 4);
        }
      } catch (e) {
        Logger.error(TAG, `fetchDomains from URL[${i}] failed: ${Logger.describe(e)}`);
      }
    }
    return [];
  }

  /** 24h 周期外直接返回当前列表；到期则尝试远端更新 */
  static async updateDomainsIfStale(): Promise<boolean> {
    const last: number = await Settings.getNumber(SettingsKeys.JM_DOMAIN_UPDATE_TIME, 0);
    if (Date.now() - last < JmApi.DOMAIN_UPDATE_INTERVAL) {
      return true;
    }
    const fetched: string[] = await JmApi.fetchDomains();
    if (fetched.length > 0) {
      await JmApi.applyDomains(fetched);
      await Settings.putNumber(SettingsKeys.JM_DOMAIN_UPDATE_TIME, Date.now());
      return true;
    }
    return false;
  }

  /** 单域名探测：POST /login body '&' 期望 401，8s 超时（与原版一致） */
  private static async probeDomain(domain: string): Promise<boolean> {
    const time: string = String(Math.floor(Date.now() / 1000));
    const headers: Record<string, string> = JmApi.buildHeaders(time, true);
    const resp: NetworkResp = await Network.postWithStatus(`${domain}/login`, '&', headers, 8000);
    return resp.code === 401;
  }

  /** 并发探测全部域名：POST /login body '&' 期望 401，最快命中者胜出并持久化（对齐原版自动分流） */
  static async selectDomain(): Promise<number> {
    if (JmApi.domains.length === 0) {
      JmApi.domains = JmApi.builtinDomains();
    }
    return new Promise<number>((resolve: (index: number) => void) => {
      let settled: boolean = false;
      let pending: number = JmApi.domains.length;
      for (let i = 0; i < JmApi.domains.length; i++) {
        const idx: number = i;
        const domain: string = JmApi.domains[idx];
        JmApi.probeDomain(domain).then((ok: boolean) => {
          pending--;
          if (ok && !settled) {
            settled = true;
            JmApi.domainIndex = idx;
            JmApi.currentDomain = domain;
            Settings.putNumber(SettingsKeys.JM_DOMAIN_INDEX, idx).catch((e: Object) => {
              Logger.warn(TAG, `persist domain index failed: ${Logger.describe(e)}`);
            });
            Logger.info(TAG, `Selected JM API domain: ${domain}`);
            resolve(idx);
          } else if (pending === 0 && !settled) {
            settled = true;
            resolve(-1);
          }
        });
      }
    });
  }

  /** 当前域名健康检查（POST /login 期望 401，8s 超时） */
  static async healthCheck(): Promise<boolean> {
    try {
      return await JmApi.probeDomain(JmApi.currentDomain);
    } catch (e) {
      Logger.error(TAG, `healthCheck failed: ${Logger.describe(e)}`);
      return false;
    }
  }

  /** 图片分流切换（lineIndex 0-3 → app_img_shunt 1-4），失败保留旧图床（与原版一致） */
  static async updateImgUrl(lineIndex: number): Promise<boolean> {
    const clamped: number = Math.min(Math.max(lineIndex, 0), ApiConstants.JM_IMG_URLS.length - 1);
    JmApi.imgLineIndex = clamped;
    await Settings.putNumber(SettingsKeys.JM_IMG_LINE_INDEX, clamped);
    try {
      const data: Record<string, Object> =
        await JmApi.apiGet('/setting', { 'app_img_shunt': String(clamped + 1) }) as Record<string, Object>;
      const host: string = JmApi.safeStr(data, 'img_host');
      if (host !== '') {
        JmApi.imgHost = JmApi.normalizeDomain(host);
        await Settings.putString(SettingsKeys.JM_IMG_HOST, JmApi.imgHost);
        Logger.info(TAG, `Updated JM image URL: ${JmApi.imgHost}`);
        return true;
      }
    } catch (e) {
      Logger.warn(TAG, `updateImgUrl failed: ${Logger.describe(e)}`);
    }
    return false;
  }

  /** 仅持久化图片分流选择（不发请求）；未登录时设置页调用 */
  static async setImgLineIndex(lineIndex: number): Promise<void> {
    const clamped: number = Math.min(Math.max(lineIndex, 0), ApiConstants.JM_IMG_URLS.length - 1);
    JmApi.imgLineIndex = clamped;
    await Settings.putNumber(SettingsKeys.JM_IMG_LINE_INDEX, clamped);
  }

  /** 获取远端 APP 版本号（明文 JSON），成功则持久化 */
  static async getAppVersionCode(): Promise<string> {
    const url: string = `${JmApi.currentDomain}/static/jmapp3apk/version.json`;
    const headers: Record<string, string> = {
      'Accept': '*/*',
      'Accept-Language': 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7',
      'User-Agent': ApiConstants.JM_USER_AGENT,
      'X-Requested-With': ApiConstants.JM_PACKAGE_NAME,
      'Origin': 'https://localhost',
      'Referer': 'https://localhost/'
    };
    const body: string = await Network.get(url, headers);
    if (body === '') {
      throw new Error('Network Error');
    }
    const parsed: Record<string, Object> = JSON.parse(body) as Record<string, Object>;
    const version: string = JmApi.safeStr(parsed, 'version');
    if (version === '') {
      throw new Error('No version code in response.');
    }
    JmApi.appVersion = version;
    await Settings.putString(SettingsKeys.JM_APP_VERSION, version);
    return version;
  }

  // ========== Request Core ==========

  private static buildHeaders(time: string, post: boolean, tokenSecret: string = ApiConstants.JM_SECRET): Record<string, string> {
    const headers: Record<string, string> = {
      'Accept': '*/*',
      'Accept-Language': 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7',
      'Origin': 'https://localhost',
      'Referer': 'https://localhost/',
      'Sec-Fetch-Dest': 'empty',
      'Sec-Fetch-Mode': 'cors',
      'Sec-Fetch-Site': 'cross-site',
      'Sec-Fetch-Storage-Access': 'active',
      'X-Requested-With': ApiConstants.JM_PACKAGE_NAME,
      'Authorization': 'Bearer',
      'token': JmApi.generateToken(time, tokenSecret),
      'tokenparam': `${time},${JmApi.appVersion}`,
      'User-Agent': ApiConstants.JM_USER_AGENT
    };
    if (post) {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    }
    return headers;
  }

  private static extractErrorMsg(body: string): string {
    try {
      const parsed: Record<string, Object> = JSON.parse(body) as Record<string, Object>;
      return JmApi.safeStr(parsed, 'errorMsg', '');
    } catch (e) {
      return '';
    }
  }

  /** 安全 JSON 解析：非 JSON / 解析失败时记录状态码、域名、时间与 body 头部，并抛出可读错误 */
  private static parseJsonOrThrow(body: string, code: number, time: string): Object {
    const trimmed: string = body.trim();
    if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
      Logger.error(TAG, `Non-JSON response: HTTP ${code}, domain=${JmApi.currentDomain}, time=${time}, ver=${JmApi.appVersion}, head=${trimmed.substring(0, 200)}`);
      throw new Error(`Server returned non-JSON (HTTP ${code}): ${trimmed.substring(0, 120)}`);
    }
    try {
      return JSON.parse(trimmed) as Object;
    } catch (e) {
      Logger.error(TAG, `JSON parse failed: HTTP ${code}, domain=${JmApi.currentDomain}, time=${time}, head=${trimmed.substring(0, 200)}`);
      throw new Error(`Invalid JSON from server (HTTP ${code}): ${trimmed.substring(0, 120)}`);
    }
  }

  private static async handleResponse(
    resp: NetworkResp,
    time: string,
    isRetry: boolean,
    retry: () => Promise<Object>
  ): Promise<Object> {
    if (resp.code === 401) {
      const errorMsg: string = JmApi.extractErrorMsg(resp.body);
      if (errorMsg === '請先登入會員' && JmApi.loggedIn && !JmApi.performingLogin && !isRetry) {
        const ok: boolean = await JmApi.reLogin();
        if (ok) {
          return await retry();
        }
      }
      throw new Error(errorMsg !== '' ? errorMsg : '請先登入會員');
    }
    if (resp.code !== 200) {
      const errorMsg: string = JmApi.extractErrorMsg(resp.body);
      throw new Error(errorMsg !== '' ? errorMsg : `HTTP ${resp.code}`);
    }
    if (resp.body === '') {
      throw new Error('Empty response');
    }
    const result: Record<string, Object> = JmApi.parseJsonOrThrow(resp.body, resp.code, time) as Record<string, Object>;
    const code: number = JmApi.safeNum(result, 'code', 200);
    if (code !== 200) {
      const msg: string = JmApi.safeStr(result, 'errorMsg', JmApi.safeStr(result, 'info', 'Unknown error'));
      throw new Error(msg);
    }
    const dataField: Object | undefined = result['data'];
    if (dataField === undefined || dataField === null) {
      throw new Error('Empty data');
    }
    if (typeof dataField === 'string') {
      const s: string = String(dataField);
      if (s.length === 0) {
        throw new Error('Empty data');
      }
      // 解密必须复用请求时的 time
      const decrypted: string = await JmApi.convertData(s, time);
      if (decrypted === '') {
        throw new Error('Decrypt failed');
      }
      return JmApi.parseJsonOrThrow(decrypted, resp.code, time);
    }
    if (Array.isArray(dataField)) {
      const arr: Object[] = dataField as Object[];
      if (arr.length === 0) {
        throw new Error('Empty data');
      }
      throw new Error('Data parsing error');
    }
    return dataField;
  }

  private static async apiGet(path: string, params: Record<string, string>, isRetry: boolean = false): Promise<Object> {
    // 登录进行中时等待（与原版 get() 一致），上限 10s 防死等
    let waitCount: number = 0;
    while (JmApi.performingLogin && waitCount < 100) {
      await new Promise<void>((resolve: () => void) => setTimeout(resolve, 100));
      waitCount++;
    }
    const time: string = String(Math.floor(Date.now() / 1000));
    const headers: Record<string, string> = JmApi.buildHeaders(time, false);
    let url: string = `${JmApi.currentDomain}${path}`;
    const paramKeys: string[] = Object.keys(params);
    const parts: string[] = [];
    for (let i = 0; i < paramKeys.length; i++) {
      const key: string = paramKeys[i];
      const value: string = params[key];
      if (value !== '') {
        parts.push(`${key}=${JmApi.encodeValue(value)}`);
      }
    }
    if (parts.length > 0) {
      url += (path.indexOf('?') !== -1 ? '&' : '?') + parts.join('&');
    }
    Logger.debug(TAG, `GET ${url} time=${time} ver=${JmApi.appVersion}`);
    const resp: NetworkResp = await Network.getWithStatus(url, headers);
    // 网络异常：仅 GET（幂等）换域名重试一次；POST 不重试，防止开关量类接口双重执行
    if (resp.code === -1) {
      if (!isRetry) {
        await JmApi.selectDomain();
        return await JmApi.apiGet(path, params, true);
      }
      throw new Error('Network Error');
    }
    return await JmApi.handleResponse(resp, time, isRetry, () => JmApi.apiGet(path, params, true));
  }

  private static async apiPost(path: string, formBody: string, isRetry: boolean = false): Promise<Object> {
    const time: string = String(Math.floor(Date.now() / 1000));
    const headers: Record<string, string> = JmApi.buildHeaders(time, true);
    const url: string = `${JmApi.currentDomain}${path}`;
    Logger.debug(TAG, `POST ${url} time=${time} ver=${JmApi.appVersion}`);
    const resp: NetworkResp = await Network.postWithStatus(url, formBody, headers);
    if (resp.code === -1) {
      // POST 不做网络错误自动重试（与原版 post() 一致）
      throw new Error('Network Error');
    }
    return await JmApi.handleResponse(resp, time, isRetry, () => JmApi.apiPost(path, formBody, true));
  }

  // ========== Browse Endpoints ==========

  /** 最新（裸数组，无 maxPage，翻到空为止） */
  static async getLatest(page: number): Promise<Comic[]> {
    const data: Object = await JmApi.apiGet('/latest', { 'page': String(page) });
    return JmApi.parseComicList(data);
  }

  /** 主页分区（/promote?page=0） */
  static async getHomePage(): Promise<JmHomeSection[]> {
    const data: Object = await JmApi.apiGet('/promote', { 'page': '0' });
    const sections: JmHomeSection[] = [];
    const arr: Object[] = Array.isArray(data) ? data as Object[] : [];
    for (let i = 0; i < arr.length; i++) {
      try {
        const rec: Record<string, Object> = arr[i] as Record<string, Object>;
        const section: JmHomeSection = new JmHomeSection();
        section.title = JmApi.safeStr(rec, 'title');
        const type: string = JmApi.safeStr(rec, 'type');
        section.id = type === 'category_id' ? JmApi.safeStr(rec, 'slug') : JmApi.safeStr(rec, 'id');
        section.comics = JmApi.parseComicList(rec['content']);
        sections.push(section);
      } catch (e) {
        continue;
      }
    }
    return sections;
  }

  /** 分区漫画分页（/promote_list） */
  static async getPromoteList(id: string, page: number): Promise<JmPagedResult> {
    const data: Record<string, Object> =
      await JmApi.apiGet('/promote_list', { 'id': id, 'page': String(page) }) as Record<string, Object>;
    const result: JmPagedResult = new JmPagedResult();
    result.comics = JmApi.parseComicList(data['list']);
    const total: number = JmApi.toInt(data['total'], result.comics.length);
    result.maxPage = result.comics.length > 0 ? Math.ceil(total / result.comics.length) : 0;
    return result;
  }

  /** 搜索（page=1 时省略 page 参数） */
  static async search(keyword: string, page: number, order: string = 'mr'): Promise<JmPagedResult> {
    let kw: string = keyword.trim();
    kw = kw.replace(/ {2}/g, ' ');
    const params: Record<string, string> = {
      'search_query': kw,
      'o': order,
      'page': page !== 1 ? String(page) : ''
    };
    const data: Record<string, Object> = await JmApi.apiGet('/search', params) as Record<string, Object>;
    const result: JmPagedResult = new JmPagedResult();
    result.comics = JmApi.parseComicList(data['content']);
    const total: number = JmApi.toInt(data['total'], result.comics.length);
    result.maxPage = result.comics.length > 0 ? Math.ceil(total / result.comics.length) : 0;
    return result;
  }

  /** 分类过滤（/categories/filter） */
  static async getCategoryComics(slug: string, order: string, page: number): Promise<JmPagedResult> {
    const params: Record<string, string> = {
      'o': order,
      'c': slug,
      'page': String(page)
    };
    const data: Record<string, Object> = await JmApi.apiGet('/categories/filter', params) as Record<string, Object>;
    const result: JmPagedResult = new JmPagedResult();
    result.comics = JmApi.parseComicList(data['content']);
    const total: number = JmApi.toInt(data['total'], result.comics.length);
    result.maxPage = result.comics.length > 0 ? Math.ceil(total / result.comics.length) : 0;
    return result;
  }

  /** 漫画详情（/album）：章节、相关推荐、点赞/收藏状态 */
  static async getComicInfo(id: string): Promise<Comic> {
    const data: Record<string, Object> = await JmApi.apiGet('/album', { 'id': id }) as Record<string, Object>;
    const comic: Comic = new Comic();
    comic.id = id;
    comic.source = 'jm';
    comic.title = JmApi.safeStr(data, 'name', '未知');
    comic.description = JmApi.safeStr(data, 'description', '');

    const authorField: Object | undefined = data['author'];
    const authors: string[] = JmApi.toStringArray(authorField);
    comic.author = authors.length > 0 ? authors.join(', ') : '未知';

    comic.likes = JmApi.toInt(data['likes'], 0);
    comic.comments = JmApi.toInt(data['comment_total'], 0);
    comic.isLiked = JmApi.isTruthy(data['liked']);
    comic.isFavorite = JmApi.isTruthy(data['is_favorite']);
    comic.coverUrl = `${JmApi.imgHost}/media/albums/${id}_3x4.jpg`;

    const tags: string[] = JmApi.toStringArray(data['tags']);
    const works: string[] = JmApi.toStringArray(data['works']);
    const actors: string[] = JmApi.toStringArray(data['actors']);
    comic.tags = tags;
    const categories: string[] = [];
    const pools: string[][] = [tags, works, actors];
    for (let p = 0; p < pools.length; p++) {
      const pool: string[] = pools[p];
      for (let i = 0; i < pool.length; i++) {
        const item: string = pool[i].trim();
        if (item.length > 0) {
          categories.push(item);
        }
      }
    }
    comic.categories = categories;

    // 章节：series 数组 [{id, name, sort}]；为空则单章
    const chapters: Chapter[] = [];
    const seriesField: Object | undefined = data['series'];
    if (seriesField !== undefined && seriesField !== null && Array.isArray(seriesField)) {
      const series: Object[] = seriesField as Object[];
      for (let i = 0; i < series.length; i++) {
        const s: Record<string, Object> = series[i] as Record<string, Object>;
        const ch: Chapter = new Chapter();
        ch.id = JmApi.safeStr(s, 'id');
        ch.comicId = id;
        ch.order = JmApi.toInt(s['sort'], i + 1);
        let name: string = JmApi.safeStr(s, 'name');
        if (name === '') {
          name = `第${ch.order}話`;
        }
        ch.title = name;
        chapters.push(ch);
      }
    }
    if (chapters.length === 0) {
      const ch: Chapter = new Chapter();
      ch.id = id;
      ch.comicId = id;
      ch.order = 1;
      ch.title = '第1話';
      chapters.push(ch);
    }
    chapters.sort((a: Chapter, b: Chapter) => a.order - b.order);
    comic.chapters = chapters;
    comic.chapterCount = chapters.length;

    // 相关推荐
    const related: Comic[] = JmApi.parseComicList(data['related_list']);
    comic.relatedComics = related;
    return comic;
  }

  /** 章节图片（/chapter）：images 为文件名数组 */
  static async getChapter(id: string): Promise<Chapter> {
    const data: Record<string, Object> = await JmApi.apiGet('/chapter', { 'id': id }) as Record<string, Object>;
    const chapter: Chapter = new Chapter();
    chapter.id = id;
    chapter.comicId = JmApi.safeStr(data, 'album_id', '');
    chapter.title = JmApi.safeStr(data, 'name', '');
    const filenames: string[] = JmApi.toStringArray(data['images']);
    const urls: string[] = [];
    for (let i = 0; i < filenames.length; i++) {
      urls.push(`${JmApi.imgHost}/media/photos/${id}/${filenames[i]}`);
    }
    chapter.imageUrls = urls;
    chapter.pages = urls.length;
    return chapter;
  }

  static fetchScrambleId(photoId: string): Promise<string> {
    const existing: Promise<string> | undefined = JmApi.scramblePromises.get(photoId);
    if (existing !== undefined) {
      return existing;
    }
    const p: Promise<string> = JmApi.doFetchScrambleId(photoId);
    JmApi.scramblePromises.set(photoId, p);
    return p;
  }

  private static async doFetchScrambleId(photoId: string): Promise<string> {
    try {
      const time: string = String(Math.floor(Date.now() / 1000));
      // /chapter_view_template 专用 APP_TOKEN_SECRET_2（JM_AUTH_KEY），用普通密钥会返回 403
      const headers: Record<string, string> = JmApi.buildHeaders(time, false, ApiConstants.JM_AUTH_KEY);
      const url: string =
        `${JmApi.currentDomain}/chapter_view_template?id=${photoId}&mode=vertical&page=0&app_img_shunt=1&express=off&v=${time}`;
      const body: string = await Network.get(url, headers);
      if (body.length > 0) {
        const m: RegExpMatchArray | null = body.match(/var scramble_id = (\d+);/);
        if (m !== null && m.length > 1) {
          return m[1];
        }
      }
      Logger.warn(TAG, `scramble_id not matched, fallback, body head: ${body.substring(0, 120)}`);
    } catch (e) {
      Logger.warn(TAG, `fetch scramble_id failed: ${Logger.describe(e)}`);
    }
    return ApiConstants.JM_SCRAMBLE_FALLBACK;
  }

  /** 热搜词（解密后 data 即字符串数组） */
  static async getHotTags(): Promise<string[]> {
    const data: Object = await JmApi.apiGet('/hot_tags', {});
    return JmApi.toStringArray(data);
  }

  /** 每周必看分类（/week） */
  static async getWeekCategories(): Promise<JmWeekCategory[]> {
    const data: Record<string, Object> = await JmApi.apiGet('/week', {}) as Record<string, Object>;
    const result: JmWeekCategory[] = [];
    const listField: Object | undefined = data['categories'];
    const list: Object[] = listField !== undefined && listField !== null && Array.isArray(listField)
      ? listField as Object[] : [];
    for (let i = 0; i < list.length; i++) {
      const rec: Record<string, Object> = list[i] as Record<string, Object>;
      const cat: JmWeekCategory = new JmWeekCategory();
      cat.id = JmApi.safeStr(rec, 'id');
      cat.label = JmApi.safeStr(rec, 'time');
      result.push(cat);
    }
    return result;
  }

  /** 每周必看漫画（/week/filter，单页）；type: ''|'hanman'|'manga'|'another' */
  static async getWeekComics(id: string, type: string): Promise<Comic[]> {
    const params: Record<string, string> = { 'id': id, 'page': '0', 'type': type };
    const data: Record<string, Object> = await JmApi.apiGet('/week/filter', params) as Record<string, Object>;
    return JmApi.parseComicList(data['list']);
  }

  // ========== Account Endpoints ==========

  /** 登录：POST /login（form）；finally 中更新图片分流 + 可选自动签到（与原版一致，失败也执行） */
  static async login(account: string, pwd: string): Promise<void> {
    const autoSelect: boolean = await Settings.getBool(SettingsKeys.JM_AUTO_SELECT_DOMAIN, true);
    if (autoSelect) {
      await JmApi.selectDomain();
    }
    JmApi.performingLogin = true;
    try {
      const data: Record<string, Object> = await JmApi.apiPost(
        '/login',
        `username=${encodeURIComponent(account)}&password=${encodeURIComponent(pwd)}`
      ) as Record<string, Object>;
      JmApi.account = account;
      JmApi.password = pwd;
      JmApi.userName = JmApi.safeStr(data, 'username');
      JmApi.userId = JmApi.safeStr(data, 'uid');
      JmApi.loggedIn = true;
      await Settings.putString(SettingsKeys.JM_ACCOUNT, account);
      await Settings.putString(SettingsKeys.JM_PASSWORD, pwd);
      await Settings.putString(SettingsKeys.JM_USER_NAME, JmApi.userName);
      await Settings.putString(SettingsKeys.JM_USER_ID, JmApi.userId);
      JmApi.notifyAccountChanged();
    } finally {
      JmApi.performingLogin = false;
      // 登录后更新图片分流（须在 performingLogin=false 之后，避免 apiGet 等待死锁）
      await JmApi.updateImgUrl(JmApi.imgLineIndex);
      // 自动签到
      const autoCheckin: boolean = await Settings.getBool(SettingsKeys.JM_AUTO_CHECKIN, false);
      if (autoCheckin) {
        try {
          const msg: string = await JmApi.dailyChk();
          Logger.info(TAG, `JM auto check-in succeed: ${msg}`);
        } catch (e) {
          Logger.warn(TAG, `JM auto check-in failed: ${Logger.describe(e)}`);
        }
      }
    }
  }

  /** 登出：清 cookie + 清账号持久化 */
  static async logout(): Promise<void> {
    try {
      Network.clearAllCookies();
    } catch (e) {
      Logger.warn(TAG, `clearAllCookies failed: ${Logger.describe(e)}`);
    }
    JmApi.account = '';
    JmApi.password = '';
    JmApi.userName = '';
    JmApi.userId = '';
    JmApi.loggedIn = false;
    await Settings.putString(SettingsKeys.JM_ACCOUNT, '');
    await Settings.putString(SettingsKeys.JM_PASSWORD, '');
    await Settings.putString(SettingsKeys.JM_USER_NAME, '');
    await Settings.putString(SettingsKeys.JM_USER_ID, '');
    JmApi.notifyAccountChanged();
  }

  /** 用持久化账号重新登录 */
  static async reLogin(): Promise<boolean> {
    if (JmApi.account === '' || JmApi.password === '') {
      return false;
    }
    try {
      await JmApi.login(JmApi.account, JmApi.password);
      return true;
    } catch (e) {
      Logger.warn(TAG, `reLogin failed: ${Logger.describe(e)}`);
      return false;
    }
  }

  /** 收藏夹列表（GET /favorite） */
  static async getFolders(): Promise<JmFolder[]> {
    const data: Record<string, Object> = await JmApi.apiGet('/favorite', {}) as Record<string, Object>;
    const folders: JmFolder[] = [];
    const listField: Object | undefined = data['folder_list'];
    const list: Object[] = listField !== undefined && listField !== null && Array.isArray(listField)
      ? listField as Object[] : [];
    for (let i = 0; i < list.length; i++) {
      const rec: Record<string, Object> = list[i] as Record<string, Object>;
      const folder: JmFolder = new JmFolder();
      folder.id = JmApi.safeStr(rec, 'FID');
      folder.name = JmApi.safeStr(rec, 'name');
      folders.push(folder);
    }
    return folders;
  }

  /** 收藏夹漫画分页（order: 0→mr 最新收藏, 1→mp 最新更新） */
  static async getFolderComicsPage(folderId: string, page: number): Promise<JmPagedResult> {
    const orderSetting: number = await Settings.getNumber(SettingsKeys.JM_FAVORITE_ORDER, 0);
    const order: string = orderSetting === 0 ? 'mr' : 'mp';
    const data: Record<string, Object> = await JmApi.apiGet('/favorite', {
      'page': String(page),
      'folder_id': folderId,
      'o': order
    }) as Record<string, Object>;
    const result: JmPagedResult = new JmPagedResult();
    result.comics = JmApi.parseComicList(data['list']);
    const total: number = JmApi.toInt(data['total'], result.comics.length);
    result.maxPage = result.comics.length > 0 ? Math.ceil(total / result.comics.length) : 0;
    return result;
  }

  /** 收藏/取消收藏；folder=null 取消，'0'=未分类，其他=指定收藏夹 */
  static async favoriteComic(id: string, folder: string | null): Promise<void> {
    if (folder !== null) {
      let res: Record<string, Object> =
        await JmApi.apiPost('/favorite', `aid=${id}&`) as Record<string, Object>;
      if (JmApi.safeStr(res, 'type') !== 'add') {
        res = await JmApi.apiPost('/favorite', `aid=${id}&`) as Record<string, Object>;
      }
      if (folder !== '0') {
        await JmApi.moveToFolder(id, folder);
      }
    } else {
      const res: Record<string, Object> =
        await JmApi.apiPost('/favorite', `aid=${id}&`) as Record<string, Object>;
      if (JmApi.safeStr(res, 'type') === 'add') {
        await JmApi.apiPost('/favorite', `aid=${id}&`);
      }
    }
  }

  static async createFolder(name: string): Promise<void> {
    await JmApi.apiPost('/favorite_folder', `type=add&folder_name=${name}&`);
  }

  static async deleteFolder(id: string): Promise<void> {
    const res: Record<string, Object> =
      await JmApi.apiPost('/favorite_folder', `type=del&folder_id=${id}&`) as Record<string, Object>;
    if (JmApi.toInt(res['code'], 200) === 400) {
      throw new Error(JmApi.safeStr(res, 'msg'));
    }
  }

  static async moveToFolder(comicId: string, folderId: string): Promise<void> {
    await JmApi.apiPost('/favorite_folder', `type=move&folder_id=${folderId}&aid=${comicId}&`);
  }

  static async likeComic(id: string): Promise<void> {
    await JmApi.apiPost('/like', `id=${id}&`);
  }

  /** 每日签到，成功返回 msg */
  static async dailyChk(): Promise<string> {
    const data: Record<string, Object> =
      await JmApi.apiGet('/daily', { 'user_id': JmApi.userId }) as Record<string, Object>;
    const dailyId: string = JmApi.safeStr(data, 'daily_id');
    if (dailyId === '') {
      throw new Error('daily_id not found');
    }
    const res: Record<string, Object> = await JmApi.apiPost(
      '/daily_chk',
      `user_id=${JmApi.userId}&daily_id=${dailyId}&`
    ) as Record<string, Object>;
    const msg: string = JmApi.safeStr(res, 'msg');
    if (msg.indexOf('今天') === 0 || msg.indexOf('Jcoin') !== -1 || msg.indexOf('EXP') !== -1) {
      return msg;
    }
    throw new Error(msg !== '' ? msg : 'Check-in failed');
  }

  /** 评论列表（/forum?mode=manhua） */
  static async getComments(id: string, page: number): Promise<JmCommentPage> {
    const data: Record<string, Object> = await JmApi.apiGet('/forum', {
      'mode': 'manhua',
      'aid': id,
      'page': String(page)
    }) as Record<string, Object>;
    const result: JmCommentPage = new JmCommentPage();
    const listField: Object | undefined = data['list'];
    const list: Object[] = listField !== undefined && listField !== null && Array.isArray(listField)
      ? listField as Object[] : [];
    for (let i = 0; i < list.length; i++) {
      const rec: Record<string, Object> = list[i] as Record<string, Object>;
      const comment: JmComment = new JmComment();
      comment.id = JmApi.safeStr(rec, 'CID');
      comment.username = JmApi.safeStr(rec, 'username');
      comment.time = JmApi.safeStr(rec, 'addtime');
      comment.content = JmApi.htmlToText(JmApi.safeStr(rec, 'content'));
      comment.avatar = JmApi.avatarUrl(JmApi.safeStr(rec, 'photo'));
      const repliesField: Object | undefined = rec['replys'];
      if (repliesField !== undefined && repliesField !== null && Array.isArray(repliesField)) {
        const replies: Object[] = repliesField as Object[];
        for (let j = 0; j < replies.length; j++) {
          const rrec: Record<string, Object> = replies[j] as Record<string, Object>;
          const reply: JmComment = new JmComment();
          reply.id = JmApi.safeStr(rrec, 'CID');
          reply.username = JmApi.safeStr(rrec, 'username');
          reply.time = JmApi.safeStr(rrec, 'addtime');
          reply.content = JmApi.htmlToText(JmApi.safeStr(rrec, 'content'));
          reply.avatar = JmApi.avatarUrl(JmApi.safeStr(rrec, 'photo'));
          comment.replies.push(reply);
        }
      }
      result.comments.push(comment);
    }
    const total: number = JmApi.toInt(data['total'], result.comments.length);
    result.maxPage = result.comments.length > 0 ? Math.max(1, Math.ceil(total / result.comments.length)) : 1;
    return result;
  }

  /** 发送评论，返回 msg */
  static async postComment(aid: string, content: string): Promise<string> {
    const data: Record<string, Object> = await JmApi.apiPost(
      '/comment',
      `comment=${encodeURIComponent(content)}&status=undefined&aid=${aid}&`
    ) as Record<string, Object>;
    return JmApi.safeStr(data, 'msg');
  }

  // ========== Parsing ==========

  private static parseComicBrief(item: Record<string, Object>): Comic {
    const comic: Comic = new Comic();
    comic.id = JmApi.safeStr(item, 'id');
    comic.title = JmApi.safeStr(item, 'name');
    comic.author = JmApi.safeStr(item, 'author');
    comic.description = JmApi.safeStr(item, 'description');
    comic.source = 'jm';
    const tags: string[] = [];
    const catField: Object | undefined = item['category'];
    if (catField !== undefined && catField !== null) {
      const cat: Record<string, Object> = catField as Record<string, Object>;
      const t: string = JmApi.safeStr(cat, 'title');
      if (t !== '') {
        tags.push(t);
      }
    }
    const subField: Object | undefined = item['category_sub'];
    if (subField !== undefined && subField !== null) {
      const sub: Record<string, Object> = subField as Record<string, Object>;
      const t: string = JmApi.safeStr(sub, 'title');
      if (t !== '') {
        tags.push(t);
      }
    }
    comic.tags = tags;
    comic.categories = tags;
    comic.coverUrl = `${JmApi.imgHost}/media/albums/${comic.id}_3x4.jpg`;
    return comic;
  }

  private static parseComicList(field: Object | undefined): Comic[] {
    const result: Comic[] = [];
    if (field !== undefined && field !== null && Array.isArray(field)) {
      const arr: Object[] = field as Object[];
      for (let i = 0; i < arr.length; i++) {
        try {
          result.push(JmApi.parseComicBrief(arr[i] as Record<string, Object>));
        } catch (e) {
          continue;
        }
      }
    }
    return result;
  }

  // ========== Crypto ==========

  /**
   * 对齐 jm_toolkit.py JmCryptoTool.token_and_tokenparam：token = md5Hex(ts + secret)
   * 普通接口用 APP_TOKEN_SECRET（JM_SECRET）；/chapter_view_template 用 APP_TOKEN_SECRET_2（JM_AUTH_KEY）
   */
  private static generateToken(time: string, secret: string = ApiConstants.JM_SECRET): string {
    return JmApi.md5Hex(`${time}${secret}`);
  }

  static md5Hex(input: string): string {
    const bytes: number[] = [];
    for (let i = 0; i < input.length; i++) {
      bytes.push(input.charCodeAt(i) & 0xFF);
    }
    const msgLen: number = bytes.length;
    bytes.push(0x80);
    while (bytes.length % 64 !== 56) {
      bytes.push(0x00);
    }
    const bitLen: number = msgLen * 8;
    bytes.push(bitLen & 0xFF, (bitLen >> 8) & 0xFF, (bitLen >> 16) & 0xFF, (bitLen >> 24) & 0xFF);
    bytes.push(0, 0, 0, 0);

    let a0: number = 0x67452301;
    let b0: number = 0xEFCDAB89;
    let c0: number = 0x98BADCFE;
    let d0: number = 0x10325476;

    const S: number[] = [
      7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
      5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
      4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
      6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21
    ];

    const K: number[] = [];
    for (let t = 0; t < 64; t++) {
      K.push(Math.floor(Math.abs(Math.sin(t + 1)) * 4294967296));
    }

    for (let i = 0; i < bytes.length; i += 64) {
      const M: number[] = [];
      for (let j = 0; j < 16; j++) {
        M[j] = (bytes[i + j * 4]) | (bytes[i + j * 4 + 1] << 8) |
          (bytes[i + j * 4 + 2] << 16) | (bytes[i + j * 4 + 3] << 24);
      }

      let A: number = a0;
      let B: number = b0;
      let C: number = c0;
      let D: number = d0;

      for (let t = 0; t < 64; t++) {
        let F: number = 0;
        let g: number = 0;
        if (t < 16) {
          F = (B & C) | ((~B) & D);
          g = t;
        } else if (t < 32) {
          F = (D & B) | ((~D) & C);
          g = (5 * t + 1) % 16;
        } else if (t < 48) {
          F = B ^ C ^ D;
          g = (3 * t + 5) % 16;
        } else {
          F = C ^ (B | (~D));
          g = (7 * t) % 16;
        }
        const temp: number = (B + (((A + F + K[t] + M[g]) << S[t]) |
          (((A + F + K[t] + M[g]) >>> (32 - S[t]))))) | 0;
        A = D;
        D = C;
        C = B;
        B = temp;
      }

      a0 = (a0 + A) | 0;
      b0 = (b0 + B) | 0;
      c0 = (c0 + C) | 0;
      d0 = (d0 + D) | 0;
    }

    const words: number[] = [a0, b0, c0, d0];
    let hex: string = '';
    for (let i = 0; i < 4; i++) {
      const w: number = words[i];
      hex += JmApi.hexByte(w & 0xFF);
      hex += JmApi.hexByte((w >> 8) & 0xFF);
      hex += JmApi.hexByte((w >> 16) & 0xFF);
      hex += JmApi.hexByte((w >> 24) & 0xFF);
    }
    return hex;
  }

  private static hexByte(b: number): string {
    const h: string = (b & 0xFF).toString(16);
    return h.length < 2 ? '0' + h : h;
  }

  private static bytesToString(bytes: number[]): string {
    let result: string = '';
    for (let i = 0; i < bytes.length; i++) {
      result += String.fromCharCode(bytes[i]);
    }
    return result;
  }

  private static strToBytes(str: string): number[] {
    const bytes: number[] = [];
    for (let i = 0; i < str.length; i++) {
      bytes.push(str.charCodeAt(i) & 0xFF);
    }
    return bytes;
  }

  private static base64Decode(input: string): Uint8Array {
    const chars: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    const bytes: number[] = [];
    let buffer: number = 0;
    let bits: number = 0;
    for (let i = 0; i < input.length; i++) {
      const c: string = input.charAt(i);
      if (c === '=' || c === '\n' || c === '\r') {
        continue;
      }
      const val: number = chars.indexOf(c);
      if (val === -1) {
        continue;
      }
      buffer = (buffer << 6) | val;
      bits += 6;
      if (bits >= 8) {
        bits -= 8;
        bytes.push((buffer >> bits) & 0xFF);
      }
    }
    return new Uint8Array(bytes);
  }

  /**
   * 对齐 jm_toolkit.py JmCryptoTool.decode_resp_data：
   * base64 解码 → AES256-ECB 解密（key = md5Hex(ts + secret) 的 UTF-8 字节）→ 去尾部 padding → UTF-8 解码
   * @param base64Data 服务端返回的 base64 密文
   * @param ts 请求时间戳（域名场景传 ''，API 场景必须与请求时一致）
   * @param secret jm_config.py 密钥（APP_DATA_SECRET / API_DOMAIN_SERVER_SECRET）
   */
  private static async decodeRespData(base64Data: string, ts: string, secret: string): Promise<string> {
    try {
      const decoded: Uint8Array = JmApi.base64Decode(base64Data);
      const keyBytes: number[] = JmApi.strToBytes(JmApi.md5Hex(`${ts}${secret}`));
      const keyData: Uint8Array = new Uint8Array(keyBytes);

      // @SuppressWarnings syscap
      const generator: cryptoFramework.SymKeyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
      const keyBlob: cryptoFramework.DataBlob = { data: keyData };
      // @SuppressWarnings syscap
      const symKey: cryptoFramework.SymKey = await generator.convertKey(keyBlob);

      // @SuppressWarnings syscap
      const cipher: cryptoFramework.Cipher = cryptoFramework.createCipher('AES256|ECB|NoPadding');
      // @SuppressWarnings syscap
      await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, symKey, null);

      const input: cryptoFramework.DataBlob = { data: decoded };
      // @SuppressWarnings syscap
      const output: cryptoFramework.DataBlob = await cipher.doFinal(input);
      // 对齐 Python data_aes[:-data_aes[-1]]：尾字节为 padding 长度 N，截掉尾部 N 字节
      const raw: Uint8Array = output.data;
      let body: Uint8Array = raw;
      if (raw.length > 0) {
        const padLen: number = raw[raw.length - 1];
        if (padLen > 0 && padLen <= raw.length) {
          body = raw.subarray(0, raw.length - padLen);
        }
      }
      // 明文为 UTF-8 编码的 JSON（原版 Utf8Decoder().convert），逐字节转字符会把中文变乱码
      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8');
      return decoder.decodeToString(body);
    } catch (e) {
      Logger.error(TAG, `decodeRespData failed: ${Logger.describe(e)}`);
      return '';
    }
  }

  /** 域名密文解密：ts = ''，key = md5Hex(API_DOMAIN_SERVER_SECRET)（对齐 req_api_domain_server） */
  private static async aesEcbDecrypt(base64Data: string, secretStr: string): Promise<string> {
    return JmApi.decodeRespData(base64Data, '', secretStr);
  }

  /** API data 解密：key = md5Hex(time + JM_SECRET)，time 必须与请求一致 */
  private static async convertData(input: string, time: string): Promise<string> {
    return JmApi.decodeRespData(input, time, ApiConstants.JM_SECRET);
  }
}
