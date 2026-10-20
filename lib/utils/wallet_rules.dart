import 'package:intl/intl.dart';

// Wallet business rules as shown in the app. The server is authoritative —
// these mirror functions/wallet/constants.js (keep both in sync) so the
// form can reject obvious mistakes before calling requestWithdrawal.

/// Smallest withdrawal, in TZS.
const int kMinWithdrawalTzs = 10000;

/// Share of each payment by a referred friend credited to the referrer.
const double kReferralCommissionRate = 0.01;

/// Same rounding as the server (2 decimals).
double roundMoney(double value) => (value * 100).roundToDouble() / 100;

/// Commission earned for a payment of [amount] TZS.
double referralCommission(num amount) =>
    amount <= 0 ? 0 : roundMoney(amount * kReferralCommissionRate);

/// "TZS 12,345" (or "TZS 12,345.50" when there are cents).
String formatTzs(num amount) {
  final hasCents = amount != amount.roundToDouble();
  final pattern = NumberFormat(hasCents ? '#,##0.00' : '#,##0', 'en_US');
  return 'TZS ${pattern.format(amount)}';
}

/// Why a withdrawal amount can't be requested, or null if it can.
enum WithdrawalAmountError { invalid, belowMinimum, aboveBalance }

WithdrawalAmountError? checkWithdrawalAmount(num? amount, num balance) {
  if (amount == null || amount <= 0) return WithdrawalAmountError.invalid;
  if (amount < kMinWithdrawalTzs) return WithdrawalAmountError.belowMinimum;
  if (amount > balance) return WithdrawalAmountError.aboveBalance;
  return null;
}

/// ID document attached to a withdrawal request; [value] is what the
/// server stores (see ID_TYPES in functions/wallet/constants.js).
enum WithdrawalIdType {
  nationalId('national_id'),
  driversLicense('drivers_license'),
  passport('passport');

  const WithdrawalIdType(this.value);
  final String value;

  static WithdrawalIdType? fromValue(String? value) {
    for (final t in values) {
      if (t.value == value) return t;
    }
    return null;
  }
}
