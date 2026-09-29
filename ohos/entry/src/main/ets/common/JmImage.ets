// common/JmImage.ets - JM 图片分片重组（对齐 Python 爬虫 jm_toolkit.py get_num/decode_and_save）
import { image } from '@kit.ImageKit';
import { JmApi } from '../data/api/JmApi';
import { Logger } from './Logger';
import { ApiConstants } from './Constants';

const TAG = 'JmImage';

export class JmImage {
  /** JM 图片下载请求头（对齐原版 getImgHeaders()，CDN 会拒绝无 UA 的请求） */
  static imgHeaders(): Record<string, string> {
    const headers: Record<string, string> = {
      'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
      'Accept-Language': 'zh-CN,zh;q=0.9,en-US;q=0.8,en;q=0.7',
      'Referer': 'https://localhost/',
      'Sec-Fetch-Dest': 'image',
      'Sec-Fetch-Mode': 'no-cors',
      'Sec-Fetch-Site': 'cross-site',
      'Sec-Fetch-Storage-Access': 'active',
      'User-Agent': ApiConstants.JM_USER_AGENT,
      'X-Requested-With': ApiConstants.JM_PACKAGE_NAME
    };
    return headers;
  }

  static isGif(url: string): boolean {
    const q: number = url.indexOf('?');
    const path: string = q >= 0 ? url.substring(0, q) : url;
    return path.endsWith('.gif');
  }

  static bookIdFromUrl(url: string): string {
    const q: number = url.indexOf('?');
    let name: string = q >= 0 ? url.substring(0, q) : url;
    const slash: number = name.lastIndexOf('/');
    if (slash >= 0) {
      name = name.substring(slash + 1);
    }
    const dot: number = name.lastIndexOf('.');
    if (dot > 0) {
      name = name.substring(0, dot);
    }
    return name;
  }

  static photoIdFromUrl(url: string): string {
    const q: number = url.indexOf('?');
    const path: string = q >= 0 ? url.substring(0, q) : url;
    const marker: string = '/photos/';
    const idx: number = path.indexOf(marker);
    if (idx < 0) {
      return '';
    }
    let i: number = idx + marker.length;
    let digits: string = '';
    while (i < path.length) {
      const c: string = path.charAt(i);
      if (c < '0' || c > '9') {
        break;
      }
      digits += c;
      i++;
    }
    return digits;
  }

  /** 分段数（对齐 jm_toolkit.py get_num：ord(md5 末字符) 取 ASCII 码） */
  static getSegmentationNum(epsId: string, scrambleId: string, pictureName: string): number {
    const epsID: number = Number.parseInt(epsId);
    if (Number.isNaN(epsID)) {
      return 0;
    }
    const sid: number = Number.parseInt(scrambleId);
    if (epsID < sid) {
      return 0;
    }
    if (epsID < 268850) {
      return 10;
    }
    const hash: string = JmApi.md5Hex(`${epsId}${pictureName}`);
    if (hash.length === 0) {
      return 0;
    }
    // Python: num = ord(s[-1]) % x * 2 + 2，取末字符的 ASCII 码而非十六进制值
    const sec: number = hash.charCodeAt(hash.length - 1);
    if (epsID < 421926) {
      return sec % 10 * 2 + 2;
    }
    return sec % 8 * 2 + 2;
  }

  /** 魔数嗅探：识别 JPEG/PNG/GIF/WebP/BMP，防御 200 状态码返回的 HTML 反爬页 */
  static looksLikeImage(bytes: Uint8Array): boolean {
    if (bytes.length < 12) {
      return false;
    }
    // JPEG: FF D8 FF
    if (bytes[0] === 0xFF && bytes[1] === 0xD8 && bytes[2] === 0xFF) {
      return true;
    }
    // PNG: 89 50 4E 47
    if (bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4E && bytes[3] === 0x47) {
      return true;
    }
    // GIF: 47 49 46 ("GIF")
    if (bytes[0] === 0x47 && bytes[1] === 0x49 && bytes[2] === 0x46) {
      return true;
    }
    // WebP: "RIFF"...."WEBP"
    if (bytes[0] === 0x52 && bytes[1] === 0x49 && bytes[2] === 0x46 && bytes[3] === 0x46 &&
      bytes[8] === 0x57 && bytes[9] === 0x45 && bytes[10] === 0x42 && bytes[11] === 0x50) {
      return true;
    }
    // BMP: 42 4D ("BM")
    if (bytes[0] === 0x42 && bytes[1] === 0x4D) {
      return true;
    }
    return false;
  }

  /** 打印字节头部 hex（诊断非图片响应用） */
  static headHex(bytes: Uint8Array): string {
    const n: number = Math.min(16, bytes.length);
    let out: string = '';
    for (let i = 0; i < n; i++) {
      out += bytes[i].toString(16).padStart(2, '0');
      if (i < n - 1) {
        out += ' ';
      }
    }
    return out;
  }

  static async decode(bytes: Uint8Array): Promise<image.PixelMap> {
    const data: ArrayBuffer = bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength);
    const source: image.ImageSource = image.createImageSource(data);
    const opts: image.DecodingOptions = { desiredPixelFormat: image.PixelMapFormat.RGBA_8888 };
    const pixelMap: image.PixelMap = await source.createPixelMap(opts);
    source.release();
    return pixelMap;
  }

  /**
   * 反打乱重组（对齐 jm_toolkit.py JmImageTool.decode_and_save / PicaComic _segmentationPicture）：
   * 源图按 floor(h/num) 高切段，末段附带 h%num 余数行；目标图从末段开始倒序整段贴合，段内不旋转。
   * 全量读出像素后用 createPixelMapFromPixels 重建，规避不可编辑像素图 writePixels 失败的问题。
   * 返回重组后的新 PixelMap（num<=1 或尺寸异常时原样返回传入的 pixelMap）。
   */
  static async recombine(pixelMap: image.PixelMap, url: string): Promise<image.PixelMap> {
    const aid: string = JmImage.photoIdFromUrl(url);
    const pictureName: string = JmImage.bookIdFromUrl(url);
    if (aid.length === 0) {
      Logger.info(TAG, `recombine skip: no photo id, url=${url}`);
      return pixelMap;
    }
    const scrambleId: string = await JmApi.fetchScrambleId(aid);
    const num: number = JmImage.getSegmentationNum(aid, scrambleId, pictureName);
    if (num <= 1) {
      Logger.info(TAG, `recombine skip: num=${num} aid=${aid} name=${pictureName} scramble=${scrambleId}`);
      return pixelMap;
    }
    const info: image.ImageInfo = await pixelMap.getImageInfo();
    const w: number = info.size.width;
    const h: number = info.size.height;
    const move: number = Math.floor(h / num);
    if (w <= 0 || h <= 0 || move < 1) {
      Logger.warn(TAG, `recombine skip: w=${w} h=${h} num=${num}`);
      return pixelMap;
    }
    const pxCount: number = w * h;
    const srcBuf: ArrayBuffer = new ArrayBuffer(pxCount * 4);
    await pixelMap.readAllPixelsToBuffer(srcBuf);
    const src: Uint32Array = new Uint32Array(srcBuf);
    const dstBuf: ArrayBuffer = new ArrayBuffer(pxCount * 4);
    const dst: Uint32Array = new Uint32Array(dstBuf);
    // 对齐 jm_toolkit.py decode_and_save：源图底段（含 h%num 余数行）贴到顶部，其余段依次下移，段内不旋转
    const over: number = h % num;
    for (let i: number = 0; i < num; i++) {
      let blockH: number = move;
      const srcRow: number = h - move * (i + 1) - over;
      let dstRow: number = move * i;
      if (i === 0) {
        blockH += over;
      } else {
        dstRow += over;
      }
      for (let r: number = 0; r < blockH; r++) {
        const srcOff: number = (srcRow + r) * w;
        const dstOff: number = (dstRow + r) * w;
        for (let c: number = 0; c < w; c++) {
          dst[dstOff + c] = src[srcOff + c];
        }
      }
    }
    pixelMap.release();
    const initOpts: image.InitializationOptions = {
      size: { width: w, height: h },
      srcPixelFormat: image.PixelMapFormat.RGBA_8888,
      pixelFormat: image.PixelMapFormat.RGBA_8888
    };
    const result: image.PixelMap = await image.createPixelMapFromPixels(dstBuf, initOpts);
    Logger.info(TAG, `recombine ok: num=${num} aid=${aid} name=${pictureName} w=${w} h=${h}`);
    return result;
  }
}
