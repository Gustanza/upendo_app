const { REFERRAL_COMMISSION_RATE } = require('./constants');

// Wallet amounts are TZS with at most 2 decimals. Every balance is
// recomputed and rounded inside a transaction (never FieldValue.increment
// on fractional values), so floating-point drift can't accumulate.
function round2(value) {
  return Math.round((Number(value) + Number.EPSILON) * 100) / 100;
}

// Parses an amount that payment providers may send as a number or a
// numeric string ("10000", "10,000.00"). Returns NaN when unusable.
function parseAmount(value) {
  if (typeof value === 'number') return value;
  if (typeof value === 'string') return Number(value.replace(/,/g, '').trim());
  return NaN;
}

// The amount actually paid for a subscription: what the provider reported
// collecting (ClickPesa collectedAmount / PesaPal amount, stored as
// payment_amount), falling back to the package price recorded at checkout.
// When both are known the lower one is used, so a webhook reporting an
// inflated amount can never earn more than 1% of the package price.
function paymentAmountOf(subscription) {
  const reported = parseAmount(subscription && subscription.payment_amount);
  const listed = parseAmount(subscription && subscription.amount);
  const okReported = Number.isFinite(reported) && reported > 0;
  const okListed = Number.isFinite(listed) && listed > 0;
  if (okReported && okListed) return Math.min(reported, listed);
  if (okReported) return reported;
  return okListed ? listed : 0;
}

function commissionFor(amount, rate = REFERRAL_COMMISSION_RATE) {
  const value = parseAmount(amount);
  if (!Number.isFinite(value) || value <= 0) return 0;
  return round2(value * rate);
}

module.exports = { round2, parseAmount, paymentAmountOf, commissionFor };
