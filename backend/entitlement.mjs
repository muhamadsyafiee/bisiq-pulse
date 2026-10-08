import { createPrivateKey, sign } from 'node:crypto';

export const PACKAGE = 'com.pulseworkout.gym_timer';
export const PRODUCT = 'pulse_pro_lifetime';
export class VerificationError extends Error {
  constructor(status, code) { super(code); this.status = status; }
}
// Publisher 401/403 or an unknown package means server/Play Console
// configuration, never that the user's purchase was revoked.
export function classifyPublisherError(error) {
  const status = error?.response?.status;
  const message = String(error?.response?.data?.error?.message ?? '');
  if (status === 404 && /package not found/i.test(message)) {
    return new VerificationError(503, 'VERIFICATION_UNAVAILABLE');
  }
  if ([400, 404, 410].includes(status)) return new VerificationError(403, 'PURCHASE_REJECTED');
  return new VerificationError(503, 'VERIFICATION_UNAVAILABLE');
}
export function validateRequest(body) {
  if (!body || typeof body.purchaseToken !== 'string' || body.purchaseToken.length < 8 ||
      body.purchaseToken.length > 4096 || !/^[\w-]{16,64}$/.test(body.installationId ?? '')) {
    throw new VerificationError(400, 'INVALID_REQUEST');
  }
}
export function validatePurchase(purchase) {
  const state = purchase.purchaseStateContext?.purchaseState;
  if (state === 'PENDING') throw new VerificationError(409, 'PURCHASE_PENDING');
  if (state !== 'PURCHASED') throw new VerificationError(403, 'PURCHASE_REJECTED');
  const line = purchase.productLineItem?.find(item => item.productId === PRODUCT);
  const offer = line?.productOfferDetails;
  if (!offer || offer.rentOfferDetails || offer.preorderOfferDetails ||
      offer.consumptionState !== 'CONSUMPTION_STATE_YET_TO_BE_CONSUMED' ||
      !(offer.refundableQuantity > 0)) throw new VerificationError(403, 'PURCHASE_REJECTED');
  if (!['ACKNOWLEDGEMENT_STATE_PENDING', 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED'].includes(purchase.acknowledgementState)) {
    throw new VerificationError(503, 'VERIFICATION_UNAVAILABLE');
  }
}
export function createVerifier({ publisher, privateKey, now = () => Date.now() }) {
  const key = createPrivateKey(privateKey);
  if (key.asymmetricKeyType !== 'ed25519') throw new Error('Ed25519 signing key required');
  return async function verify(body) {
    validateRequest(body);
    const purchase = await publisher.get(body.purchaseToken);
    validatePurchase(purchase);
    if (purchase.acknowledgementState !== 'ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED') {
      await publisher.acknowledge(body.purchaseToken);
    }
    const issuedAt = Math.floor(now() / 1000);
    const claims = { version: 1, packageName: PACKAGE, productId: PRODUCT,
      installationId: body.installationId, issuedAt, expiresAt: issuedAt + 7 * 86400 };
    const bytes = Buffer.from(JSON.stringify(claims));
    return { payload: bytes.toString('base64url'), signature: sign(null, bytes, key).toString('base64url') };
  };
}
