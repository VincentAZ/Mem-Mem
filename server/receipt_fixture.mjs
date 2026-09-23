// Disposable cross-language signature fixture. Contains no private key or live token.
import { createHash, generateKeyPairSync } from 'node:crypto';
import { writeFileSync } from 'node:fs';
import { createVerifier } from './verifier.mjs';
import { createAccessRedeemer } from './access.mjs';
const { privateKey, publicKey } = generateKeyPairSync('rsa', { modulusLength: 2048 });
const record = {
  purchaseStateContext: { purchaseState: 'PURCHASED' },
  acknowledgementState: 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED',
  productLineItem: [{ productId: 'remove_ads', productOfferDetails: {
    purchaseOptionId: 'buy', quantity: 1, refundableQuantity: 1,
    consumptionState: 'CONSUMPTION_STATE_YET_TO_BE_CONSUMED',
  } }],
};
const input = { product: 'remove_ads', token: 'fixture-token', device: 'a'.repeat(64), nonce: 'b'.repeat(64) };
const verify = createVerifier({ play: { get: async () => record }, privateKey: privateKey.export({ type: 'pkcs8', format: 'pem' }), purchaseOption: 'buy' });
const accessCode = 'fixture-review-access-code-with-32-characters';
const redeem = createAccessRedeemer({ privateKey: privateKey.export({ type: 'pkcs8', format: 'pem' }),
  codeHash: createHash('sha256').update(accessCode).digest('hex') });
writeFileSync(process.argv[2], JSON.stringify({ public_key: publicKey.export({ type: 'spki', format: 'pem' }),
  receipt: await verify(input), access_code: accessCode, access_receipt: await redeem({ ...input, token: accessCode }) }));
