import test from 'node:test';
import assert from 'node:assert/strict';
import { generateKeyPairSync, verify as verifySignature } from 'node:crypto';
import { createVerifier, purchaseStatus, validateInput, ServiceError, MAX_AGE } from './verifier.mjs';
import { createPlayClient, createAccessToken } from './play.mjs';
import { createHandler } from './server.mjs';
import { Readable } from 'node:stream';

const keys = generateKeyPairSync('rsa', { modulusLength: 2048 });
const privateKey = keys.privateKey.export({ type: 'pkcs8', format: 'pem' });
const input = { product: 'remove_ads', token: 'play-token', device: 'a'.repeat(64), nonce: 'b'.repeat(64) };
function record(overrides = {}) {
  return {
    purchaseStateContext: { purchaseState: 'PURCHASED' },
    acknowledgementState: 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED',
    productLineItem: [{ productId: 'remove_ads', productOfferDetails: {
      purchaseOptionId: 'buy', quantity: 1, refundableQuantity: 1,
      consumptionState: 'CONSUMPTION_STATE_YET_TO_BE_CONSUMED',
    } }], ...overrides,
  };
}
function make(play) { return createVerifier({ play, privateKey, purchaseOption: 'buy', now: () => 1800000000 }); }
const claims = receipt => JSON.parse(Buffer.from(receipt.payload, 'base64'));

test('signed receipt binds exact package, product, installation, token and request; expires in seven days', async () => {
  const receipt = await make({ get: async () => record(), acknowledge: () => assert.fail() })(input);
  assert.ok(verifySignature('RSA-SHA256', Buffer.from(receipt.payload, 'base64'), keys.publicKey, Buffer.from(receipt.signature, 'base64')));
  const data = claims(receipt);
  assert.equal(data.status, 'active');
  assert.equal(data.package, 'io.github.vincentaz.memmem');
  assert.equal(data.product, 'remove_ads');
  assert.equal(data.device, input.device);
  assert.equal(data.nonce, input.nonce);
  assert.equal(data.token_hash.length, 64);
  assert.equal(data.expires_at - data.issued_at, MAX_AGE);
  assert.equal(JSON.stringify(receipt).includes(input.token), false);
});

test('pending, cancellation, refunds, wrong product, rental, consumed and multi-quantity never grant', async () => {
  for (const state of ['PENDING', 'CANCELLED']) {
    const receipt = await make({ get: async () => record({ purchaseStateContext: { purchaseState: state } }), acknowledge: () => assert.fail() })(input);
    assert.equal(claims(receipt).status, state === 'PENDING' ? 'pending' : 'revoked');
  }
  const alterations = [r => r.productLineItem[0].productId = 'other',
    r => r.productLineItem[0].productOfferDetails.refundableQuantity = 0,
    r => r.productLineItem[0].productOfferDetails.rentOfferDetails = {},
    r => r.productLineItem[0].productOfferDetails.quantity = 2,
    r => r.productLineItem[0].productOfferDetails.purchaseOptionId = 'rental',
    r => r.productLineItem[0].productOfferDetails.consumptionState = 'CONSUMPTION_STATE_CONSUMED'];
  for (const alter of alterations) { const r = record(); alter(r); assert.equal(purchaseStatus(r, 'buy'), 'revoked'); }
});

test('acknowledges once before grant, verifies completion, and coalesces concurrent callbacks', async () => {
  let acknowledged = false, acknowledgements = 0, reads = 0;
  const verify = make({ get: async () => { reads++; return record({ acknowledgementState: acknowledged ? 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED' : 'ACKNOWLEDGEMENT_STATE_PENDING' }); },
    acknowledge: async () => { acknowledgements++; acknowledged = true; } });
  const receipts = await Promise.all([verify(input), verify({ ...input, nonce: 'c'.repeat(64) })]);
  assert.equal(acknowledgements, 1);
  assert.equal(reads, 2);
  assert.equal(claims(receipts[0]).status, 'active');
  assert.equal(claims(receipts[1]).nonce, 'c'.repeat(64));
  await verify(input);
  assert.equal(acknowledgements, 1);
  assert.equal(reads, 3); // No stale positive cache; refunds are rechecked each time.
});

test('acknowledgement error grants only if Play confirms another worker already acknowledged', async () => {
  const r = record({ acknowledgementState: 'ACKNOWLEDGEMENT_STATE_PENDING' });
  const play = { get: async () => r, acknowledge: async () => { throw new Error('offline'); } };
  await assert.rejects(make(play)(input), { status: 503 });
  play.acknowledge = async () => { r.acknowledgementState = 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED'; throw new Error('raced'); };
  assert.equal(claims(await make(play)(input)).status, 'active');
});

test('no grants on outages, malformed input or unknown store state', async () => {
  for (const bad of [null, {}, { ...input, product: 'other' }, { ...input, token: '' }, { ...input, nonce: '' }, { ...input, device: 'other' }]) {
    assert.throws(() => validateInput(bad), { status: 400 });
  }
  await assert.rejects(make({ get: async () => { throw new ServiceError(503, 'Offline'); } })(input), { status: 503 });
  await assert.rejects(make({ get: async () => record({ purchaseStateContext: {} }) })(input), { status: 503 });
});

test('Play client fixes package and product, encodes tokens, never consumes and treats errors as retryable', async () => {
  const calls = [];
  const play = createPlayClient({ accessToken: async () => 'oauth', fetcher: async (url, options) => {
    calls.push({ url, options }); return { ok: true, json: async () => record() };
  } });
  await play.get('a/b?c');
  await play.acknowledge('a/b?c');
  assert.ok(calls[0].url.endsWith('/productsv2/tokens/a%2Fb%3Fc'));
  assert.ok(calls[1].url.endsWith('/products/remove_ads/tokens/a%2Fb%3Fc:acknowledge'));
  assert.equal(calls[1].options.method, 'POST');
  assert.equal(calls[0].options.redirect, 'error');
  assert.equal(calls[0].options.headers.Authorization, 'Bearer oauth');
  const failed = createPlayClient({ accessToken: async () => 'oauth', fetcher: async () => ({ ok: false, status: 404 }) });
  await assert.rejects(failed.get('token'), { status: 503 });
});

test('Cloud Run credentials request the Publisher scope and share refreshes', async () => {
  let calls = 0;
  let time = 1000;
  const get = createAccessToken({ env: {}, now: () => time, fetcher: async (url, options) => {
    calls++;
    assert.equal(new URL(url).searchParams.get('scopes'), 'https://www.googleapis.com/auth/androidpublisher');
    assert.equal(options.headers['Metadata-Flavor'], 'Google');
    return { ok: true, json: async () => ({ access_token: 'oauth', expires_in: 3600 }) };
  } });
  assert.deepEqual(await Promise.all([get(), get()]), ['oauth', 'oauth']);
  await get();
  assert.equal(calls, 1);
  time += 3600 * 1000;
  await get();
  assert.equal(calls, 2);
});

async function request(body, { method = 'POST', url = '/v1/play/verify', type = 'application/json' } = {}, verifier = async () => ({ ok: true })) {
  const req = Readable.from([Buffer.from(body)]);
  Object.assign(req, { method, url, headers: { 'content-type': type } });
  const result = {};
  const res = { writeHead: (status, headers) => Object.assign(result, { status, headers }), end: text => result.body = JSON.parse(text) };
  await createHandler(verifier)(req, res);
  return result;
}
test('HTTP boundary rejects wrong routes, content types, oversized bodies and invalid JSON', async () => {
  assert.equal((await request('{}', { url: '/other' })).status, 404);
  assert.equal((await request('{}', { type: 'text/plain' })).status, 415);
  assert.equal((await request('x'.repeat(8193))).status, 413);
  assert.equal((await request('{')).status, 400);
  const response = await request('{}');
  assert.equal(response.status, 200);
  assert.equal(response.headers['Cache-Control'], 'no-store');
});
