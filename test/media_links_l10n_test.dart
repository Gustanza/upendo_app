import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:upendo_app/l10n/app_localizations.dart';
import 'package:upendo_app/models/attachment_model.dart';
import 'package:upendo_app/models/chat_channel.dart';
import 'package:upendo_app/models/media_limits.dart';
import 'package:upendo_app/models/thread_scope.dart';
import 'package:upendo_app/services/locale_controller.dart';
import 'package:upendo_app/utils/links.dart';

PendingAttachment _file(String type, {int size = 1000}) =>
    PendingAttachment(type: type, localPath: '/tmp/x', name: 'x', size: size);

void main() {
  group('MediaLimits.community (subcategory & group posts)', () {
    const limits = MediaLimits.community;
    const mb = MediaLimits.megabyte;

    test('video must be ≤ 5 minutes, one per post', () {
      expect(limits.check(type: Attachment.video, size: mb, current: const [],
          videoDuration: const Duration(minutes: 5)), isNull);
      expect(limits.check(type: Attachment.video, size: mb, current: const [],
          videoDuration: const Duration(minutes: 5, seconds: 1)), MediaRejection.videoTooLong);
      expect(limits.check(type: Attachment.video, size: mb, current: const [],
          videoDuration: null), MediaRejection.videoTooLong);
      expect(limits.check(type: Attachment.video, size: mb, current: [_file(Attachment.video)],
          videoDuration: const Duration(minutes: 1)), MediaRejection.oneVideoOnly);
    });

    test('up to 5 images in one post', () {
      final four = List.generate(4, (_) => _file(Attachment.image));
      expect(limits.imageRoom(four), 1);
      expect(limits.check(type: Attachment.image, size: mb, current: four), isNull);
      final five = [...four, _file(Attachment.image)];
      expect(limits.check(type: Attachment.image, size: mb, current: five),
          MediaRejection.tooManyImages);
    });

    test('PDF and audio capped at 50 MB each', () {
      expect(limits.check(type: Attachment.pdf, size: 50 * mb, current: const []), isNull);
      expect(limits.check(type: Attachment.pdf, size: 50 * mb + 1, current: const []),
          MediaRejection.fileTooLarge);
      expect(limits.check(type: Attachment.audio, size: 10 * mb, current: const []), isNull);
      expect(limits.check(type: Attachment.audio, size: 51 * mb, current: const []),
          MediaRejection.fileTooLarge);
    });

    test('total attachments capped at 10 (matches firestore.rules)', () {
      final ten = List.generate(10, (_) => _file(Attachment.pdf));
      expect(limits.check(type: Attachment.pdf, size: 1, current: ten),
          MediaRejection.tooManyAttachments);
    });
  });

  test('community wall keeps its original rules (10-min video, no PDF/audio)', () {
    const wall = MediaLimits.wall;
    expect(wall.check(type: Attachment.video, size: 1, current: const [],
        videoDuration: const Duration(minutes: 9)), isNull);
    expect(wall.check(type: Attachment.pdf, size: 1, current: const []),
        MediaRejection.typeNotAllowed);
    expect(wall.check(type: Attachment.audio, size: 1, current: const []),
        MediaRejection.typeNotAllowed);
  });

  group('scopes and channels', () {
    test('paths match firestore.rules / storage.rules', () {
      expect(ThreadScope.wall.postsPath, 'threadPosts');
      expect(ThreadScope.subcategory('c1').postsPath, 'subcategoryFeeds/c1/posts');
      final g = ThreadScope.group('g1', ownerId: 'owner');
      expect(g.postsPath, 'userGroups/g1/posts');
      expect(g.allowLinks, isTrue);
      expect(ChatChannel.conversation('a_b').storageFolder('m1', uploaderUid: 'a'),
          'conversations/a_b/m1');
      expect(ChatChannel.subcategory('c1').storageFolder('m1', uploaderUid: 'a'),
          'subcategoryFeeds/c1/messages/m1');
      expect(ChatChannel.group('g1', ownerId: 'o').messagesPath, 'userGroups/g1/messages');
    });

    test('group owner moderates; members delete only their own', () {
      final scope = ThreadScope.group('g1', ownerId: 'owner');
      expect(scope.canDelete(authorId: 'alice', myUid: 'owner'), isTrue);
      expect(scope.canDelete(authorId: 'alice', myUid: 'alice'), isTrue);
      expect(scope.canDelete(authorId: 'alice', myUid: 'bob'), isFalse);
      expect(ThreadScope.wall.canDelete(authorId: 'alice', myUid: 'owner'), isFalse);
      final room = ChatChannel.group('g1', ownerId: 'owner');
      expect(room.canDelete(senderId: 'alice', myUid: 'owner'), isTrue);
      expect(room.canDelete(senderId: 'alice', myUid: 'bob'), isFalse);
      expect(ChatChannel.conversation('a_b').canDelete(senderId: 'a', myUid: 'a'), isFalse);
    });
  });

  group('links', () {
    test('normalizeUrl accepts http(s)/www and rejects junk', () {
      expect(normalizeUrl('www.example.com').toString(), 'https://www.example.com');
      expect(normalizeUrl('https://x.co/a?b=1').toString(), 'https://x.co/a?b=1');
      expect(normalizeUrl('ftp://x.co'), isNull);
      expect(normalizeUrl('not a url'), isNull);
      expect(normalizeUrl('localhost'), isNull);
      expect(normalizeUrl('javascript:alert(1)'), isNull);
    });

    test('splitLinks finds URLs and drops trailing punctuation', () {
      final s = splitLinks('Soma https://moyo.app/x. Pia www.example.com, sawa!');
      expect(s.where((e) => e.isLink).map((e) => e.text), ['https://moyo.app/x', 'www.example.com']);
      expect(s.map((e) => e.text).join(), 'Soma https://moyo.app/x. Pia www.example.com, sawa!');
      expect(splitLinks('hakuna kiungo').single.isLink, isFalse);
    });

    test('parseLinkMetadata reads OpenGraph tags and falls back to <title>', () {
      final page = Uri.parse('https://example.com/post');
      final og = parseLinkMetadata(
        '<head><meta property="og:title" content="Habari &amp; Mafunzo">'
        '<meta property="og:image" content="/img.png"><title>ignored</title></head>',
        page,
      );
      expect(og.title, 'Habari & Mafunzo');
      expect(og.imageUrl, 'https://example.com/img.png');
      final plain = parseLinkMetadata('<title> Plain </title>', page);
      expect(plain.title, 'Plain');
      expect(plain.imageUrl, isNull);
    });
  });

  group('localization', () {
    test('Swahili is the default; unknown codes fall back to it', () {
      expect(LocaleController.defaultLocale, const Locale('sw'));
      expect(LocaleController.resolve(null), const Locale('sw'));
      expect(LocaleController.resolve('de'), const Locale('sw'));
      expect(LocaleController.resolve('fr'), const Locale('fr'));
    });

    test('all three languages are supported and translated', () {
      expect(AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
          {'sw', 'en', 'fr'});
      final sw = lookupAppLocalizations(const Locale('sw'));
      final en = lookupAppLocalizations(const Locale('en'));
      final fr = lookupAppLocalizations(const Locale('fr'));
      expect(sw.navAccount, 'Akaunti');
      expect(en.navAccount, 'Account');
      expect(fr.navAccount, 'Compte');
      expect(en.membersCount(1), '1 member');
      expect(en.membersCount(3), '3 members');
      expect(fr.withdrawMinimum('TZS 10,000'), contains('TZS 10,000'));
    });
  });
}
