import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/l10n.dart';

// Play Store listing for applicationId com.moyoapp.tanzania.
// TODO: add the App Store link here once the iOS app is published.
const kAppDownloadUrl =
    'https://play.google.com/store/apps/details?id=com.moyoapp.tanzania';

/// Opens the system share sheet (WhatsApp, Facebook, SMS, …) with an invite
/// message and the download link.
Future<void> shareApp(BuildContext context) {
  final l10n = context.l10n;
  return _share(
    context,
    text: l10n.shareAppText(kAppDownloadUrl),
    subject: l10n.shareAppSubject,
  );
}

/// Same share sheet, but the invite carries the user's referral code so the
/// friend can enter it during profile setup (see ProfileSetupScreen).
Future<void> shareReferralCode(BuildContext context, String code) {
  final l10n = context.l10n;
  return _share(
    context,
    text: l10n.shareReferralText(code, kAppDownloadUrl),
    subject: l10n.shareAppSubject,
  );
}

Future<void> _share(
  BuildContext context, {
  required String text,
  required String subject,
}) {
  final box = context.findRenderObject() as RenderBox?;
  return SharePlus.instance.share(
    ShareParams(
      text: text,
      subject: subject,
      // Required on iPad, where the share sheet is a popover.
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}
