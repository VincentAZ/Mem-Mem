import { createHash, createPrivateKey, sign, timingSafeEqual } from 'node:crypto';
import { PACKAGE, PRODUCT, MAX_AGE, ServiceError, validateInput } from './verifier.mjs';

// Reusable review credentials stay outside the app. Disable/rotate the hash to
// revoke renewals; already issued installation-bound receipts last at most 7 days.
export function createAccessRedeemer({ privateKey, codeHash = '', now = () => Math.floor(Date.now() / 1000) }) {
  if (codeHash && !/^[a-f0-9]{64}$/.test(codeHash)) throw new Error('Invalid ACCESS_CODE_SHA256.');
  const key = createPrivateKey(privateKey);
  if (key.asymmetricKeyType !== 'rsa' || key.asymmetricKeyDetails.modulusLength < 2048) {
    throw new Error('An RSA signing key of at least 2048 bits is required.');
  }
  return async input => {
    validateInput(input);
    const hash = createHash('sha256').update(input.token).digest();
    if (!codeHash || !timingSafeEqual(hash, Buffer.from(codeHash, 'hex'))) {
      throw new ServiceError(403, 'Access code is not valid.');
    }
    const issued = now();
    const payload = Buffer.from(JSON.stringify({
      version: 1, package: PACKAGE, product: PRODUCT, grant: 'review',
      device: input.device, nonce: input.nonce, token_hash: hash.toString('hex'),
      status: 'active', issued_at: issued, expires_at: issued + MAX_AGE,
    }));
    return { payload: payload.toString('base64'), signature: sign('RSA-SHA256', payload, key).toString('base64') };
  };
}
