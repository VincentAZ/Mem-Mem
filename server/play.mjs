import { readFileSync } from 'node:fs';
import { sign } from 'node:crypto';
import { PACKAGE, PRODUCT, ServiceError } from './verifier.mjs';

// Cloud Run uses its attached service account. An explicit key file is supported for
// local operations; credentials and purchase tokens never enter application logs.
export function createAccessToken({ env = process.env, fetcher = fetch, now = () => Date.now() } = {}) {
  let cached;
  let refreshing;
  const credentials = env.GOOGLE_APPLICATION_CREDENTIALS
    ? JSON.parse(readFileSync(env.GOOGLE_APPLICATION_CREDENTIALS, 'utf8')) : null;
  async function refresh() {
    let response;
    if (credentials) {
      if (credentials.type !== 'service_account') throw new Error('Use service account credentials.');
      const timestamp = Math.floor(now() / 1000);
      const encode = data => Buffer.from(JSON.stringify(data)).toString('base64url');
      const jwt = `${encode({ alg: 'RS256', typ: 'JWT' })}.${encode({
        iss: credentials.client_email, scope: 'https://www.googleapis.com/auth/androidpublisher',
        aud: 'https://oauth2.googleapis.com/token', iat: timestamp, exp: timestamp + 3600,
      })}`;
      const assertion = `${jwt}.${sign('RSA-SHA256', Buffer.from(jwt), credentials.private_key).toString('base64url')}`;
      response = await fetcher('https://oauth2.googleapis.com/token', {
        method: 'POST', body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }),
        signal: AbortSignal.timeout(8000), redirect: 'error',
      });
    } else {
      const scopes = encodeURIComponent('https://www.googleapis.com/auth/androidpublisher');
      response = await fetcher(`http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token?scopes=${scopes}`, {
        headers: { 'Metadata-Flavor': 'Google' }, signal: AbortSignal.timeout(3000), redirect: 'error',
      });
    }
    if (!response.ok) throw new ServiceError(503, 'Store authorization unavailable.');
    const data = await response.json();
    if (typeof data.access_token !== 'string' || !(data.expires_in > 60)) {
      throw new ServiceError(503, 'Store authorization unavailable.');
    }
    cached = { token: data.access_token, expires: now() + (data.expires_in - 60) * 1000 };
    return cached.token;
  }
  return async () => {
    if (cached?.expires > now()) return cached.token;
    if (!refreshing) refreshing = refresh().finally(() => { refreshing = undefined; });
    return refreshing;
  };
}

export function createPlayClient({ accessToken = createAccessToken(), fetcher = fetch } = {}) {
  const root = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE}/purchases`;
  async function request(url, method = 'GET') {
    const response = await fetcher(url, {
      method, headers: { Authorization: `Bearer ${await accessToken()}`, 'Content-Type': 'application/json' },
      ...(method === 'POST' ? { body: '{}' } : {}), signal: AbortSignal.timeout(8000), redirect: 'error',
    });
    // Errors are retryable, not proof of revocation. Only an authenticated Play
    // record (including refunded quantity) or an empty device query removes access.
    if (!response.ok) throw new ServiceError(503, 'Google Play is temporarily unavailable.');
    return method === 'GET' ? response.json() : null;
  }
  return {
    get: token => request(`${root}/productsv2/tokens/${encodeURIComponent(token)}`),
    acknowledge: token => request(`${root}/products/${PRODUCT}/tokens/${encodeURIComponent(token)}:acknowledge`, 'POST'),
  };
}
