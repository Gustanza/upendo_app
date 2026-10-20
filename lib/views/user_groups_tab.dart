import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/category_model.dart';
import '../models/user_group_model.dart';
import '../services/user_group_service.dart';
import 'user_group_form_screen.dart';
import 'user_group_screen.dart';

/// "Groups" tab of a subcategory: every user group created in it, plus a
/// button to create a new one.
class UserGroupsTab extends StatefulWidget {
  final Category subcategory;
  const UserGroupsTab({super.key, required this.subcategory});

  @override
  State<UserGroupsTab> createState() => _UserGroupsTabState();
}

class _UserGroupsTabState extends State<UserGroupsTab> {
  final UserGroupService _service = UserGroupService();
  late final Stream<List<UserGroup>> _groups = _service.watchGroups(widget.subcategory.id);

  Future<void> _create() async {
    final groupId = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => UserGroupFormScreen(subcategoryId: widget.subcategory.id),
      ),
    );
    if (groupId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserGroupScreen(groupId: groupId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return StreamBuilder<List<UserGroup>>(
      stream: _groups,
      builder: (context, snapshot) {
        final groups = snapshot.data ?? const <UserGroup>[];
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.group_add_rounded),
                label: Text(l10n.createGroup),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2942),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (snapshot.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Center(
                  child: Text(
                    l10n.errorWithDetails('${snapshot.error}'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.only(top: 30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Center(
                  child: Text(
                    l10n.noGroupsYet,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ...groups.map((g) => _GroupTile(group: g)),
          ],
        );
      },
    );
  }
}

class _GroupTile extends StatelessWidget {
  final UserGroup group;
  const _GroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: GroupAvatar(group: group, radius: 26),
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.description.isNotEmpty)
              Text(group.description, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              context.l10n.membersCount(group.memberCount),
              style: const TextStyle(fontSize: 12, color: Color(0xFF8B2942)),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => UserGroupScreen(groupId: group.id)),
        ),
      ),
    );
  }
}

/// Group profile picture, or its initial on the brand colour.
class GroupAvatar extends StatelessWidget {
  final UserGroup group;
  final double radius;
  const GroupAvatar({super.key, required this.group, this.radius = 22});

  @override
  Widget build(BuildContext context) {
    final url = group.photoUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFF3E3E7),
      backgroundImage: url != null ? NetworkImage(url) : null,
      child: url == null
          ? Text(
              group.name.isNotEmpty ? group.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8B2942),
              ),
            )
          : null,
    );
  }
}
