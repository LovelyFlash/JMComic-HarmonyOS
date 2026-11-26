// data/api/JmCrypto.ets - JM API 加解密（md5/token/base64/AES）
import cryptoFramework from '@ohos.security.cryptoFramework';
import { util } from '@kit.ArkTS';
import { ApiConstants } from '../../common/Constants';
import { Logger } from '../../common/Logger';

const TAG = 'JmCrypto';

export class JmCrypto {
  static generateToken(time: string, secret: string = ApiConstants.JM_SECRET): string {
    return JmCrypto.md5Hex(`${time}${secret}`);
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
      hex += JmCrypto.hexByte(w & 0xFF);
      hex += JmCrypto.hexByte((w >> 8) & 0xFF);
      hex += JmCrypto.hexByte((w >> 16) & 0xFF);
      hex += JmCrypto.hexByte((w >> 24) & 0xFF);
    }
    return hex;
  }

  private static hexByte(b: number): string {
    const h: string = (b & 0xFF).toString(16);
    return h.length < 2 ? '0' + h : h;
  }

  static bytesToString(bytes: number[]): string {
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
      const decoded: Uint8Array = JmCrypto.base64Decode(base64Data);
      const keyBytes: number[] = JmCrypto.strToBytes(JmCrypto.md5Hex(`${ts}${secret}`));
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
  static async aesEcbDecrypt(base64Data: string, secretStr: string): Promise<string> {
    return JmCrypto.decodeRespData(base64Data, '', secretStr);
  }

  /** API data 解密：key = md5Hex(time + JM_SECRET)，time 必须与请求一致 */
  static async convertData(input: string, time: string): Promise<string> {
    return JmCrypto.decodeRespData(input, time, ApiConstants.JM_SECRET);
  }
}
