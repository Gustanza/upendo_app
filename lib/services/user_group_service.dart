import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/attachment_model.dart';
import '../models/user_group_model.dart';
import '../utils/storage_paths.dart';
import 'attachment_service.dart';

/// User groups inside subcategories. Every rule that matters (only members
/// post/chat, only the owner edits/removes, removed members can't rejoin)
/// is enforced by firestore.rules/storage.rules — this class just performs
/// the writes those rules expect.
class UserGroupService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _groups => _db.collection('userGroups');

  CollectionReference<Map<String, dynamic>> _members(String groupId) =>
      _groups.doc(groupId).collection('members');

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<String> _myName() async {
    final doc = await _db.collection('users').doc(_uid).get();
    return (doc.data()?['fullName'] as String?) ?? '';
  }

  /// Newest first. Needs the (subcategoryId, createdAt desc) index in
  /// firestore.indexes.json.
  Stream<List<UserGroup>> watchGroups(String subcategoryId) {
    return _groups
        .where('subcategoryId', isEqualTo: subcategoryId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(UserGroup.fromFirestore).toList());
  }

  /// Emits null once the group is deleted.
  Stream<UserGroup?> watchGroup(String groupId) {
    return _groups.doc(groupId).snapshots().map(
          (doc) => doc.exists ? UserGroup.fromFirestore(doc) : null,
        );
  }

  Stream<bool> watchIsMember(String groupId) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(false);
    return _members(groupId).doc(uid).snapshots().map((d) => d.exists);
  }

  Stream<List<GroupMember>> watchMembers(String groupId) {
    return _members(groupId).orderBy('joinedAt').snapshots().map((snap) => snap.docs
        .map((d) => GroupMember.fromFirestore(d.id, d.data()))
        .toList());
  }

  /// Uploads the optional profile picture FIRST (into the creator's own
  /// folder — storage.rules needs no group doc for that), then creates the
  /// group with photoUrl/photoPath and its owner membership in one batch
  /// (the rules verify the owner member doc against the group being
  /// created). So either the whole group appears, picture included, or —
  /// if the upload fails — nothing is created and retrying is safe.
  ///
  /// Previously the group was written first and the picture uploaded after
  /// it, guarded by a Firestore owner lookup in storage.rules that
  /// production refused: the group appeared without a picture and the form
  /// showed a "[firebase_storage/unauthorized]" error.
  Future<String> createGroup({
    required String subcategoryId,
    required String name,
    required String description,
    PendingAttachment? photo,
  }) async {
    final myName = await _myName();
    final ref = _groups.doc();
    final photoFields = photo == null ? null : await _uploadPhoto(ref.id, photo);
    final batch = _db.batch()
      ..set(ref, {
        'subcategoryId': subcategoryId,
        'name': name.trim(),
        'description': description.trim(),
        'ownerId': _uid,
        'ownerName': myName,
        ...?photoFields,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      })
      ..set(_members(ref.id).doc(_uid), {
        'name': myName,
        'role': GroupMember.roleOwner,
        'joinedAt': FieldValue.serverTimestamp(),
      });
    await batch.commit();
    return ref.id;
  }

  Future<void> updateGroup(
    String groupId, {
    required String name,
    required String description,
    PendingAttachment? newPhoto,
  }) async {
    final photoFields = newPhoto == null ? null : await _uploadPhoto(groupId, newPhoto);
    await _groups.doc(groupId).update({
      'name': name.trim(),
      'description': description.trim(),
      ...?photoFields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // A fresh file name each time so cached copies of the old picture don't
  // linger; the previous file is removed with the group by cleanupUserGroup.
  // Returns the fields that make it the group's picture.
  Future<Map<String, Object>> _uploadPhoto(String groupId, PendingAttachment photo) async {
    final ext = photo.name.contains('.') ? photo.name.split('.').last.toLowerCase() : 'jpg';
    final path = StoragePaths.groupPhoto(
        groupId, _uid, '${DateTime.now().millisecondsSinceEpoch}.$ext');
    final ref = FirebaseStorage.instance.ref(path);
    await ref.putFile(
      File(photo.localPath),
      SettableMetadata(contentType: AttachmentService.contentTypeFor(photo)),
    );
    return {'photoUrl': await ref.getDownloadURL(), 'photoPath': path};
  }

  /// Owner (or admin) only. Posts, chat, members and Storage files are
  /// removed by the cleanupUserGroup Cloud Function.
  Future<void> deleteGroup(String groupId) => _groups.doc(groupId).delete();

  Future<void> join(String groupId) async {
    await _members(groupId).doc(_uid).set({
      'name': await _myName(),
      'role': GroupMember.roleMember,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  /// The owner can't leave their own group — they delete it instead.
  Future<void> leave(String groupId) => _members(groupId).doc(_uid).delete();

  /// Owner moderation: removes the member and records a ban so they can't
  /// immediately rejoin (firestore.rules checks bans/{uid} on join).
  Future<void> removeMember(String groupId, String memberUid) async {
    final batch = _db.batch()
      ..delete(_members(groupId).doc(memberUid))
      ..set(_groups.doc(groupId).collection('bans').doc(memberUid), {
        'bannedBy': _uid,
        'bannedAt': FieldValue.serverTimestamp(),
      });
    await batch.commit();
  }
}
