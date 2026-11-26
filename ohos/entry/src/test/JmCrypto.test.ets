import { describe, it, expect } from '@ohos/hypium';
import { JmCrypto } from '../main/ets/data/api/JmCrypto';

export default function jmCryptoTest() {
  describe('JmCrypto', () => {
    it('md5_empty', 0, () => {
      expect(JmCrypto.md5Hex('')).assertEqual('d41d8cd98f00b204e9800998ecf8427e');
    });

    it('md5_abc', 0, () => {
      expect(JmCrypto.md5Hex('abc')).assertEqual('900150983cd24fb0d6963f7d28e17f72');
    });

    it('token_matches_md5_of_time_and_secret', 0, () => {
      expect(JmCrypto.generateToken('1700000000', 'secret'))
        .assertEqual(JmCrypto.md5Hex('1700000000secret'));
    });
  });
}
