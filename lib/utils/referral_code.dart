// Referral code format, mirrored from functions/referrals/codes.js (the
// server generates and validates codes — this is only for input checks
// before calling it): 4 characters, uppercase letters and digits, without
// the look-alikes 0/O and 1/I.

const kReferralCodeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const kReferralCodeLength = 4;

final RegExp _codePattern = RegExp('^[$kReferralCodeAlphabet]{$kReferralCodeLength}\$');

/// Trims and upper-cases user input ("ab2c " → "AB2C").
String normalizeReferralCode(String input) => input.trim().toUpperCase();

bool isValidReferralCode(String code) => _codePattern.hasMatch(code);

/// Mirrors REFERRAL_NEW_USER_WINDOW_DAYS (functions/wallet/constants.js):
/// only accounts at most this old may enter a referral code.
const int kReferralNewUserWindowDays = 7;

/// Whether the profile-setup screen should offer the referral code field.
/// Like the server (applyReferralCode), account age comes from the Firebase
/// Auth account ([accountCreatedAt] = User.metadata.creationTime), not from
/// users.createdAt — registerFcmToken often creates the users doc first,
/// without createdAt. The server makes the final call (it also checks for
/// prior payments and an existing referral claim).
bool canOfferReferralField({
  required bool alreadyReferred,
  DateTime? accountCreatedAt,
  DateTime? now,
}) {
  if (alreadyReferred) return false;
  // Unknown creation time: let the server decide.
  if (accountCreatedAt == null) return true;
  final age = (now ?? DateTime.now()).difference(accountCreatedAt);
  return age <= const Duration(days: kReferralNewUserWindowDays);
}
