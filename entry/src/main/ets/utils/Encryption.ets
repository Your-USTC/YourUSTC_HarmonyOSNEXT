
/**
 * 加密功能接口
 */

import { JSEncrypt } from '../utils/jsencrypt/lib/index';
import UnifiedPreference, { PASSWORD_KEY, UID_KEY } from '../utils/UnifyPreference';

class accountInfoProvider {

  private en = new JSEncrypt();

  private key = [`
-----BEGIN RSA PUBLIC KEY-----
MEgCQQCX0QD5l2oReKn1BLOXNYkuLM55B2xgeXIfKFjA0id/bDNqb45nptPidrGT
A56mFkEceviOoiKKdR5+qwUp5pKHAgMBAAE=
-----END RSA PUBLIC KEY-----
`, `
-----BEGIN RSA PRIVATE KEY-----
MIIBOgIBAAJBAJfRAPmXahF4qfUEs5c1iS4sznkHbGB5ch8oWMDSJ39sM2pvjmem
0+J2sZMDnqYWQRx6+I6iIop1Hn6rBSnmkocCAwEAAQJBAJVHpIfIRTnsxmHxP459
y+glktkbXYv3nynYCH2Bp+j4Nd5XOSSuhv8LbERfheIA6eUmSypG08+lzENZMHoT
LkECIQDy7dGuOW26oJ1WslXaXl1ddfhVyDzi4ZSrlm7I8ip7dwIhAJ/8K+GMKNwv
SZ1Mu72+Qqh/qnKX7KpD+aSpt52m2UVxAiB5owjdktXVn7yIf40rZRqcxIgO889A
zzDw5ccdCNyqqwIgTXg3630KYCzJ0dDRbH0QHDXN3LWylXRbE6BXWJDtzxECID/H
Khn2U/BWZPsaIliHKmxgwtHXQE+dfI9ByJxl4e+i
-----END RSA PRIVATE KEY-----
`];                                 // WARNING: 正式提交时需要更换

  constructor() {
    this.en.setPublicKey(this.key[0]);
    this.en.setPrivateKey(this.key[1]);
  }

  getUID(): string {
    return UnifiedPreference.getSync(UID_KEY);
  }

  encryptPassword(password: string): string {
    const cipher: string | false = this.en.encrypt(password);
    return cipher === false ? '' : cipher;
  }

  getPassword(): string {
    const password: string | false = this.en.decrypt(UnifiedPreference.getSync(PASSWORD_KEY));
    if (password === false) {
      console.info(`加密解密出现false：${UnifiedPreference.getSync(PASSWORD_KEY)}`);
    }
    return password === false ? '' : password;
  }
}

export default new accountInfoProvider();
