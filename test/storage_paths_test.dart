import 'package:flutter_test/flutter_test.dart';
import 'package:upendo_app/models/attachment_model.dart';
import 'package:upendo_app/models/chat_channel.dart';
import 'package:upendo_app/models/media_limits.dart';
import 'package:upendo_app/models/thread_scope.dart';
import 'package:upendo_app/services/attachment_service.dart';
import 'package:upendo_app/utils/storage_paths.dart';

// Upload folders must be authorisable by storage.rules WITHOUT a Firestore
// lookup (production denies those unless an extra IAM role is granted), so
// group uploads carry the uploader's uid and DMs rely on the
// "uidA_uidB" conversation id. Mirrors the paths exercised in
// functions/test/emulator/storage-rules.emulator.test.js.
void main() {
  group('upload folders (storage.rules)', () {
    test('group posts and chat files go in the uploader\'s own folder', () {
      expect(ThreadScope.group('g1', ownerId: 'o').storageFolder('p1', uploaderUid: 'bob'),
          'userGroups/g1/posts/p1/bob');
      expect(ChatChannel.group('g1', ownerId: 'o').storageFolder('m1', uploaderUid: 'bob'),
          'userGroups/g1/messages/m1/bob');
      expect(StoragePaths.groupItem('g1', 'posts', 'p1', 'bob'), 'userGroups/g1/posts/p1/bob');
    });

    test('group photo lives under the creator\'s uid (uploaded before the group doc)', () {
      expect(StoragePaths.groupPhoto('g1', 'own', '1.jpg'), 'userGroups/g1/photo/own/1.jpg');
    });

    test('1:1 chat files stay under conversations/{uidA_uidB}/{messageId}', () {
      expect(ChatChannel.conversation('a_b').storageFolder('m1', uploaderUid: 'a'),
          StoragePaths.conversationMessage('a_b', 'm1'));
    });

    test('wall and subcategory feeds are unchanged', () {
      expect(ThreadScope.wall.storageFolder('p1', uploaderUid: 'a'), 'threadPosts/p1');
      expect(ThreadScope.subcategory('c1').storageFolder('p1', uploaderUid: 'a'),
          'subcategoryFeeds/c1/posts/p1');
    });
  });

  group('MediaLimits.directMessage (1:1 inbox)', () {
    const dm = MediaLimits.directMessage;
    const mb = MediaLimits.megabyte;
    PendingAttachment file(String type) =>
        PendingAttachment(type: type, localPath: '/x', name: 'x', size: 1);

    test('images (≤5), video ≤5 min, PDF and audio ≤50 MB are all allowed', () {
      for (final t in [Attachment.image, Attachment.video, Attachment.pdf, Attachment.audio]) {
        expect(dm.allows(t), isTrue, reason: t);
      }
      expect(dm.imageRoom(const []), 5);
      expect(dm.check(type: Attachment.image, size: mb, current: List.generate(5, (_) => file(Attachment.image))),
          MediaRejection.tooManyImages);
      expect(dm.check(type: Attachment.video, size: mb, current: const [],
          videoDuration: const Duration(minutes: 5)), isNull);
      expect(dm.check(type: Attachment.video, size: mb, current: const [],
          videoDuration: const Duration(minutes: 6)), MediaRejection.videoTooLong);
      expect(dm.check(type: Attachment.pdf, size: 50 * mb, current: const []), isNull);
      expect(dm.check(type: Attachment.pdf, size: 50 * mb + 1, current: const []),
          MediaRejection.fileTooLarge);
      expect(dm.check(type: Attachment.audio, size: 51 * mb, current: const []),
          MediaRejection.fileTooLarge);
    });

    test('1:1 chat uses these limits', () {
      expect(identical(ChatChannel.conversation('a_b').limits, MediaLimits.directMessage), isTrue);
    });
  });

  test('upload content types satisfy storage.rules type checks', () {
    PendingAttachment f(String type, String name) =>
        PendingAttachment(type: type, localPath: '/x', name: name, size: 1);
    expect(AttachmentService.contentTypeFor(f(Attachment.pdf, 'a.pdf')), 'application/pdf');
    expect(AttachmentService.contentTypeFor(f(Attachment.image, 'a.HEIC')), 'image/heic');
    expect(AttachmentService.contentTypeFor(f(Attachment.video, 'a.mov')), 'video/quicktime');
    expect(AttachmentService.contentTypeFor(f(Attachment.audio, 'a.m4a')), 'audio/mp4');
  });
}
