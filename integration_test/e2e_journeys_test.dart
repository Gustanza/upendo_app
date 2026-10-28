// TEST-ONLY on-device E2E against the LOCAL Firebase emulators.
//
//   1. start emulators:  firebase emulators:start --only auth,firestore,storage,functions
//                        --project moyoapptanzania-cf0e7   (see integration_test/README in run script)
//   2. seed:             node functions/test/device/seed-device-e2e.js  (emulator env vars set)
//   3. run:              bash integration_test/run_device_e2e.sh
//                        (= flutter test integration_test/e2e_journeys_test.dart -d emulator-5554
//                           --dart-define=USE_FIREBASE_EMULATORS=true, screenshots on "SHOT:" lines)
//
// Native pickers can't be driven here, so uploads call the same service
// methods the UI calls (ConversationService.sendTo, ThreadPostService.
// createPost, UserGroupService.createGroup) with generated files
// (integration_test/fixtures.dart), and the real screens are pumped to
// check they render the result. Any FlutterError (overflow, image load
// failure, exception in build) fails the test via the binding.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:upendo_app/dev/emulator_harness.dart';
import 'package:upendo_app/firebase_options.dart';
import 'package:upendo_app/l10n/app_localizations.dart';
import 'package:upendo_app/main.dart';
import 'package:upendo_app/models/attachment_model.dart';
import 'package:upendo_app/models/category_model.dart';
import 'package:upendo_app/models/chat_channel.dart';
import 'package:upendo_app/models/thread_scope.dart';
import 'package:upendo_app/services/conversation_service.dart';
import 'package:upendo_app/services/locale_controller.dart';
import 'package:upendo_app/services/referral_service.dart';
import 'package:upendo_app/services/thread_post_service.dart';
import 'package:upendo_app/services/user_group_service.dart';
import 'package:upendo_app/services/user_preferences.dart';
import 'package:upendo_app/views/account_fragment.dart';
import 'package:upendo_app/views/conversation_screen.dart';
import 'package:upendo_app/views/conversations_screen.dart';
import 'package:upendo_app/views/subcategory_hub_screen.dart';
import 'package:upendo_app/views/user_group_screen.dart';
import 'package:upendo_app/views/user_groups_tab.dart';
import 'package:upendo_app/widgets/thread_feed.dart';

import 'fixtures.dart';

const password = 'secret123';
const emailA = 'alice@test.moyo';
const emailB = 'bob@test.moyo';
const emailC = 'carol@test.moyo';

final uids = <String, String>{};
final db = FirebaseFirestore.instance;
final sub = Category(id: 'cat-sub', name: 'E2E Sub', parentId: 'cat-main', colorHex: 0xFF1565C0);
final mainCat = Category(id: 'cat-main', name: 'E2E Main', colorHex: 0xFF8B2942);
final results = <String>[];
final runTag = DateTime.now().millisecondsSinceEpoch.toString();

AppLocalizations l10nFor(String code) => lookupAppLocalizations(Locale(code));

Future<void> signIn(String email) async {
  await FirebaseAuth.instance.signOut();
  final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
  uids[email] = cred.user!.uid;
}

Future<PendingAttachment> fixture(String type, String name, String b64) async {
  final f = File('${Directory.systemTemp.path}/e2e_$name');
  await f.writeAsBytes(base64Decode(b64));
  return PendingAttachment(type: type, localPath: f.path, name: name, size: await f.length());
}

Future<void> wait(WidgetTester t, [int ms = 1000]) async {
  final end = DateTime.now().add(Duration(milliseconds: ms));
  while (DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await t.pump();
  }
}

Future<void> waitFor(WidgetTester t, Finder f, {int seconds = 25, String? why}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await t.pump();
    if (f.evaluate().isNotEmpty) return;
  }
  fail('timed out waiting for ${why ?? f}');
}

Future<void> waitGone(WidgetTester t, Finder f, {int seconds = 15}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(end)) {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await t.pump();
    if (f.evaluate().isEmpty) return;
  }
  fail('still showing $f');
}

Future<void> show(WidgetTester t, Widget home) async {
  await t.pumpWidget(NguvuYaUpendoApp(key: UniqueKey(), home: home));
  await wait(t, 600);
}

/// The host script (run_device_e2e.sh) takes an adb screenshot on this line.
Future<void> shot(WidgetTester t, String name) async {
  await wait(t, 1500); // let network images paint
  // ignore: avoid_print
  print('SHOT:$name');
  await wait(t, 2500); // hold the frame while adb captures
}

Future<String> expectDenied(String what, Future<void> Function() action) async {
  try {
    await action();
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied' || e.code == 'unauthorized') {
      results.add('DENIED as expected: $what (${e.plugin}/${e.code})');
      return e.code;
    }
    fail('$what: expected a permission error, got ${e.plugin}/${e.code}: ${e.message}');
  }
  fail('$what: expected permission error, but it SUCCEEDED');
}

/// Downloads [url] on the device and decodes it as an image (proves the
/// download URL works over the debug cleartext config and is a real image).
Future<ui.Size> fetchImage(String url) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse(url));
    final res = await req.close();
    expect(res.statusCode, 200, reason: url);
    final bytes = await res.fold<List<int>>(<int>[], (a, b) => a..addAll(b));
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
    final frame = await codec.getNextFrame();
    return ui.Size(frame.image.width.toDouble(), frame.image.height.toDouble());
  } finally {
    client.close();
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  setUpAll(() async {
    expect(kUsingFirebaseEmulators, isTrue,
        reason: 'run with --dart-define=USE_FIREBASE_EMULATORS=true (debug build)');
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await connectFirebaseEmulatorsIfRequested();
    await LocaleController.instance.setLanguage('sw');
    for (final e in [emailA, emailB, emailC]) {
      await signIn(e);
    }
  });

  tearDownAll(() {
    for (final r in results) {
      // ignore: avoid_print
      print('RESULT: $r');
    }
  });

  // ── Journey 1: 1:1 chat with text, image, PDF, video, audio ──────────
  testWidgets('J1 private chat: media, delete-for-me, reappear', (t) async {
    final a = uids[emailA]!, b = uids[emailB]!;
    final svc = ConversationService();
    await signIn(emailA);
    final convId = await svc.getOrCreateConversation(otherUid: b, otherName: 'Bob Tester');
    expect(convId, ([a, b]..sort()).join('_'));

    await svc.sendMessage(convId, 'Hello Bob from Alice $runTag');
    await svc.sendMessage(convId, 'Photo and PDF', attachments: [
      await fixture(Attachment.image, 'photo.jpg', jpegB64),
      await fixture(Attachment.pdf, 'notes.pdf', pdfB64),
    ]);
    await svc.sendMessage(convId, 'Video and audio', attachments: [
      await fixture(Attachment.video, 'clip.mp4', mp4B64),
      await fixture(Attachment.audio, 'voice.wav', wavB64),
    ]);
    final msgs = await db.collection('conversations/$convId/messages').get();
    final withFiles = msgs.docs.where((d) => (d.data()['attachments'] as List?)?.isNotEmpty ?? false).toList();
    expect(withFiles.length, greaterThanOrEqualTo(2));
    String? photoPath, photoUrl;
    for (final d in withFiles) {
      for (final att in Attachment.listFrom(d.data()['attachments'])) {
        expect(att.path, startsWith('conversations/$convId/${d.id}/'));
        if (att.name == 'photo.jpg') {
          photoPath = att.path;
          photoUrl = att.url;
        }
      }
    }
    expect(photoPath, isNotNull);
    results.add('J1 A sent text+jpg+pdf+mp4+wav; paths under conversations/$convId/{msgId}/');
    final size = await fetchImage(photoUrl!);
    expect(size.width, 160);

    await show(t, ConversationScreen(conversationId: convId, otherName: 'Bob Tester'));
    await waitFor(t, find.text('Hello Bob from Alice $runTag'));
    await waitFor(t, find.text('notes.pdf'), why: 'PDF tile');
    expect(find.byType(Image), findsWidgets);
    await shot(t, 'j1_dm_alice_sent_media');

    // Outsider C: can't read the files or the messages, can't upload there.
    await signIn(emailC);
    await expectDenied('C reads A↔B DM photo via SDK', () => FirebaseStorage.instance.ref(photoPath!).getData());
    await expectDenied('C uploads into A↔B DM folder',
        () => FirebaseStorage.instance.ref('conversations/$convId/x/evil.jpg')
            .putData(base64Decode(jpegB64), SettableMetadata(contentType: 'image/jpeg')));
    await expectDenied('C reads A↔B messages', () => db.collection('conversations/$convId/messages').get());

    // B sees everything.
    await signIn(emailB);
    final bytes = await FirebaseStorage.instance.ref(photoPath!).getData();
    expect(bytes, isNotNull);
    results.add('J1 B (participant) reads the DM photo via SDK: ${bytes!.length} bytes');
    await show(t, const ConversationsScreen());
    await waitFor(t, find.text('Alice Tester'));
    await shot(t, 'j1_dm_bob_inbox');
    await show(t, ConversationScreen(conversationId: convId, otherName: 'Alice Tester'));
    await waitFor(t, find.text('Hello Bob from Alice $runTag'));
    await waitFor(t, find.text('notes.pdf'));
    await shot(t, 'j1_dm_bob_sees_media');

    // A deletes the chat for herself.
    await signIn(emailA);
    await svc.deleteConversationForMe(convId);
    await show(t, const ConversationsScreen());
    await wait(t, 3000);
    expect(find.text('Bob Tester'), findsNothing, reason: 'deleted chat must be hidden for A');
    await shot(t, 'j1_dm_alice_after_delete');

    // B unaffected.
    await signIn(emailB);
    await show(t, const ConversationsScreen());
    await waitFor(t, find.text('Alice Tester'));
    final bView = await svc.watchMessages(ChatChannel.conversation(convId)).first;
    expect(bView.length, greaterThanOrEqualTo(3));
    await svc.sendMessage(convId, 'Bob is back $runTag');
    results.add('J1 B still sees ${bView.length} messages after A deleted; B replied');

    // A: the chat reappears (once notifyConversationMessage bumps updatedAt)
    // with only the new message.
    await signIn(emailA);
    await show(t, const ConversationsScreen());
    await waitFor(t, find.text('Bob Tester'), seconds: 40, why: 'chat reappears for A (needs functions emulator)');
    await shot(t, 'j1_dm_alice_reappeared');
    await show(t, ConversationScreen(conversationId: convId, otherName: 'Bob Tester'));
    await waitFor(t, find.text('Bob is back $runTag'));
    expect(find.text('Hello Bob from Alice $runTag'), findsNothing, reason: 'old messages stay hidden for A');
    expect(find.text('notes.pdf'), findsNothing);
    await shot(t, 'j1_dm_alice_only_new_message');
    results.add('J1 PASS');
  });

  // ── Journey 2: user group with photo; membership gates posting ────────
  testWidgets('J2 user group: photo, join gate, media posts, removal', (t) async {
    final a = uids[emailA]!, b = uids[emailB]!;
    final groups = UserGroupService();
    await signIn(emailA);
    final groupName = 'E2E Photo Group $runTag';
    final groupId = await groups.createGroup(
      subcategoryId: 'cat-sub',
      name: groupName,
      description: 'Created by the on-device E2E',
      photo: await fixture(Attachment.image, 'group.png', pngB64),
    );
    final g = (await db.doc('userGroups/$groupId').get()).data()!;
    expect(g['photoPath'], startsWith('userGroups/$groupId/photo/$a/'));
    final photoUrl = g['photoUrl'] as String;
    expect((await fetchImage(photoUrl)).width, 160);
    expect((await db.doc('userGroups/$groupId/members/$a').get()).exists, isTrue);
    results.add('J2 group created with photo at ${g['photoPath']} + owner membership');

    await show(t, Scaffold(body: UserGroupsTab(subcategory: sub)));
    await waitFor(t, find.text(groupName));
    final avatar = t.widget<CircleAvatar>(find.descendant(
        of: find.ancestor(of: find.text(groupName), matching: find.byType(ListTile)).first,
        matching: find.byType(CircleAvatar)));
    expect((avatar.backgroundImage as NetworkImage).url, photoUrl);
    await shot(t, 'j2_group_list_with_photo');
    await show(t, UserGroupScreen(groupId: groupId));
    await waitFor(t, find.text(groupName));
    expect(find.byWidgetPredicate((w) => w is CircleAvatar && w.backgroundImage is NetworkImage
        && (w.backgroundImage as NetworkImage).url == photoUrl), findsWidgets);
    await shot(t, 'j2_group_header_owner');

    // Owner can't point the picture at someone else's folder.
    await expectDenied('A sets group photoPath to B\'s folder',
        () => db.doc('userGroups/$groupId').update({'photoPath': 'userGroups/$groupId/photo/$b/x.png', 'photoUrl': photoUrl}));

    // B (not a member) can't post or chat.
    await signIn(emailB);
    final bPosts = ThreadPostService(scope: ThreadScope.group(groupId, ownerId: a));
    final bChat = ChatChannel.group(groupId, ownerId: a);
    await expectDenied('non-member B posts in group', () => bPosts.createPost(text: 'sneaky'));
    await expectDenied('non-member B posts in group with own uploads',
        () async => bPosts.createPost(text: 'sneaky media', attachments: [
              // upload into B's own folder succeeds (by design); the doc write is denied
              await fixture(Attachment.image, 'sneaky.jpg', jpegB64),
            ]));
    await expectDenied('non-member B chats in group',
        () => ConversationService().sendTo(bChat, 'sneaky chat'));
    // Upload into B's own folder IS allowed (by design), but a message
    // referencing it is still refused for a non-member.
    final ownPath = 'userGroups/$groupId/messages/m-$runTag/$b/0_x.jpg';
    await FirebaseStorage.instance.ref(ownPath).putData(base64Decode(jpegB64), SettableMetadata(contentType: 'image/jpeg'));
    await expectDenied('non-member B writes a message referencing own upload',
        () => db.doc('userGroups/$groupId/messages/m-$runTag').set({
              'senderId': b, 'senderName': 'Bob Tester', 'text': '', 'createdAt': FieldValue.serverTimestamp(), 'type': 'text',
              'attachments': [{'type': 'image', 'url': 'x', 'path': ownPath}],
            }));
    await expectDenied('B uploads into A\'s uid folder (forged)',
        () => FirebaseStorage.instance.ref('userGroups/$groupId/posts/p-$runTag/$a/0_x.jpg')
            .putData(base64Decode(jpegB64), SettableMetadata(contentType: 'image/jpeg')));
    await show(t, UserGroupScreen(groupId: groupId));
    await waitFor(t, find.text(l10nFor('sw').joinToSeePosts));
    await shot(t, 'j2_group_nonmember_view');

    // B joins and posts media.
    await groups.join(groupId);
    await bPosts.createPost(text: 'Bob group post $runTag', attachments: [
      await fixture(Attachment.image, 'gpost.jpg', jpegB64),
      await fixture(Attachment.pdf, 'gdoc.pdf', pdfB64),
      await fixture(Attachment.audio, 'gvoice.wav', wavB64),
    ]);
    await ConversationService().sendTo(bChat, 'Bob group chat $runTag', attachments: [
      await fixture(Attachment.image, 'gchat.jpg', jpegB64),
      await fixture(Attachment.pdf, 'gchat.pdf', pdfB64),
    ]);
    final post = (await db.collection('userGroups/$groupId/posts').where('authorId', isEqualTo: b).get()).docs.single;
    for (final att in Attachment.listFrom(post.data()['attachments'])) {
      expect(att.path, startsWith('userGroups/$groupId/posts/${post.id}/$b/'));
    }
    results.add('J2 B joined and posted jpg+pdf+wav (post) and jpg+pdf (chat) under uploader folders');
    await show(t, UserGroupScreen(groupId: groupId));
    await waitFor(t, find.text('Bob group post $runTag'));
    await waitFor(t, find.text('gdoc.pdf'));
    await shot(t, 'j2_group_member_posts');
    await t.tap(find.text(l10nFor('sw').tabChat));
    await waitFor(t, find.text('Bob group chat $runTag'));
    await waitFor(t, find.text('gchat.pdf'));
    await shot(t, 'j2_group_member_chat');

    // Owner removes B.
    await signIn(emailA);
    await show(t, UserGroupScreen(groupId: groupId));
    await waitFor(t, find.text('Bob group post $runTag'), why: 'owner sees member post');
    await groups.removeMember(groupId, b);
    await signIn(emailB);
    await expectDenied('removed B posts again', () => bPosts.createPost(text: 'after removal'));
    await expectDenied('removed B rejoins (banned)', () => groups.join(groupId));
    await show(t, UserGroupScreen(groupId: groupId));
    await waitFor(t, find.text(l10nFor('sw').joinToSeePosts));
    await shot(t, 'j2_group_removed_member');
    results.add('J2 PASS');
  });

  // ── Journey 3: subcategory Topics + community feeds ──────────────────
  testWidgets('J3 subcategory Topics shows sub + main posts; community image posts', (t) async {
    await signIn(emailA);
    await show(t, SubcategoryHubScreen(category: sub));
    await waitFor(t, find.text('Subcategory topic'));
    await waitFor(t, find.text('Main category topic'));
    await waitFor(t, find.text('Legacy sub topic'));
    expect(find.text('Unrelated topic'), findsNothing);
    final ySub = t.getTopLeft(find.text('Subcategory topic')).dy;
    final yMain = t.getTopLeft(find.text('Main category topic')).dy;
    expect(ySub < yMain, isTrue, reason: 'own posts first');
    await shot(t, 'j3_topics_tab_sub_and_main');

    await ThreadPostService(scope: ThreadScope.subcategory('cat-sub')).createPost(
      text: 'Community image post $runTag',
      attachments: [await fixture(Attachment.image, 'community.jpg', jpegB64)],
    );
    await t.tap(find.text(l10nFor('sw').tabCommunity));
    await waitFor(t, find.text('Community image post $runTag'));
    expect(find.byType(Image), findsWidgets);
    await shot(t, 'j3_subcategory_community_image');

    await ThreadPostService().createPost(
      text: 'Wall image post $runTag',
      attachments: [await fixture(Attachment.image, 'wall.jpg', jpegB64)],
    );
    await show(t, const Scaffold(body: ThreadFeed()));
    await waitFor(t, find.text('Wall image post $runTag'));
    await shot(t, 'j3_wall_feed_image');
    results.add('J3 PASS');
  });

  // ── Journey 4: language switch persists ──────────────────────────────
  testWidgets('J4 language switch en / fr', (t) async {
    await signIn(emailA);
    final en = l10nFor('en'), fr = l10nFor('fr'), sw = l10nFor('sw');
    expect({en.tabTopics, fr.tabTopics, sw.tabTopics}.length, 3, reason: 'Topics tab translated in all 3');
    await LocaleController.instance.setLanguage('en');
    await show(t, SubcategoryHubScreen(category: sub));
    await waitFor(t, find.text(en.tabTopics));
    expect(find.text(en.tabGroups), findsOneWidget);
    await shot(t, 'j4_hub_english');
    await show(t, const AccountFragment());
    await wait(t, 2000);
    await shot(t, 'j4_account_english');
    await LocaleController.instance.setLanguage('fr');
    await show(t, SubcategoryHubScreen(category: sub));
    await waitFor(t, find.text(fr.tabTopics));
    expect(find.text(en.tabTopics), findsNothing);
    await shot(t, 'j4_hub_french');
    expect(await UserPreferences().getLanguageCode(), 'fr');
    // Simulated restart: a fresh load reads the persisted choice.
    await LocaleController.instance.load();
    expect(LocaleController.instance.value.languageCode, 'fr');
    results.add('J4 PASS (persisted code=fr in SharedPreferences)');
  });

  // ── Journey 5: referral code callable on the functions emulator ──────
  testWidgets('J5 referral code', (t) async {
    await signIn(emailA);
    final code = await ReferralService().generateMyCode();
    expect(code, isNotEmpty);
    expect(await ReferralService().generateMyCode(), code, reason: 'idempotent');
    results.add('J5 A referral code = $code');
    await signIn(emailC);
    try {
      await ReferralService().applyCode(code);
      results.add('J5 C applied A\'s code');
    } on ReferralException catch (e) {
      results.add('J5 C applyCode refused: ${e.reason} (seeded users are not "new")');
    }
    await signIn(emailA);
    await LocaleController.instance.setLanguage('en');
    await show(t, const AccountFragment());
    await waitFor(t, find.textContaining(code), seconds: 20, why: 'code on Account screen');
    await shot(t, 'j5_account_referral_code');
    await LocaleController.instance.setLanguage('fr'); // left as fr for the restart check
    results.add('J5 PASS');
  });
}
