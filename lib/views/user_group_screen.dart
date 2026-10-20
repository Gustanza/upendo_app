import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/chat_channel.dart';
import '../models/thread_scope.dart';
import '../models/user_group_model.dart';
import '../services/user_group_service.dart';
import '../utils/display_name.dart';
import '../utils/time_ago.dart';
import '../widgets/chat_room_view.dart';
import '../widgets/thread_feed.dart';
import 'user_group_form_screen.dart';
import 'user_groups_tab.dart';

/// A user group: header with join/leave, then (for members) its posts,
/// chat and member list. Non-members only see the description — posts and
/// chat are members-only in firestore.rules.
class UserGroupScreen extends StatefulWidget {
  final String groupId;
  const UserGroupScreen({super.key, required this.groupId});

  @override
  State<UserGroupScreen> createState() => _UserGroupScreenState();
}

class _UserGroupScreenState extends State<UserGroupScreen> {
  final UserGroupService _service = UserGroupService();
  late final Stream<UserGroup?> _group = _service.watchGroup(widget.groupId);
  late final Stream<bool> _isMember = _service.watchIsMember(widget.groupId);
  bool _busy = false;

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) _snack(context.l10n.errorWithDetails('$e'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String body, String action) async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _join(UserGroup group) async {
    setState(() => _busy = true);
    try {
      await _service.join(group.id);
    } catch (_) {
      // Most likely the owner removed this user (bans/{uid} blocks rejoining).
      if (mounted) _snack(context.l10n.joinGroupFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    final l10n = context.l10n;
    if (!await _confirm(l10n.leaveGroupTitle, l10n.leaveGroupBody, l10n.leaveGroup)) return;
    await _run(() => _service.leave(widget.groupId));
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    if (!await _confirm(l10n.deleteGroupTitle, l10n.deleteGroupBody, l10n.delete)) return;
    await _run(() => _service.deleteGroup(widget.groupId));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _edit(UserGroup group) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserGroupFormScreen(subcategoryId: group.subcategoryId, existing: group),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return StreamBuilder<UserGroup?>(
      stream: _group,
      builder: (context, groupSnap) {
        if (groupSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final group = groupSnap.data;
        if (group == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.groupNotFound)),
          );
        }
        final isOwner = group.isOwner(uid);
        return StreamBuilder<bool>(
          stream: _isMember,
          builder: (context, memberSnap) {
            final isMember = memberSnap.data ?? false;
            return DefaultTabController(
              length: 3,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(group.name, overflow: TextOverflow.ellipsis),
                  actions: [
                    if (isOwner)
                      PopupMenuButton<String>(
                        onSelected: (v) => v == 'edit' ? _edit(group) : _delete(),
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'edit', child: Text(l10n.editGroup)),
                          PopupMenuItem(value: 'delete', child: Text(l10n.deleteGroup)),
                        ],
                      ),
                  ],
                  bottom: isMember
                      ? TabBar(
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white70,
                          indicatorColor: Colors.white,
                          tabs: [
                            Tab(text: l10n.tabPosts),
                            Tab(text: l10n.tabChat),
                            Tab(text: l10n.tabMembers),
                          ],
                        )
                      : null,
                ),
                body: isMember
                    ? Column(
                        children: [
                          _Header(group: group, compact: true, trailing: _membershipButton(group, isMember, isOwner)),
                          Expanded(
                            child: TabBarView(
                              children: [
                                ThreadFeed(scope: ThreadScope.group(group.id, ownerId: group.ownerId)),
                                ChatRoomView(channel: ChatChannel.group(group.id, ownerId: group.ownerId)),
                                _MembersList(group: group, isOwner: isOwner),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        children: [
                          _Header(group: group, trailing: _membershipButton(group, isMember, isOwner)),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              l10n.joinToSeePosts,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _membershipButton(UserGroup group, bool isMember, bool isOwner) {
    final l10n = context.l10n;
    if (isOwner) {
      return Chip(
        avatar: const Icon(Icons.star_rounded, size: 16, color: Color(0xFF8B2942)),
        label: Text(l10n.groupOwner),
      );
    }
    if (isMember) {
      return OutlinedButton(
        onPressed: _busy ? null : _leave,
        child: Text(l10n.leaveGroup),
      );
    }
    return ElevatedButton(
      onPressed: _busy ? null : () => _join(group),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8B2942),
        foregroundColor: Colors.white,
      ),
      child: Text(l10n.joinGroup),
    );
  }
}

class _Header extends StatelessWidget {
  final UserGroup group;
  final Widget trailing;
  final bool compact;
  const _Header({required this.group, required this.trailing, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      color: const Color(0xFFFBF4F6),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GroupAvatar(group: group, radius: compact ? 22 : 34),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text(
                      l10n.membersCount(group.memberCount),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF8B2942)),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
          if (!compact && group.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(group.description, style: const TextStyle(height: 1.4)),
          ],
          if (!compact) ...[
            const SizedBox(height: 8),
            Text(
              l10n.groupCreatedBy(displayName(group.ownerName, l10n)),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}

class _MembersList extends StatelessWidget {
  final UserGroup group;
  final bool isOwner;
  const _MembersList({required this.group, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final service = UserGroupService();
    return StreamBuilder<List<GroupMember>>(
      stream: service.watchMembers(group.id),
      builder: (context, snapshot) {
        final members = snapshot.data ?? const <GroupMember>[];
        if (snapshot.connectionState == ConnectionState.waiting && members.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: members.length,
          separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
          itemBuilder: (context, i) {
            final m = members[i];
            final name = displayName(m.name, l10n);
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFF3E3E7),
                child: Text(
                  nameInitial(name),
                  style: const TextStyle(color: Color(0xFF8B2942), fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(name),
              subtitle: Text(m.isOwner ? l10n.groupOwner : l10n.joinedAgo(timeAgo(m.joinedAt))),
              trailing: isOwner && !m.isOwner
                  ? IconButton(
                      tooltip: l10n.removeMember,
                      icon: const Icon(Icons.person_remove_rounded, color: Colors.redAccent),
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text(l10n.removeMemberTitle(name)),
                            content: Text(l10n.removeMemberBody),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text(l10n.cancel)),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(l10n.removeMember,
                                    style: const TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        try {
                          await service.removeMember(group.id, m.uid);
                        } catch (e) {
                          messenger.showSnackBar(
                              SnackBar(content: Text(l10n.errorWithDetails('$e'))));
                        }
                      },
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}
