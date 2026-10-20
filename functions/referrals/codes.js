const crypto = require('crypto');
const { REFERRAL_NEW_USER_WINDOW_DAYS } = require('../wallet/constants');

// 4 characters from uppercase letters + digits, without the look-alikes
// 0/O and 1/I (32 symbols → 1,048,576 possible codes). Mirrored by
// kReferralCodeAlphabet in lib/utils/referral_code.dart for input checks.
const REFERRAL_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const REFERRAL_CODE_LENGTH = 4;

const CODE_PATTERN = new RegExp(`^[${REFERRAL_CODE_ALPHABET}]{${REFERRAL_CODE_LENGTH}}$`);

// randomInt(max) → integer in [0, max). Injectable for tests.
function generateCode(randomInt = crypto.randomInt) {
  let code = '';
  for (let i = 0; i < REFERRAL_CODE_LENGTH; i++) {
    code += REFERRAL_CODE_ALPHABET[randomInt(REFERRAL_CODE_ALPHABET.length)];
  }
  return code;
}

function normalizeCode(input) {
  return typeof input === 'string' ? input.trim().toUpperCase() : '';
}

function isValidCodeFormat(code) {
  return typeof code === 'string' && CODE_PATTERN.test(code);
}

function toDate(value) {
  if (!value) return null;
  if (value instanceof Date) return value;
  if (typeof value.toDate === 'function') return value.toDate();
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

// Decides whether `uid` may claim `code`. Pure — the caller reads the
// user doc, the referralCodes/{code} owner, whether a server-only
// referralClaims/{uid} record exists, whether the user has a completed
// payment, and when the Firebase Auth account was created. Returns null
// when allowed, otherwise a reason string the app maps to a message.
//
// "New user" is judged from the Auth account's creation time
// (accountCreatedAt), never from users.createdAt, which a client could
// rewrite. "Already referred" comes from referralClaims, which survives the
// user doc being deleted and recreated.
function validateReferralClaim({
  code,
  uid,
  userData,
  codeOwnerUid,
  hasCompletedPayment,
  alreadyClaimed = false,
  accountCreatedAt,
  now = new Date(),
  windowDays = REFERRAL_NEW_USER_WINDOW_DAYS,
}) {
  if (!isValidCodeFormat(code)) return 'invalid-format';
  if (!userData) return 'no-profile';
  if (alreadyClaimed || userData.referredBy) return 'already-referred';
  if (!codeOwnerUid) return 'not-found';
  if (codeOwnerUid === uid) return 'own-code';
  const createdAt = toDate(accountCreatedAt);
  if (!createdAt) return 'not-new-user';
  if (now.getTime() - createdAt.getTime() > windowDays * 24 * 60 * 60 * 1000) {
    return 'not-new-user';
  }
  if (hasCompletedPayment) return 'not-new-user';
  return null;
}

module.exports = {
  REFERRAL_CODE_ALPHABET,
  REFERRAL_CODE_LENGTH,
  generateCode,
  normalizeCode,
  isValidCodeFormat,
  validateReferralClaim,
};
