// common/Network.ets - HTTP 封装
import http from '@ohos.net.http';
import { request } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import { common } from '@kit.AbilityKit';
import { Logger } from './Logger';

const TAG = 'Network';

class CacheEntry {
  data: string = '';
  time: number = 0;
}

/** 带状态码的响应（401 等非 200 也能拿到 body） */
export class NetworkResp {
  code: number = -1;
  body: string = '';
  constructor(code: number, body: string) {
    this.code = code;
    this.body = body;
  }
}

export class Network {
  private static cookies: Map<string, string> = new Map();
  private static cache: Map<string, CacheEntry> = new Map();
  private static readonly CACHE_EXPIRY: number = 5 * 60 * 1000;

  static setCookie(host: string, cookie: string): void {
    Network.cookies.set(host, cookie);
  }

  static getCookie(host: string): string {
    const val = Network.cookies.get(host);
    return val !== undefined ? val : '';
  }

  /** 清除指定 host 的 cookie（登出用） */
  static clearHostCookies(host: string): void {
    Network.cookies.delete(host);
  }

  /** 清除全部 cookie */
  static clearAllCookies(): void {
    Network.cookies.clear();
  }

  /** 从响应头捕获 Set-Cookie 并按 host 合并（值可能是 string 或 string[]） */
  private static captureCookies(host: string, headerObj: Object): void {
    if (host.length === 0) {
      return;
    }
    const headers = headerObj as Record<string, Object>;
    const keys: string[] = ['set-cookie', 'Set-Cookie', 'SET-COOKIE'];
    let raw: Object | undefined = undefined;
    for (let i = 0; i < keys.length; i++) {
      const v: Object | undefined = headers[keys[i]];
      if (v !== undefined && v !== null) {
        raw = v;
        break;
      }
    }
    if (raw === undefined || raw === null) {
      return;
    }
    const parts: string[] = [];
    if (Array.isArray(raw)) {
      const arr: Object[] = raw as Object[];
      for (let i = 0; i < arr.length; i++) {
        parts.push(String(arr[i]));
      }
    } else {
      parts.push(String(raw));
    }
    // 合并 name=value 对
    const pairs: Map<string, string> = new Map();
    const existing: string = Network.cookies.get(host) ?? '';
    if (existing.length > 0) {
      const items: string[] = existing.split(';');
      for (let i = 0; i < items.length; i++) {
        const seg: string = items[i].trim();
        const idx: number = seg.indexOf('=');
        if (idx > 0) {
          pairs.set(seg.substring(0, idx), seg.substring(idx + 1));
        }
      }
    }
    for (let i = 0; i < parts.length; i++) {
      const seg: string = parts[i].split(';')[0].trim();
      const idx: number = seg.indexOf('=');
      if (idx > 0) {
        pairs.set(seg.substring(0, idx), seg.substring(idx + 1));
      }
    }
    const merged: string[] = [];
    pairs.forEach((value: string, key: string) => {
      merged.push(`${key}=${value}`);
    });
    if (merged.length > 0) {
      Network.cookies.set(host, merged.join('; '));
      Logger.debug(TAG, `Captured cookies for ${host}: ${merged.length} pairs`);
    }
  }

  /** 大小写不敏感读取响应头，缺失返回 '' */
  private static headerOf(headerObj: Object, key: string): string {
    try {
      const headers = headerObj as Record<string, Object>;
      const target: string = key.toLowerCase();
      const keys: string[] = Object.keys(headers);
      for (let i = 0; i < keys.length; i++) {
        if (keys[i].toLowerCase() === target) {
          return String(headers[keys[i]]);
        }
      }
    } catch (e) {
      return '';
    }
    return '';
  }

  /** 响应摘要日志：状态码 + Content-Type + body 头部；非 200 或非 JSON 升为 warn 便于过滤 */
  private static logResp(method: string, url: string, code: number, headerObj: Object, body: string): void {
    const ct: string = Network.headerOf(headerObj, 'content-type');
    const head: string = body.length > 200 ? `${body.substring(0, 200)}...` : body;
    const trimmed: string = body.trim();
    const looksJson: boolean = trimmed.startsWith('{') || trimmed.startsWith('[');
    if (code !== 200 || !looksJson) {
      Logger.warn(TAG, `${method} ${url} -> ${code}, ct=${ct}, head=${head}`);
    } else {
      Logger.debug(TAG, `${method} ${url} -> ${code}, ct=${ct}, bytes=${body.length}`);
    }
  }

  static async get(url: string, headers?: Record<string, string>, useCache: boolean = false): Promise<string> {
    if (useCache) {
      const cached = Network.cache.get(url);
      if (cached !== undefined && (Date.now() - cached.time) < Network.CACHE_EXPIRY) {
        return cached.data;
      }
    }
    const httpRequest = http.createHttp();
    try {
      const requestHeaders: Record<string, string> = headers ?? {};
      const host = Network.extractHost(url);
      const cookie = Network.getCookie(host);
      if (cookie !== '') {
        requestHeaders['Cookie'] = cookie;
      }
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: requestHeaders,
        connectTimeout: 15000,
        readTimeout: 30000
      });
      Network.captureCookies(host, response.header);
      if (response.responseCode === 200) {
        const data = response.result as string;
        if (useCache) {
          const entry = new CacheEntry();
          entry.data = data;
          entry.time = Date.now();
          Network.cache.set(url, entry);
        }
        return data;
      } else {
        let failHead: string = '';
        try {
          failHead = String(response.result);
        } catch (e) {
          failHead = '';
        }
        Logger.error(TAG, `GET ${url} failed: ${response.responseCode}, ct=${Network.headerOf(response.header, 'content-type')}, head=${failHead.substring(0, 200)}`);
        return '';
      }
    } catch (e) {
      Logger.error(TAG, `GET ${url} exception: ${Logger.describe(e)}`);
      return '';
    } finally {
      httpRequest.destroy();
    }
  }

  /** GET，任意状态码都返回 {code, body}（body 解析为 string，失败为 ''） */
  static async getWithStatus(url: string, headers?: Record<string, string>): Promise<NetworkResp> {
    const httpRequest = http.createHttp();
    try {
      const requestHeaders: Record<string, string> = headers ?? {};
      const host = Network.extractHost(url);
      const cookie = Network.getCookie(host);
      if (cookie !== '') {
        requestHeaders['Cookie'] = cookie;
      }
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: requestHeaders,
        connectTimeout: 15000,
        readTimeout: 30000
      });
      Network.captureCookies(host, response.header);
      let body: string = '';
      try {
        body = response.result as string;
      } catch (e) {
        body = '';
      }
      Network.logResp('GET', url, response.responseCode, response.header, body);
      return new NetworkResp(response.responseCode, body);
    } catch (e) {
      Logger.error(TAG, `GET ${url} exception: ${Logger.describe(e)}`);
      return new NetworkResp(-1, '');
    } finally {
      httpRequest.destroy();
    }
  }

  /** GET 二进制数据（JM 图片分片重组用），失败返回 null */
  static async getBytes(url: string, headers?: Record<string, string>): Promise<Uint8Array | null> {
    const httpRequest = http.createHttp();
    try {
      const requestHeaders: Record<string, string> = headers ?? {};
      const host = Network.extractHost(url);
      const cookie = Network.getCookie(host);
      if (cookie !== '') {
        requestHeaders['Cookie'] = cookie;
      }
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        header: requestHeaders,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 15000,
        readTimeout: 30000
      });
      Network.captureCookies(host, response.header);
      if (response.responseCode === 200) {
        return new Uint8Array(response.result as ArrayBuffer);
      }
      Logger.error(TAG, `GET bytes ${url} failed: ${response.responseCode}`);
      return null;
    } catch (e) {
      Logger.error(TAG, `GET bytes ${url} exception: ${Logger.describe(e)}`);
      return null;
    } finally {
      httpRequest.destroy();
    }
  }

  /** 通过系统下载服务取二进制（http 栈被拒时的兜底，另一网络栈），失败返回 null */
  static async getBytesViaDownload(url: string, headers: Record<string, string>,
    ctx: common.Context): Promise<Uint8Array | null> {
    const fileName: string = `jm_${Date.now()}_${Math.floor(Math.random() * 100000)}.img`;
    const filePath: string = `${ctx.cacheDir}/${fileName}`;
    let task: request.DownloadTask | null = null;
    try {
      task = await request.downloadFile(ctx, {
        url: url,
        header: headers,
        filePath: filePath,
        enableMetered: true,
        enableRoaming: true
      });
    } catch (e) {
      Logger.error(TAG, `downloadFile init failed: ${Logger.describe(e)}`);
      return null;
    }
    return await new Promise<Uint8Array | null>((resolve: (value: Uint8Array | null) => void) => {
      task!.on('complete', () => {
        try {
          const stat: fs.Stat = fs.statSync(filePath);
          const buf: ArrayBuffer = new ArrayBuffer(stat.size);
          const file: fs.File = fs.openSync(filePath, fs.OpenMode.READ_ONLY);
          fs.readSync(file.fd, buf);
          fs.closeSync(file);
          try {
            fs.unlinkSync(filePath);
          } catch (e) {
            Logger.debug(TAG, `unlink temp file failed: ${Logger.describe(e)}`);
          }
          resolve(new Uint8Array(buf));
        } catch (e) {
          Logger.error(TAG, `read downloaded file failed: ${Logger.describe(e)}`);
          try {
            fs.unlinkSync(filePath);
          } catch (e2) {
            Logger.debug(TAG, `unlink temp file failed: ${String(e2)}`);
          }
          resolve(null);
        }
      });
      task!.on('fail', (err: number) => {
        Logger.error(TAG, `download task fail: ${err}, ${url}`);
        try {
          fs.unlinkSync(filePath);
        } catch (e) {
          Logger.debug(TAG, `unlink temp file failed: ${Logger.describe(e)}`);
        }
        task!.delete().catch(() => {
        });
        resolve(null);
      });
    });
  }

  static async post(url: string, body: string, headers?: Record<string, string>): Promise<string> {
    const resp: NetworkResp = await Network.postWithStatus(url, body, headers);
    return resp.code === 200 ? resp.body : '';
  }

  /** POST，任意状态码都返回 {code, body} */
  static async postWithStatus(url: string, body: string, headers?: Record<string, string>,
    timeoutMs: number = 15000): Promise<NetworkResp> {
    const httpRequest = http.createHttp();
    try {
      const requestHeaders: Record<string, string> = headers ?? {};
      const host = Network.extractHost(url);
      const cookie = Network.getCookie(host);
      if (cookie !== '') {
        requestHeaders['Cookie'] = cookie;
      }
      if (requestHeaders['Content-Type'] === undefined) {
        requestHeaders['Content-Type'] = 'application/json';
      }
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.POST,
        header: requestHeaders,
        extraData: body,
        connectTimeout: timeoutMs,
        readTimeout: timeoutMs
      });
      Network.captureCookies(host, response.header);
      let respBody: string = '';
      try {
        respBody = response.result as string;
      } catch (e) {
        respBody = '';
      }
      Network.logResp('POST', url, response.responseCode, response.header, respBody);
      return new NetworkResp(response.responseCode, respBody);
    } catch (e) {
      Logger.error(TAG, `POST ${url} exception: ${Logger.describe(e)}`);
      return new NetworkResp(-1, '');
    } finally {
      httpRequest.destroy();
    }
  }

  static async headCheck(url: string, timeout: number = 5000): Promise<boolean> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(url, {
        method: http.RequestMethod.HEAD,
        connectTimeout: timeout,
        readTimeout: timeout
      });
      return response.responseCode >= 200 && response.responseCode < 400;
    } catch (e) {
      return false;
    } finally {
      httpRequest.destroy();
    }
  }

  static async requestWithCode(url: string, method: http.RequestMethod, headers?: Record<string, string>, body?: string): Promise<number> {
    const httpRequest = http.createHttp();
    try {
      const requestHeaders: Record<string, string> = headers ?? {};
      let response: http.HttpResponse;
      if (body !== undefined) {
        response = await httpRequest.request(url, {
          method: method,
          header: requestHeaders,
          extraData: body,
          connectTimeout: 15000,
          readTimeout: 30000
        });
      } else {
        response = await httpRequest.request(url, {
          method: method,
          header: requestHeaders,
          connectTimeout: 15000,
          readTimeout: 30000
        });
      }
      return response.responseCode;
    } catch (e) {
      return -1;
    } finally {
      httpRequest.destroy();
    }
  }

  static clearCache(): void {
    Network.cache.clear();
  }

  private static extractHost(url: string): string {
    try {
      let host = url;
      // Remove protocol
      if (host.indexOf('://') !== -1) {
        host = host.substring(host.indexOf('://') + 3);
      }
      // Remove path
      const slashIdx = host.indexOf('/');
      if (slashIdx !== -1) {
        host = host.substring(0, slashIdx);
      }
      // Remove port
      const colonIdx = host.indexOf(':');
      if (colonIdx !== -1) {
        host = host.substring(0, colonIdx);
      }
      return host;
    } catch (e) {
      return '';
    }
  }
}
