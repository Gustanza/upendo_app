// Single source of truth for referral/wallet business rules on the server.
// The app mirrors MIN_WITHDRAWAL_TZS and REFERRAL_COMMISSION_RATE in
// lib/utils/wallet_rules.dart for display only — these values are what's
// actually enforced.

// Smallest amount a user may withdraw from their wallet, in TZS.
const MIN_WITHDRAWAL_TZS = 10000;

// Share of each completed payment by a referred user credited to the
// referrer's wallet (1%).
const REFERRAL_COMMISSION_RATE = 0.01;

// A referral code can only be entered by a "new user": an account whose
// users/{uid}.createdAt is at most this many days old and that has no
// completed payment yet.
const REFERRAL_NEW_USER_WINDOW_DAYS = 7;

const ID_TYPES = ['national_id', 'drivers_license', 'passport'];

module.exports = {
  MIN_WITHDRAWAL_TZS,
  REFERRAL_COMMISSION_RATE,
  REFERRAL_NEW_USER_WINDOW_DAYS,
  ID_TYPES,
};
