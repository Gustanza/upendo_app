import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upendo_app/l10n/app_localizations.dart';
import 'package:upendo_app/models/thread_post_model.dart';
import 'package:upendo_app/utils/display_name.dart';

void main() {
  test('missing, blank and legacy "Mtumiaji" names show the localized fallback', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final fr = lookupAppLocalizations(const Locale('fr'));
    final sw = lookupAppLocalizations(const Locale('sw'));
    expect(displayName(null, en), 'User');
    expect(displayName('  ', fr), 'Utilisateur');
    expect(displayName('Mtumiaji', en), 'User');
    expect(displayName('', sw), 'Mtumiaji');
    expect(displayName(' Asha ', en), 'Asha');
    expect(nameInitial('asha'), 'A');
    expect(nameInitial(''), '?');
  });

  test('models no longer invent a Swahili placeholder for missing names', () {
    expect(ThreadPostModel(id: 'p', authorId: 'a', authorName: '', text: '').authorName, '');
  });
}
