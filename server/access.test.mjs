import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash, generateKeyPairSync, verify } from 'node:crypto';
import { Readable } from 'node:stream';
import { createAccessRedeemer } from './access.mjs';
import { createHandler } from './server.mjs';
import { MAX_AGE } from './verifier.mjs';

const keys = generateKeyPairSync('rsa', { modulusLength: 2048 });
const privateKey = keys.privateKey.export({ type: 'pkcs8', format: 'pem' });
const code = 'test-review-code-with-more-than-32-characters';
const codeHash = createHash('sha256').update(code).digest('hex');
const input = { product: 'remove_ads', token: code, device: 'a'.repeat(64), nonce: 'b'.repeat(64) };

test('review access is reusable, installation-bound, signed, and expires in seven days', async () => {
  const redeem = createAccessRedeemer({ privateKey, codeHash, now: () => 1800000000 });
  for (const device of ['a'.repeat(64), 'c'.repeat(64)]) {
    const receipt = await redeem({ ...input, device });
    const raw = Buffer.from(receipt.payload, 'base64');
    assert.ok(verify('RSA-SHA256', raw, keys.publicKey, Buffer.from(receipt.signature, 'base64')));
    const claims = JSON.parse(raw);
    assert.equal(claims.device, device);
    assert.equal(claims.nonce, input.nonce);
    assert.equal(claims.grant, 'review');
    assert.equal(claims.token_hash, codeHash);
    assert.equal(claims.status, 'active');
    assert.equal(claims.expires_at - claims.issued_at, MAX_AGE);
    assert.equal(raw.toString().includes(code), false);
  }
});

test('missing, wrong, or rotated credential never grants and malformed requests fail closed', async () => {
  for (const hash of ['', 'f'.repeat(64)]) {
    await assert.rejects(createAccessRedeemer({ privateKey, codeHash: hash })(input), { status: 403 });
  }
  const redeem = createAccessRedeemer({ privateKey, codeHash });
  await assert.rejects(redeem({ ...input, token: code + 'x' }), { status: 403 });
  for (const change of [{ device: 'invalid' }, { nonce: '' }, { product: 'other' }, { token: '' }]) {
    await assert.rejects(redeem({ ...input, ...change }), { status: 400 });
  }
  assert.throws(() => createAccessRedeemer({ privateKey, codeHash: 'invalid' }));
});

test('access route never calls Play and uses the bounded JSON HTTP boundary', async () => {
  const handler = createHandler(() => assert.fail('review access must not call Play'),
    createAccessRedeemer({ privateKey, codeHash }));
  for (const [body, expected] of [[JSON.stringify(input), 200], ['x'.repeat(8193), 413], ['{', 400]]) {
    const req = Readable.from([Buffer.from(body)]);
    Object.assign(req, { method: 'POST', url: '/v1/access/redeem', headers: { 'content-type': 'application/json' } });
    let status;
    await handler(req, { writeHead(value) { status = value; }, end() {} });
    assert.equal(status, expected);
  }
});
