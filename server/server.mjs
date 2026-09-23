import { createServer } from 'node:http';
import { readFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';
import { createVerifier, ServiceError } from './verifier.mjs';
import { createPlayClient } from './play.mjs';
import { createAccessRedeemer } from './access.mjs';

export function createHandler(verify, redeem) {
  let active = 0;
  return async (req, res) => {
    const reply = (status, body) => {
      res.writeHead(status, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store', 'X-Content-Type-Options': 'nosniff' });
      res.end(JSON.stringify(body));
    };
    if (req.method === 'GET' && req.url === '/health') return reply(200, { status: 'ok' });
    const operation = req.url === '/v1/play/verify' ? verify : req.url === '/v1/access/redeem' ? redeem : null;
    if (req.method !== 'POST' || !operation) return reply(404, { error: 'Not found.' });
    if (active >= 32) return reply(429, { error: 'Try again shortly.' });
    if ((req.headers['content-type'] ?? '').split(';')[0] !== 'application/json') return reply(415, { error: 'Use JSON.' });
    active++;
    try {
      const chunks = [];
      let size = 0;
      for await (const chunk of req) {
        size += chunk.length;
        if (size > 8192) throw new ServiceError(413, 'Request too large.');
        chunks.push(chunk);
      }
      let input;
      try { input = JSON.parse(Buffer.concat(chunks).toString('utf8')); }
      catch { throw new ServiceError(400, 'Invalid JSON.'); }
      reply(200, await operation(input));
    } catch (error) {
      const status = error instanceof ServiceError ? error.status : 503;
      // Do not log error objects: network errors can contain token-bearing URLs.
      if (status >= 500) console.error(JSON.stringify({ event: 'verification_unavailable', status }));
      if (!res.headersSent && !res.destroyed) reply(status, { error: error instanceof ServiceError ? error.message : 'Purchase verification unavailable.' });
    } finally { active--; }
  };
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const privateKey = readFileSync(process.env.RECEIPT_PRIVATE_KEY_FILE, 'utf8');
  const verify = createVerifier({
    play: createPlayClient(), privateKey,
    purchaseOption: process.env.PURCHASE_OPTION_ID,
  });
  const redeem = createAccessRedeemer({ privateKey, codeHash: process.env.ACCESS_CODE_SHA256 ?? '' });
  const server = createServer({ requestTimeout: 15000, headersTimeout: 10000, maxHeaderSize: 8192 }, createHandler(verify, redeem));
  server.listen(Number(process.env.PORT ?? 8080), '0.0.0.0');
  process.on('SIGTERM', () => server.close());
}
