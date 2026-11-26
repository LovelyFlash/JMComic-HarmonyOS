import { describe, it, expect } from '@ohos/hypium';
import { Translations } from '../main/ets/common/Translations';

export default function translationsTest() {
  describe('Translations', () => {
    it('defaults_to_chinese', 0, () => {
      Translations.setLocale('zh_CN');
      expect(Translations.t('tab_home')).assertEqual('主页');
      expect(Translations.t('language_en')).assertEqual('English');
    });

    it('switches_to_english', 0, () => {
      Translations.setLocale('en_US');
      expect(Translations.t('tab_home')).assertEqual('Home');
      expect(Translations.t('unknown')).assertEqual('Unknown');
      Translations.setLocale('zh_CN');
    });

    it('unknown_key_returns_key', 0, () => {
      expect(Translations.t('__missing_key__')).assertEqual('__missing_key__');
    });
  });
}
