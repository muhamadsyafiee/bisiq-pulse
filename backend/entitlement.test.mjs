import test from 'node:test';
import assert from 'node:assert/strict';
import { generateKeyPairSync, verify as verifySignature } from 'node:crypto';
import { classifyPublisherError, createVerifier, PRODUCT, PACKAGE } from './entitlement.mjs';
const pair = generateKeyPairSync('ed25519');
const privateKey = pair.privateKey.export({type:'pkcs8',format:'pem'});
const good = () => ({ purchaseStateContext: {purchaseState:'PURCHASED'},
  acknowledgementState:'ACKNOWLEDGEMENT_STATE_PENDING',
  productLineItem:[{productId:PRODUCT, productOfferDetails:{refundableQuantity:1, consumptionState:'CONSUMPTION_STATE_YET_TO_BE_CONSUMED'}}] });
const request = {purchaseToken:'play-test-token',installationId:'installation-test-1234'};
test('signed installation-bound seven-day lease is issued only after acknowledge', async () => {
  const calls=[];
  const verifier=createVerifier({privateKey,now:()=>Date.UTC(2026,9,8),publisher:{
    get:async token=>{calls.push(token);return good();},acknowledge:async token=>calls.push('ack:'+token)}});
  const result=await verifier(request);
  const bytes=Buffer.from(result.payload,'base64url');
  assert(verifySignature(null,bytes,pair.publicKey,Buffer.from(result.signature,'base64url')));
  const claims=JSON.parse(bytes);
  assert.equal(claims.packageName,PACKAGE);assert.equal(claims.productId,PRODUCT);
  assert.equal(claims.installationId,request.installationId);
  assert.equal(claims.expiresAt-claims.issuedAt,7*86400);
  assert.deepEqual(calls,['play-test-token','ack:play-test-token']);
});
for(const [name,change,status] of [
  ['pending',p=>p.purchaseStateContext.purchaseState='PENDING',409],
  ['cancelled',p=>p.purchaseStateContext.purchaseState='CANCELLED',403],
  ['wrong product',p=>p.productLineItem[0].productId='other',403],
  ['refunded',p=>p.productLineItem[0].productOfferDetails.refundableQuantity=0,403],
  ['consumed',p=>p.productLineItem[0].productOfferDetails.consumptionState='CONSUMPTION_STATE_CONSUMED',403],
  ['rental',p=>p.productLineItem[0].productOfferDetails.rentOfferDetails={},403],
  ['unknown acknowledge',p=>p.acknowledgementState='UNKNOWN',503],
]) test(`rejects ${name} without acknowledge or signed access`,async()=>{
  const purchase=good();change(purchase);
  const verifier=createVerifier({privateKey,publisher:{get:async()=>purchase,acknowledge:async()=>assert.fail('must not acknowledge')}});
  await assert.rejects(verifier(request),error=>error.status===status);
});
test('acknowledged restore does not acknowledge twice',async()=>{
  const purchase=good();purchase.acknowledgementState='ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED';
  const verifier=createVerifier({privateKey,publisher:{get:async()=>purchase,acknowledge:async()=>assert.fail()}});
  assert((await verifier(request)).signature);
});
test('upstream or acknowledgement failures never issue access',async()=>{
  for(const phase of ['get','acknowledge']) {
    const verifier=createVerifier({privateKey,publisher:{get:async()=>{if(phase==='get')throw Error('offline');return good();},acknowledge:async()=>{throw Error('offline');}}});
    await assert.rejects(verifier(request));
  }
});
test('malformed requests never call Google',async()=>{
  const verifier=createVerifier({privateKey,publisher:{get:async()=>assert.fail()}});
  for(const body of [{},{...request,installationId:'bad'}, {...request,purchaseToken:'x'.repeat(5000)}])
    await assert.rejects(verifier(body),error=>error.status===400);
});
test('Play Console configuration errors are not treated as revoked purchases', () => {
  const failure = (status, message = '') => ({ response: { status, data: { error: { message } } } });
  assert.equal(classifyPublisherError(failure(404, 'Package not found: com.pulseworkout.gym_timer.')).status, 503);
  assert.equal(classifyPublisherError(failure(401)).status, 503);
  assert.equal(classifyPublisherError(failure(403)).status, 503);
  assert.equal(classifyPublisherError(new Error('network')).status, 503);
  assert.equal(classifyPublisherError(failure(404, 'Purchase token not found.')).status, 403);
  assert.equal(classifyPublisherError(failure(410)).status, 403);
});
