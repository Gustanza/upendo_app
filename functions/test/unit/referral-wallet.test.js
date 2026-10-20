// Pure-logic tests — no emulator needed:  npm test
const { test, describe } = require('node:test');
const assert = require('node:assert/strict');

const {
  REFERRAL_CODE_ALPHABET,
  generateCode,
  normalizeCode,
  isValidCodeFormat,
  validateReferralClaim,
} = require('../../referrals/codes');
const { round2, parseAmount, paymentAmountOf, commissionFor } = require('../../wallet/money');
const { validateWithdrawalInput } = require('../../wallet/withdrawals');
const { MIN_WITHDRAWAL_TZS, REFERRAL_COMMISSION_RATE } = require('../../wallet/constants');

describe('referral code format', () => {
  test('alphabet excludes ambiguous 0/O/1/I and is uppercase + digits', () => {
    for (const c of ['0', 'O', '1', 'I']) assert.ok(!REFERRAL_CODE_ALPHABET.includes(c), c);
    assert.equal(REFERRAL_CODE_ALPHABET.length, 32);
    assert.match(REFERRAL_CODE_ALPHABET, /^[A-Z2-9]+$/);
  });

  test('generated codes are 4 valid characters', () => {
    for (let i = 0; i < 500; i++) {
      const code = generateCode();
      assert.equal(code.length, 4);
      assert.ok(isValidCodeFormat(code), code);
    }
    // Deterministic RNG → deterministic code.
    assert.equal(generateCode(() => 0), 'AAAA');
    assert.equal(generateCode((max) => max - 1), '9999');
  });

  test('format validation and normalization', () => {
    assert.ok(isValidCodeFormat('AB2C'));
    for (const bad of ['AB2', 'AB2CD', 'AB0C', 'ABOC', 'AB1C', 'ABIC', 'ab2c', '', null, 1234]) {
      assert.ok(!isValidCodeFormat(bad), String(bad));
    }
    assert.equal(normalizeCode(' ab2c '), 'AB2C');
    assert.equal(normalizeCode(undefined), '');
  });
});

describe('validateReferralClaim', () => {
  const now = new Date('2026-10-20T10:00:00Z');
  const freshAuth = new Date('2026-10-19T10:00:00Z');
  const base = { code: 'AB2C', uid: 'newbie', userData: { fullName: 'N' }, codeOwnerUid: 'owner', hasCompletedPayment: false, accountCreatedAt: freshAuth, now };

  test('accepts a new, unreferred user with someone else\'s code', () => {
    assert.equal(validateReferralClaim(base), null);
  });

  test('rejects bad format, unknown code, own code', () => {
    assert.equal(validateReferralClaim({ ...base, code: 'AB0C' }), 'invalid-format');
    assert.equal(validateReferralClaim({ ...base, codeOwnerUid: null }), 'not-found');
    assert.equal(validateReferralClaim({ ...base, codeOwnerUid: 'newbie' }), 'own-code');
  });

  test('can only be set once', () => {
    assert.equal(validateReferralClaim({ ...base, userData: { referredBy: 'x' } }), 'already-referred');
    // referralClaims is the source of truth even if users.referredBy was wiped.
    assert.equal(validateReferralClaim({ ...base, alreadyClaimed: true }), 'already-referred');
  });

  test('only for new users (recent Auth account, no completed payment)', () => {
    assert.equal(validateReferralClaim({ ...base, accountCreatedAt: null }), 'not-new-user');
    assert.equal(validateReferralClaim({ ...base, accountCreatedAt: new Date('2026-09-01T00:00:00Z') }), 'not-new-user');
    // users.createdAt is ignored — a client could rewrite it.
    assert.equal(validateReferralClaim({ ...base, accountCreatedAt: new Date('2024-01-01'), userData: { createdAt: now } }), 'not-new-user');
    assert.equal(validateReferralClaim({ ...base, hasCompletedPayment: true }), 'not-new-user');
    assert.equal(validateReferralClaim({ ...base, userData: null }), 'no-profile');
    // Firestore Timestamp-like objects are accepted too.
    assert.equal(validateReferralClaim({ ...base, accountCreatedAt: { toDate: () => freshAuth } }), null);
  });
});

describe('commission maths', () => {
  test('1% of the amount, 2-decimal rounding', () => {
    assert.equal(REFERRAL_COMMISSION_RATE, 0.01);
    assert.equal(commissionFor(10000), 100);
    assert.equal(commissionFor(1234), 12.34);
    assert.equal(commissionFor('5,000'), 50);
    assert.equal(commissionFor(0), 0);
    assert.equal(commissionFor('abc'), 0);
    assert.equal(round2(0.1 + 0.2), 0.3);
    assert.equal(parseAmount(' 2500 '), 2500);
  });

  test('uses the amount the provider reported, falling back to the package price', () => {
    assert.equal(paymentAmountOf({ payment_amount: '9000', amount: 10000 }), 9000);
    // An inflated reported amount is capped at the package price.
    assert.equal(paymentAmountOf({ payment_amount: '9999999', amount: 10000 }), 10000);
    assert.equal(paymentAmountOf({ payment_amount: 5000 }), 5000);
    assert.equal(paymentAmountOf({ payment_amount: null, amount: 10000 }), 10000);
    assert.equal(paymentAmountOf({ payment_amount: 0, amount: '7000' }), 7000);
    assert.equal(paymentAmountOf({}), 0);
  });
});

describe('validateWithdrawalInput', () => {
  const ok = {
    fullName: 'Asha Juma',
    phone: '+255 712 345 678',
    amount: MIN_WITHDRAWAL_TZS,
    notes: '',
    idType: 'national_id',
    idPhotoPath: 'withdrawals/u1/123_id.jpg',
  };

  test('accepts a complete request at the minimum', () => {
    const { value, error } = validateWithdrawalInput('u1', ok);
    assert.equal(error, undefined);
    assert.equal(value.amount, 10000);
  });

  test('rejects below-minimum, bad fields and foreign ID photos', () => {
    const reason = (patch) => validateWithdrawalInput('u1', { ...ok, ...patch }).error;
    assert.equal(MIN_WITHDRAWAL_TZS, 10000);
    assert.equal(reason({ amount: 9999 }), 'below-minimum');
    assert.equal(reason({ amount: -5 }), 'invalid-amount');
    assert.equal(reason({ amount: 'lots' }), 'invalid-amount');
    assert.equal(reason({ fullName: 'A' }), 'invalid-name');
    assert.equal(reason({ phone: 'call me' }), 'invalid-phone');
    assert.equal(reason({ idType: 'selfie' }), 'invalid-id-type');
    assert.equal(reason({ idPhotoPath: 'withdrawals/someone-else/x.jpg' }), 'invalid-id-photo');
    assert.equal(reason({ idPhotoPath: 'withdrawals/u1/../u2/x.jpg' }), 'invalid-id-photo');
    assert.equal(reason({ notes: 'x'.repeat(501) }), 'notes-too-long');
  });
});
