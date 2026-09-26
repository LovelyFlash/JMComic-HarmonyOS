// common/Network.ets - HTTP 封装
import http from '@ohos.net.http';
import { Logger } from './Logger';

const TAG = 'Network';

class CacheEntry {
  data: string = '';
  time: number = 0;
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
        Logger.error(TAG, `GET ${url} failed: ${response.responseCode}`);
        return '';
      }
    } catch (e) {
      Logger.error(TAG, `GET ${url} exception: ${String(e)}`);
      return '';
    } finally {
      httpRequest.destroy();
    }
  }

  static async post(url: string, body: string, headers?: Record<string, string>): Promise<string> {
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
        connectTimeout: 15000,
        readTimeout: 30000
      });
      if (response.responseCode === 200) {
        return response.result as string;
      } else {
        Logger.error(TAG, `POST ${url} failed: ${response.responseCode}`);
        return '';
      }
    } catch (e) {
      Logger.error(TAG, `POST ${url} exception: ${String(e)}`);
      return '';
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
