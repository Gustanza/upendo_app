import 'dart:io';

import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/attachment_model.dart';
import '../models/user_group_model.dart';
import '../services/attachment_service.dart';
import '../services/user_group_service.dart';

/// Create a group in [subcategoryId], or edit [existing] (owner only).
/// Pops with the group id on success.
class UserGroupFormScreen extends StatefulWidget {
  final String subcategoryId;
  final UserGroup? existing;

  const UserGroupFormScreen({super.key, required this.subcategoryId, this.existing});

  @override
  State<UserGroupFormScreen> createState() => _UserGroupFormScreenState();
}

class _UserGroupFormScreenState extends State<UserGroupFormScreen> {
  final UserGroupService _service = UserGroupService();
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _description =
      TextEditingController(text: widget.existing?.description ?? '');
  PendingAttachment? _photo;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await AttachmentService().pickImages(1);
    if (picked.isNotEmpty && mounted) setState(() => _photo = picked.first);
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (_name.text.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.groupNameRequired)));
      return;
    }
    setState(() => _saving = true);
    try {
      final String groupId;
      if (_isEdit) {
        groupId = widget.existing!.id;
        await _service.updateGroup(
          groupId,
          name: _name.text,
          description: _description.text,
          newPhoto: _photo,
        );
      } else {
        groupId = await _service.createGroup(
          subcategoryId: widget.subcategoryId,
          name: _name.text,
          description: _description.text,
          photo: _photo,
        );
      }
      if (mounted) Navigator.pop(context, groupId);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        messenger.showSnackBar(SnackBar(content: Text(l10n.saveFailed('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final existingUrl = widget.existing?.photoUrl;
    final ImageProvider? preview = _photo != null
        ? FileImage(File(_photo!.localPath))
        : (existingUrl != null ? NetworkImage(existingUrl) : null);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l10n.editGroup : l10n.createGroup)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _saving ? null : _pickPhoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: const Color(0xFFF3E3E7),
                    backgroundImage: preview,
                    child: preview == null
                        ? const Icon(Icons.groups_rounded, size: 46, color: Color(0xFF8B2942))
                        : null,
                  ),
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 17,
                      backgroundColor: Color(0xFF8B2942),
                      child: Icon(Icons.camera_alt_rounded, size: 17, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(l10n.groupPhotoHint,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _name,
            maxLength: UserGroup.maxNameLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.groupName,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _description,
            maxLength: UserGroup.maxDescriptionLength,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.groupDescription,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B2942),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(_isEdit ? l10n.save : l10n.createGroup),
            ),
          ),
        ],
      ),
    );
  }
}
