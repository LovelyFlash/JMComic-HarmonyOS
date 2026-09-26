// data/api/PicacgApi.ets - PicaComic (哔咔) API 客户端
import { Network } from '../../common/Network';
import { Logger } from '../../common/Logger';
import { Comic } from '../model/Comic';
import { User } from '../model/User';
import { ApiConstants } from '../../common/Constants';

const TAG = 'PicacgApi';

interface PicaResponse {
  code: number;
  message: string;
  data: Record<string, object>;
  limit: number;
  total: number;
  page: number;
  page_count: number;
}

interface PicaAvatar {
  fileServer: string;
  path: string;
}

interface PicaTokenData {
  token: string;
  expiredTime: string;
}

interface PicaThumb {
  fileServer: string;
  path: string;
}

interface PicaEpsCount {
  total: number;
}

export class PicacgApi {
  private static readonly API_BASE: string = ApiConstants.PICACG_API;
  private static readonly API_KEY: string = ApiConstants.PICACG_API_KEY;
  private static readonly SIGN_KEY: string = ApiConstants.PICACG_SIGN_KEY;
  private static readonly VERSION: string = ApiConstants.PICACG_VERSION;
  private static readonly APP_VERSION: string = ApiConstants.PICACG_APP_VERSION;
  private static readonly BUILD_VERSION: string = ApiConstants.PICACG_BUILD_VERSION;
  private static readonly APP_CHANNEL: string = ApiConstants.PICACG_APP_CHANNEL;
  private static readonly APP_PLATFORM: string = ApiConstants.PICACG_APP_PLATFORM;

  private static authToken: string = '';

  static setToken(token: string): void {
    PicacgApi.authToken = token;
  }

  static getToken(): string {
    return PicacgApi.authToken;
  }

  static async login(email: string, password: string): Promise<PicaResponse> {
    const body: string = JSON.stringify({ email: email, password: password });
    const apiPath: string = '/auth/sign-in';
    const headers: Record<string, string> = PicacgApi.buildHeaders('POST', apiPath, body);
    const url: string = `${PicacgApi.API_BASE}${apiPath}`;
    Logger.info(TAG, 'login');
    const resp: string = await Network.post(url, body, headers);
    const result: PicaResponse = JSON.parse(resp) as PicaResponse;
    if (result.code === 200) {
      const tokenData: PicaTokenData = result.data['token'] as PicaTokenData;
      PicacgApi.authToken = tokenData.token;
    }
    return result;
  }

  static async getProfile(): Promise<User> {
    const apiPath: string = '/user/profile';
    const url: string = `${PicacgApi.API_BASE}${apiPath}`;
    const headers: Record<string, string> = PicacgApi.buildHeaders('GET', apiPath);
    Logger.info(TAG, 'getProfile');
    const resp: string = await Network.get(url, headers);
    const result: PicaResponse = JSON.parse(resp) as PicaResponse;
    const data: Record<string, object> = result.data;
    const user: User = new User();
    user.id = (data['id'] as string) ?? '';
    user.name = (data['name'] as string) ?? '';
    const avatar: PicaAvatar = data['avatar'] as PicaAvatar;
    user.avatar = `${avatar.fileServer}/static/${avatar.path}`;
    user.email = (data['email'] as string) ?? '';
    user.isPicaPro = (data['isPicaPro'] as boolean) ?? false;
    user.slogan = (data['slogan'] as string) ?? '';
    const exp: number = (data['exp'] as number) ?? 0;
    user.exp = exp;
    user.level = PicacgApi.calcLevel(exp);
    return user;
  }

  static async search(keyword: string, page: number): Promise<PicaResponse> {
    const apiPath: string = `/comics/advanced?page=${page}&kw=${encodeURIComponent(keyword)}&sort=dd`;
    const url: string = `${PicacgApi.API_BASE}${apiPath}`;
    const headers: Record<string, string> = PicacgApi.buildHeaders('GET', apiPath);
    Logger.info(TAG, `search: keyword=${keyword}, page=${page}`);
    const resp: string = await Network.get(url, headers);
    return JSON.parse(resp) as PicaResponse;
  }

  static async getComicInfo(id: string): Promise<Comic> {
    const apiPath: string = `/comics/${id}`;
    const url: string = `${PicacgApi.API_BASE}${apiPath}`;
    const headers: Record<string, string> = PicacgApi.buildHeaders('GET', apiPath);
    Logger.info(TAG, `getComicInfo: id=${id}`);
    const resp: string = await Network.get(url, headers);
    const result: PicaResponse = JSON.parse(resp) as PicaResponse;
    const data: Record<string, object> = result.data;
    const comicObj: Record<string, object> = data['comic'] as Record<string, object>;
    return PicacgApi.parseComic(comicObj);
  }

  static async getEps(id: string): Promise<PicaResponse> {
    const apiPath: string = `/comics/${id}/eps?page=1`;
    const url: string = `${PicacgApi.API_BASE}${apiPath}`;
    const headers: Record<string, string> = PicacgApi.buildHeaders('GET', apiPath);
    Logger.info(TAG, `getEps: id=${id}`);
    const resp: string = await Network.get(url, headers);
    return JSON.parse(resp) as PicaResponse;
  }

  static async getImages(comicId: string, epOrder: number, page: number): Promise<PicaResponse> {
    const apiPath: string = `/comics/${comicId}/order/${epOrder}/pages?page=${page}`;
    const url: string = `${PicacgApi.API_BASE}${apiPath}`;
    const headers: Record<string, string> = PicacgApi.buildHeaders('GET', apiPath);
    Logger.info(TAG, `getImages: comicId=${comicId}, ep=${epOrder}, page=${page}`);
    const resp: string = await Network.get(url, headers);
    return JSON.parse(resp) as PicaResponse;
  }

  private static buildHeaders(method: string, apiPath: string, body: string = ''): Record<string, string> {
    const timestamp: string = String(Math.floor(Date.now() / 1000));
    const nonce: string = PicacgApi.generateNonce();
    const raw: string = `${timestamp}${PicacgApi.SIGN_KEY}${method}${apiPath}${body}${nonce}`;
    const signature: string = PicacgApi.hmacSha256Hex(raw);
    const headers: Record<string, string> = {
      'api-key': PicacgApi.API_KEY,
      'accept': 'application/vnd.picacomic.com.v1+json',
      'app-channel': PicacgApi.APP_CHANNEL,
      'app-time': timestamp,
      'app-version': PicacgApi.APP_VERSION,
      'app-uuid': 'picture-undefined',
      'app-platform': PicacgApi.APP_PLATFORM,
      'app-build-version': PicacgApi.BUILD_VERSION,
      'Content-Type': 'application/json; charset=UTF-8',
      'User-Agent': 'okhttp/3.8.1',
      'time': timestamp,
      'nonce': nonce,
      'signature': signature
    };
    if (PicacgApi.authToken !== '') {
      headers['authorization'] = PicacgApi.authToken;
    }
    return headers;
  }

  private static generateNonce(): string {
    const chars: string = 'abcdef0123456789';
    let result: string = '';
    for (let i: number = 0; i < 32; i++) {
      const idx: number = Math.floor(Math.random() * chars.length);
      result = result + chars.charAt(idx);
    }
    return result;
  }

  private static hmacSha256Hex(message: string): string {
    const encoder: TextEncoder = new TextEncoder();
    const keyBytes: Uint8Array = encoder.encode(PicacgApi.SIGN_KEY);
    const msgBytes: Uint8Array = encoder.encode(message);

    const blockSize: number = 64;
    const keyArr: number[] = [];
    for (let i: number = 0; i < keyBytes.length; i++) {
      keyArr.push(keyBytes[i]);
    }
    while (keyArr.length < blockSize) {
      keyArr.push(0x00);
    }

    const ipadArr: number[] = [];
    const opadArr: number[] = [];
    for (let i: number = 0; i < blockSize; i++) {
      ipadArr.push(keyArr[i] ^ 0x36);
      opadArr.push(keyArr[i] ^ 0x5C);
    }

    const ipadMsg: number[] = ipadArr;
    for (let i: number = 0; i < msgBytes.length; i++) {
      ipadMsg.push(msgBytes[i]);
    }
    const innerHash: number[] = PicacgApi.sha256Bytes(ipadMsg);
    const opadInner: number[] = [];
    for (let i: number = 0; i < opadArr.length; i++) {
      opadInner.push(opadArr[i]);
    }
    for (let i: number = 0; i < innerHash.length; i++) {
      opadInner.push(innerHash[i]);
    }
    const finalHash: number[] = PicacgApi.sha256Bytes(opadInner);

    let hex: string = '';
    for (let i: number = 0; i < finalHash.length; i++) {
      const h: string = (finalHash[i] < 16 ? '0' : '') + finalHash[i].toString(16);
      hex = hex + h;
    }
    return hex;
  }

  private static sha256Bytes(data: number[]): number[] {
    const K: number[] = [
      0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
      0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
      0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
      0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
      0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
      0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
      0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
      0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
    ];
    let h0: number = 0x6a09e667;
    let h1: number = 0xbb67ae85;
    let h2: number = 0x3c6ef372;
    let h3: number = 0xa54ff53a;
    let h4: number = 0x510e527f;
    let h5: number = 0x9b05688c;
    let h6: number = 0x1f83d9ab;
    let h7: number = 0x5be0cd19;

    const msgLen: number = data.length;
    const bitLen: number = msgLen * 8;
    data.push(0x80);
    while ((data.length % 64) !== 56) {
      data.push(0x00);
    }
    data.push(0, 0, 0, 0);
    data.push((bitLen >> 24) & 0xFF, (bitLen >> 16) & 0xFF, (bitLen >> 8) & 0xFF, bitLen & 0xFF);

    for (let i: number = 0; i < data.length; i += 64) {
      const W: number[] = new Array<number>(64);
      for (let t: number = 0; t < 16; t++) {
        W[t] = (((data[i + t * 4] << 24) | (data[i + t * 4 + 1] << 16) | (data[i + t * 4 + 2] << 8) | data[i + t * 4 + 3]) >>> 0);
      }
      for (let t: number = 16; t < 64; t++) {
        const s0Val: number = W[t - 15];
        const s0: number = (((s0Val >>> 7) | (s0Val << 25)) ^ ((s0Val >>> 18) | (s0Val << 14)) ^ (s0Val >>> 3)) >>> 0;
        const s1Val: number = W[t - 2];
        const s1: number = (((s1Val >>> 17) | (s1Val << 15)) ^ ((s1Val >>> 19) | (s1Val << 13)) ^ (s1Val >>> 10)) >>> 0;
        W[t] = ((W[t - 16] + s0 + W[t - 7] + s1) >>> 0);
      }

      let a: number = h0;
      let b: number = h1;
      let c: number = h2;
      let d: number = h3;
      let e: number = h4;
      let f: number = h5;
      let g: number = h6;
      let h: number = h7;

      for (let t: number = 0; t < 64; t++) {
        const S1: number = (((e >>> 6) | (e << 26)) ^ ((e >>> 11) | (e << 21)) ^ ((e >>> 25) | (e << 7))) >>> 0;
        const ch: number = ((e & f) ^ ((~e) & g)) >>> 0;
        const temp1: number = ((h + S1 + ch + K[t] + W[t]) >>> 0);
        const S0: number = (((a >>> 2) | (a << 30)) ^ ((a >>> 13) | (a << 19)) ^ ((a >>> 22) | (a << 10))) >>> 0;
        const maj: number = ((a & b) ^ (a & c) ^ (b & c)) >>> 0;
        const temp2: number = ((S0 + maj) >>> 0);

        h = g;
        g = f;
        f = e;
        e = ((d + temp1) >>> 0);
        d = c;
        c = b;
        b = a;
        a = ((temp1 + temp2) >>> 0);
      }

      h0 = ((h0 + a) >>> 0);
      h1 = ((h1 + b) >>> 0);
      h2 = ((h2 + c) >>> 0);
      h3 = ((h3 + d) >>> 0);
      h4 = ((h4 + e) >>> 0);
      h5 = ((h5 + f) >>> 0);
      h6 = ((h6 + g) >>> 0);
      h7 = ((h7 + h) >>> 0);
    }

    const result: number[] = [];
    result.push((h0 >>> 24) & 0xFF, (h0 >>> 16) & 0xFF, (h0 >>> 8) & 0xFF, h0 & 0xFF);
    result.push((h1 >>> 24) & 0xFF, (h1 >>> 16) & 0xFF, (h1 >>> 8) & 0xFF, h1 & 0xFF);
    result.push((h2 >>> 24) & 0xFF, (h2 >>> 16) & 0xFF, (h2 >>> 8) & 0xFF, h2 & 0xFF);
    result.push((h3 >>> 24) & 0xFF, (h3 >>> 16) & 0xFF, (h3 >>> 8) & 0xFF, h3 & 0xFF);
    result.push((h4 >>> 24) & 0xFF, (h4 >>> 16) & 0xFF, (h4 >>> 8) & 0xFF, h4 & 0xFF);
    result.push((h5 >>> 24) & 0xFF, (h5 >>> 16) & 0xFF, (h5 >>> 8) & 0xFF, h5 & 0xFF);
    result.push((h6 >>> 24) & 0xFF, (h6 >>> 16) & 0xFF, (h6 >>> 8) & 0xFF, h6 & 0xFF);
    result.push((h7 >>> 24) & 0xFF, (h7 >>> 16) & 0xFF, (h7 >>> 8) & 0xFF, h7 & 0xFF);
    return result;
  }

  private static parseComic(obj: Record<string, object>): Comic {
    const comic: Comic = new Comic();
    comic.id = (obj['_id'] as string) ?? '';
    comic.title = (obj['title'] as string) ?? '';
    comic.author = (obj['author'] as string) ?? '';
    const categories: string[] = obj['categories'] as string[];
    if (categories !== undefined) {
      comic.categories = categories;
    }
    comic.description = (obj['description'] as string) ?? '';
    comic.likes = (obj['totalLikes'] as number) ?? 0;
    comic.comments = (obj['totalComments'] as number) ?? 0;
    comic.isFavorite = (obj['isFavorite'] as boolean) ?? false;
    comic.isLiked = (obj['isLiked'] as boolean) ?? false;
    const thumb: PicaThumb = obj['thumb'] as PicaThumb;
    if (thumb !== undefined) {
      comic.coverUrl = `${thumb.fileServer}/static/${thumb.path}`;
    }
    const epsCount: PicaEpsCount = obj['epsCount'] as PicaEpsCount;
    if (epsCount !== undefined) {
      comic.chaptersCount = epsCount.total ?? 0;
    }
    comic.source = 'picacg';
    return comic;
  }

  private static calcLevel(exp: number): number {
    if (exp < 500) {
      return 1;
    }
    if (exp < 1500) {
      return 2;
    }
    if (exp < 5000) {
      return 3;
    }
    if (exp < 10000) {
      return 4;
    }
    if (exp < 30000) {
      return 5;
    }
    if (exp < 100000) {
      return 6;
    }
    if (exp < 500000) {
      return 7;
    }
    return 8;
  }
}
