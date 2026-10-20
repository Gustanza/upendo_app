import 'package:cloud_functions/cloud_functions.dart';

import '../l10n/l10n.dart';
import '../utils/referral_code.dart';

/// A referral code the server refused; [reason] comes from
/// validateReferralClaim in functions/referrals/codes.js.
class ReferralException implements Exception {
  final String reason;
  const ReferralException(this.reason);

  String message(AppLocalizations l10n) => switch (reason) {
        'invalid-format' => l10n.referralErrorFormat,
        'not-found' => l10n.referralErrorNotFound,
        'own-code' => l10n.referralErrorOwnCode,
        'already-referred' => l10n.referralErrorAlreadyUsed,
        'not-new-user' => l10n.referralErrorNotNew,
        'no-profile' => l10n.referralErrorNoProfile,
        _ => l10n.referralErrorGeneric,
      };

  @override
  String toString() => 'ReferralException($reason)';
}

/// Referral codes are generated and validated server-side (callable Cloud
/// Functions) so uniqueness and the "once, new users only" rules hold.
class ReferralService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Returns the signed-in user's code, creating it on first call.
  Future<String> generateMyCode() async {
    final result = await _functions.httpsCallable('generateReferralCode').call();
    return (result.data as Map)['code'] as String;
  }

  /// Records who referred the signed-in user. Throws [ReferralException].
  Future<void> applyCode(String input) async {
    final code = normalizeReferralCode(input);
    if (!isValidReferralCode(code)) throw const ReferralException('invalid-format');
    try {
      await _functions.httpsCallable('applyReferralCode').call({'code': code});
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      final reason = details is Map ? details['reason'] as String? : null;
      throw ReferralException(reason ?? e.code);
    }
  }
}
