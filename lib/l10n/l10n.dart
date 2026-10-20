import 'package:flutter/widgets.dart';

import '../services/locale_controller.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  /// UI strings for the language picked in Account → Language
  /// (see LocaleController). Only app chrome is translated — user and admin
  /// content (posts, category names, messages…) is shown as written.
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Same strings for code with no BuildContext at hand (e.g. timeAgo, share
/// text). Follows the currently selected language.
AppLocalizations get currentL10n =>
    lookupAppLocalizations(LocaleController.instance.locale);
