import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import '../models/category_model.dart';

class CategoryPasswordDialog extends StatefulWidget {
  final Category category;
  const CategoryPasswordDialog({super.key, required this.category});

  @override
  State<CategoryPasswordDialog> createState() => _CategoryPasswordDialogState();
}

class _CategoryPasswordDialogState extends State<CategoryPasswordDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;
  bool _wrong = false;

  String _hash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  void _submit() {
    if (_hash(_controller.text) == widget.category.passwordHash) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _wrong = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.lock_rounded, color: widget.category.color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.category.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This category is protected. Enter the password to continue.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            autofocus: true,
            onSubmitted: (_) => _submit(),
            onChanged: (_) {
              if (_wrong) setState(() => _wrong = false);
            },
            decoration: InputDecoration(
              hintText: 'Password',
              errorText: _wrong ? 'Incorrect password' : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(backgroundColor: widget.category.color),
          child: const Text('Unlock'),
        ),
      ],
    );
  }
}
