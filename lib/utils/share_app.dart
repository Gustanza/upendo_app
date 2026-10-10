import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

// Play Store listing for applicationId com.moyoapp.tanzania.
// TODO: add the App Store link here once the iOS app is published.
const kAppDownloadUrl =
    'https://play.google.com/store/apps/details?id=com.moyoapp.tanzania';

/// Opens the system share sheet (WhatsApp, Facebook, SMS, …) with an invite
/// message and the download link.
Future<void> shareApp(BuildContext context) {
  final box = context.findRenderObject() as RenderBox?;
  return SharePlus.instance.share(
    ShareParams(
      text: 'Jiunge nami kwenye Moyo App — jifunze, kua na upende! '
          'Pakua hapa: $kAppDownloadUrl',
      subject: 'Pakua Moyo App',
      // Required on iPad, where the share sheet is a popover.
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}
