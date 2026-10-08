import { createServer } from 'node:http';
import { GoogleAuth } from 'google-auth-library';
import { PACKAGE, PRODUCT, VerificationError, classifyPublisherError, createVerifier } from './entitlement.mjs';

// Use workload identity / Application Default Credentials. No credentials are
// accepted from the mobile app, committed to Git, or printed in request logs.
const auth = new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/androidpublisher'] });
const base = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE}/purchases`;
async function request(url, method = 'GET') {
  try {
    const client = await auth.getClient();
    const result = await client.request({ url, method, ...(method === 'POST' ? { data: {} } : {}), timeout: 15000 });
    return result.data;
  } catch (error) {
    throw classifyPublisherError(error);
  }
}
const verify = createVerifier({
  privateKey: process.env.PULSE_ENTITLEMENT_PRIVATE_KEY,
  publisher: {
    get: token => request(`${base}/productsv2/tokens/${encodeURIComponent(token)}`),
    acknowledge: async token => {
      try {
        await request(`${base}/products/${PRODUCT}/tokens/${encodeURIComponent(token)}:acknowledge`, 'POST');
      } catch (error) {
        // Concurrent restores can acknowledge the same purchase. Re-read its
        // state; only continue when Google confirms acknowledgement.
        const item = await request(`${base}/productsv2/tokens/${encodeURIComponent(token)}`);
        if (item.acknowledgementState !== 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED') throw error;
      }
    },
  },
});
let active = 0;
const server = createServer(async (req, res) => {
  const send = (status, body) => {
    res.writeHead(status, { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' });
    res.end(JSON.stringify(body));
  };
  if (req.method === 'GET' && req.url === '/health') { send(200, { status: 'ok' }); return; }
  if (req.method !== 'POST' || req.url !== '/v1/entitlements/verify') { send(404, { error: 'NOT_FOUND' }); return; }
  if (active >= 16) { send(429, { error: 'RETRY_LATER' }); return; }
  active++;
  try {
    if (!req.headers['content-type']?.startsWith('application/json')) throw new VerificationError(415, 'JSON_REQUIRED');
    let raw = '';
    for await (const chunk of req) {
      raw += chunk.toString('utf8');
      if (Buffer.byteLength(raw) > 8192) throw new VerificationError(413, 'REQUEST_TOO_LARGE');
    }
    let body;
    try { body = JSON.parse(raw); } catch { throw new VerificationError(400, 'INVALID_REQUEST'); }
    send(200, await verify(body));
  } catch (error) {
    send(error instanceof VerificationError ? error.status : 503,
      { error: error instanceof VerificationError ? error.message : 'VERIFICATION_UNAVAILABLE' });
  } finally { active--; }
});
server.requestTimeout = 30000;
server.headersTimeout = 10000;
server.listen(Number(process.env.PORT ?? 8080), '0.0.0.0');
