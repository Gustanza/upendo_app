import 'package:cloud_firestore/cloud_firestore.dart';

/// A user-created group inside a subcategory (userGroups/{id}). Anyone can
/// create one; others join/leave. Members post (userGroups/{id}/posts) and
/// chat (userGroups/{id}/messages); the owner moderates. Membership lives
/// in userGroups/{id}/members/{uid} — firestore.rules checks it.
class UserGroup {
  final String id;
  final String subcategoryId;
  final String name;
  final String description;
  final String? photoUrl;
  final String ownerId;
  final String ownerName;
  // Maintained server-side by the updateGroupMemberCount Cloud Function.
  final int memberCount;
  final DateTime? createdAt;

  static const maxNameLength = 80;
  static const maxDescriptionLength = 500;

  UserGroup({
    required this.id,
    required this.subcategoryId,
    required this.name,
    required this.ownerId,
    this.description = '',
    this.photoUrl,
    this.ownerName = '',
    this.memberCount = 0,
    this.createdAt,
  });

  factory UserGroup.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? const {};
    return UserGroup(
      id: doc.id,
      subcategoryId: data['subcategoryId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      ownerId: data['ownerId'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  bool isOwner(String? uid) => uid != null && uid == ownerId;
}

class GroupMember {
  static const roleOwner = 'owner';
  static const roleMember = 'member';

  final String uid;
  final String name;
  final String role;
  final DateTime? joinedAt;

  GroupMember({
    required this.uid,
    required this.name,
    this.role = roleMember,
    this.joinedAt,
  });

  factory GroupMember.fromFirestore(String uid, Map<String, dynamic> data) {
    return GroupMember(
      uid: uid,
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? roleMember,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isOwner => role == roleOwner;
}
