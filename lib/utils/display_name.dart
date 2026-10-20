import '../l10n/l10n.dart';

// Older builds stored this Swahili placeholder when a user had no name
// (authorName, senderName, participantNames…). New writes store '' instead.
const _legacyPlaceholder = 'Mtumiaji';

/// A stored person name ready for display: missing, blank or the legacy
/// placeholder become the localized "User" fallback.
String displayName(String? stored, AppLocalizations l10n) {
  final name = stored?.trim() ?? '';
  return name.isEmpty || name == _legacyPlaceholder ? l10n.userFallbackName : name;
}

/// First letter for an avatar.
String nameInitial(String name) => name.isNotEmpty ? name[0].toUpperCase() : '?';
