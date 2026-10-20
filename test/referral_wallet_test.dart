import 'package:flutter_test/flutter_test.dart';
import 'package:upendo_app/models/wallet_model.dart';
import 'package:upendo_app/utils/referral_code.dart';
import 'package:upendo_app/utils/wallet_rules.dart';

void main() {
  group('referral code format', () {
    test('alphabet is uppercase letters + digits without 0/O/1/I', () {
      for (final c in ['0', 'O', '1', 'I']) {
        expect(kReferralCodeAlphabet.contains(c), isFalse, reason: c);
      }
      expect(kReferralCodeAlphabet.length, 32);
      expect(kReferralCodeAlphabet, kReferralCodeAlphabet.toUpperCase());
    });

    test('valid codes are exactly 4 allowed characters', () {
      expect(isValidReferralCode('AB2C'), isTrue);
      expect(isValidReferralCode('ZZ99'), isTrue);
      expect(isValidReferralCode('AB2'), isFalse);
      expect(isValidReferralCode('AB2CD'), isFalse);
      expect(isValidReferralCode('AB0C'), isFalse); // zero
      expect(isValidReferralCode('ABOC'), isFalse); // letter O
      expect(isValidReferralCode('AB1C'), isFalse); // one
      expect(isValidReferralCode('ABIC'), isFalse); // letter I
      expect(isValidReferralCode('ab2c'), isFalse); // not normalized
      expect(isValidReferralCode('AB-C'), isFalse);
    });

    test('normalizing trims and upper-cases input', () {
      expect(normalizeReferralCode('  ab2c '), 'AB2C');
      expect(isValidReferralCode(normalizeReferralCode(' ab2c')), isTrue);
    });

    test('referral field eligibility uses the Auth account age, like the server', () {
      final now = DateTime(2026, 10, 20, 12);
      // A brand-new Google sign-in — even though registerFcmToken already
      // created users/{uid} without createdAt — is offered the field.
      expect(canOfferReferralField(alreadyReferred: false, now: now,
          accountCreatedAt: now.subtract(const Duration(minutes: 1))), isTrue);
      expect(canOfferReferralField(alreadyReferred: false, now: now,
          accountCreatedAt: now.subtract(const Duration(days: kReferralNewUserWindowDays))), isTrue);
      expect(canOfferReferralField(alreadyReferred: false, now: now,
          accountCreatedAt: now.subtract(const Duration(days: kReferralNewUserWindowDays, seconds: 1))),
          isFalse);
      expect(canOfferReferralField(alreadyReferred: true, now: now, accountCreatedAt: now), isFalse);
      // Unknown creation time → let the server decide.
      expect(canOfferReferralField(alreadyReferred: false, now: now), isTrue);
    });
  });

  group('commission', () {
    test('1% of the payment, rounded to 2 decimals', () {
      expect(kReferralCommissionRate, 0.01);
      expect(referralCommission(10000), 100);
      expect(referralCommission(2500), 25);
      expect(referralCommission(1234), 12.34);
      expect(referralCommission(999), 9.99);
      expect(referralCommission(0), 0);
      expect(referralCommission(-50), 0);
    });

    test('roundMoney avoids floating-point noise', () {
      expect(roundMoney(0.1 + 0.2), 0.3);
      expect(roundMoney(100.005), closeTo(100.01, 0.0001));
    });
  });

  group('withdrawal amount', () {
    test('minimum is TZS 10,000 and cannot exceed the balance', () {
      expect(kMinWithdrawalTzs, 10000);
      expect(checkWithdrawalAmount(null, 50000), WithdrawalAmountError.invalid);
      expect(checkWithdrawalAmount(0, 50000), WithdrawalAmountError.invalid);
      expect(checkWithdrawalAmount(9999, 50000), WithdrawalAmountError.belowMinimum);
      expect(checkWithdrawalAmount(10000, 9000), WithdrawalAmountError.aboveBalance);
      expect(checkWithdrawalAmount(10000, 10000), isNull);
      expect(checkWithdrawalAmount(25000.5, 30000), isNull);
    });

    test('ID types map to the server values', () {
      expect(WithdrawalIdType.values.map((t) => t.value),
          ['national_id', 'drivers_license', 'passport']);
      expect(WithdrawalIdType.fromValue('passport'), WithdrawalIdType.passport);
      expect(WithdrawalIdType.fromValue('selfie'), isNull);
    });

    test('formatTzs', () {
      expect(formatTzs(10000), 'TZS 10,000');
      expect(formatTzs(12.5), 'TZS 12.50');
    });
  });

  group('wallet model tolerates missing fields', () {
    test('no wallet doc → zero wallet', () {
      final w = Wallet.fromMap(null);
      expect(w.balance, 0);
      expect(w.referralCount, 0);
    });

    test('int and double amounts are read as doubles', () {
      final w = Wallet.fromMap({'balance': 150, 'totalEarned': 150.25, 'referralCount': 3});
      expect(w.balance, 150.0);
      expect(w.totalEarned, 150.25);
      expect(w.pendingWithdrawal, 0);
      expect(w.referralCount, 3);
    });
  });
}
