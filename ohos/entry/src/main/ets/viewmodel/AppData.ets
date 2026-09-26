// viewmodel/AppData.ets - 全局应用状态
import { ApiConstants } from '../common/Constants';

export class AppData {
  static initialized: boolean = false;

  static currentSource: string = 'picacg';

  static jmDomains: string[] = [
    ApiConstants.JM_DEFAULT_BASE,
    'https://jmcomic.me',
    'https://jmcomic1.me',
    'https://jmcomic2.me'
  ];

  static jmDomainIndex: number = 0;

  static jmImgUrl: string = 'https://cdn-msp3.jmapiproxy1.cc';

  static htBaseUrl: string = ApiConstants.HT_DEFAULT_BASE;

  static hitomiBaseDomain: string = ApiConstants.HITOMI_BASE;

  static enabledSources: string[] = [
    'picacg',
    'jm',
    'eh',
    'exh',
    'nh',
    'hitomi',
    'ht'
  ];

  static readonly BUILT_IN_SOURCES: string[] = [
    'picacg',
    'jm',
    'eh',
    'exh',
    'nh',
    'hitomi',
    'ht'
  ];

  static getCurrentJmDomain(): string {
    if (AppData.jmDomainIndex >= 0 && AppData.jmDomainIndex < AppData.jmDomains.length) {
      return AppData.jmDomains[AppData.jmDomainIndex];
    }
    return ApiConstants.JM_DEFAULT_BASE;
  }

  static isSourceEnabled(source: string): boolean {
    return AppData.enabledSources.indexOf(source) !== -1;
  }
}
