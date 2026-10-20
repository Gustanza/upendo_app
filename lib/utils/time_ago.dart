import '../l10n/l10n.dart';

// No BuildContext here (called from many list tiles), so it reads the
// currently selected UI language via currentL10n.
String timeAgo(DateTime? dateTime) {
  if (dateTime == null) return '';
  final l10n = currentL10n;
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 60) return l10n.timeJustNow;
  if (diff.inMinutes < 60) return l10n.timeMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHours(diff.inHours);
  if (diff.inDays < 7) return l10n.timeDays(diff.inDays);
  return l10n.timeWeeks((diff.inDays / 7).floor());
}
