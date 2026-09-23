import { createHash, createPrivateKey, sign } from 'node:crypto';

export const PACKAGE = 'io.github.vincentaz.memmem';
export const PRODUCT = 'remove_ads';
export const MAX_AGE = 7 * 24 * 60 * 60;
export class ServiceError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}

export function validateInput(input) {
  if (!input || input.product !== PRODUCT || typeof input.token !== 'string' ||
      input.token.length < 1 || input.token.length > 4096 || /[\s\x00-\x1f]/.test(input.token) ||
      typeof input.device !== 'string' || typeof input.nonce !== 'string' ||
      !/^[a-f0-9]{64}$/.test(input.device ?? '') || !/^[a-f0-9]{64}$/.test(input.nonce ?? '')) {
    throw new ServiceError(400, 'Invalid purchase request.');
  }
}

export function purchaseStatus(record, purchaseOption) {
  const items = record.productLineItem;
  if (!Array.isArray(items) || items.length !== 1 || items[0].productId !== PRODUCT) {
    return 'revoked';
  }
  const offer = items[0].productOfferDetails;
  if (!offer || offer.purchaseOptionId !== purchaseOption || offer.rentOfferDetails) return 'revoked';
  const state = record.purchaseStateContext?.purchaseState;
  if (state === 'PENDING') return 'pending';
  if (state === 'CANCELLED') return 'revoked';
  if (state !== 'PURCHASED') throw new ServiceError(503, 'Purchase status unavailable.');
  if (offer.consumptionState !== 'CONSUMPTION_STATE_YET_TO_BE_CONSUMED' ||
      offer.quantity !== 1 || offer.refundableQuantity !== 1) return 'revoked';
  return 'active';
}

export function createVerifier({ play, privateKey, purchaseOption, now = () => Math.floor(Date.now() / 1000) }) {
  const key = createPrivateKey(privateKey);
  if (key.asymmetricKeyType !== 'rsa' || key.asymmetricKeyDetails.modulusLength < 2048) {
    throw new Error('An RSA signing key of at least 2048 bits is required.');
  }
  if (!/^[a-z0-9][a-z0-9-]{0,62}$/.test(purchaseOption ?? '')) throw new Error('Set PURCHASE_OPTION_ID.');
  // Permanent access is a boolean, never an incrementing grant. Duplicate verification
  // is harmless; collapse concurrent requests for the same token within this process.
  const inFlight = new Map();
  async function check(token) {
    let record = await play.get(token);
    let status = purchaseStatus(record, purchaseOption);
    if (status === 'active' && record.acknowledgementState !== 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED') {
      if (record.acknowledgementState !== 'ACKNOWLEDGEMENT_STATE_PENDING') {
        throw new ServiceError(503, 'Acknowledgement status unavailable.');
      }
      try { await play.acknowledge(token); }
      catch { /* A concurrent instance may already have acknowledged. Re-read Play. */ }
      record = await play.get(token);
      status = purchaseStatus(record, purchaseOption);
      if (status === 'active' && record.acknowledgementState !== 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED') {
        throw new ServiceError(503, 'Purchase confirmation is temporarily unavailable.');
      }
    }
    return status;
  }
  return async function verify(input) {
    validateInput(input);
    const tokenHash = createHash('sha256').update(input.token).digest('hex');
    let work = inFlight.get(tokenHash);
    if (!work) {
      work = check(input.token);
      inFlight.set(tokenHash, work);
    }
    let status;
    try { status = await work; }
    finally { if (inFlight.get(tokenHash) === work) inFlight.delete(tokenHash); }
    const issued = now();
    const payload = Buffer.from(JSON.stringify({
      version: 1, package: PACKAGE, product: PRODUCT, device: input.device,
      nonce: input.nonce, token_hash: tokenHash, status,
      issued_at: issued, expires_at: issued + MAX_AGE,
    }));
    return { payload: payload.toString('base64'), signature: sign('RSA-SHA256', payload, key).toString('base64') };
  };
}
