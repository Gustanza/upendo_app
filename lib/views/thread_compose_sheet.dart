import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/poll_model.dart';
import '../services/thread_post_service.dart';
import '../widgets/poll_composer_card.dart';

class ThreadComposeSheet extends StatefulWidget {
  const ThreadComposeSheet({super.key});

  @override
  State<ThreadComposeSheet> createState() => _ThreadComposeSheetState();
}

class _ThreadComposeSheetState extends State<ThreadComposeSheet> {
  final ThreadPostService _postService = ThreadPostService();
  final TextEditingController _textController = TextEditingController();
  XFile? _image;
  PollDraft? _pollDraft;
  bool _isPosting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (file != null && mounted) setState(() => _image = file);
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _image == null && _pollDraft == null) return;

    String postText = text;
    PollData? pollData;
    if (_pollDraft != null) {
      pollData = _pollDraft!.build();
      if (pollData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jaza swali la kura kikamilifu')),
        );
        return;
      }
      postText = pollData.question;
    }

    setState(() => _isPosting = true);
    try {
      await _postService.createPost(
        text: postText,
        image: _image,
        poll: pollData,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Imeshindwa kutuma: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Andika Chapisho',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          if (_pollDraft == null)
            TextField(
              controller: _textController,
              maxLines: 5,
              minLines: 3,
              maxLength: 500,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Unafikiria nini?',
                border: InputBorder.none,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PollComposerCard(
                draft: _pollDraft!,
                onChanged: () => setState(() {}),
              ),
            ),
          if (_image != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(_image!.path),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(6),
                    child: GestureDetector(
                      onTap: () => setState(() => _image = null),
                      child: const CircleAvatar(
                        backgroundColor: Colors.black54,
                        radius: 14,
                        child: Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                onPressed: _isPosting ? null : _pickImage,
                icon: const Icon(Icons.image_outlined, color: Color(0xFF0077C2)),
              ),
              IconButton(
                onPressed: _isPosting
                    ? null
                    : () => setState(
                          () => _pollDraft = _pollDraft == null ? PollDraft() : null,
                        ),
                icon: Icon(
                  Icons.poll_outlined,
                  color: _pollDraft == null ? const Color(0xFF0077C2) : Colors.white,
                ),
                style: _pollDraft == null
                    ? null
                    : IconButton.styleFrom(backgroundColor: const Color(0xFF0077C2)),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isPosting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077C2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: _isPosting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Chapisha'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
