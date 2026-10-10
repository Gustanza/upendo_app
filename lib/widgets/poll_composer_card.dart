import 'package:flutter/material.dart';
import '../models/poll_model.dart';

const int _maxOptions = 6;

// Plain mutable holder edited in place by PollComposerCard — not a
// Firestore model. The host compose screen calls build() to know whether
// its own submit button should be enabled.
class PollDraft {
  String question;
  String pollType;
  List<String> options;

  PollDraft({
    this.question = '',
    this.pollType = PollType.multipleChoice,
    List<String>? options,
  }) : options = options ?? ['', ''];

  PollData? build() {
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty) return null;

    if (pollType == PollType.openText) {
      return PollData(question: trimmedQuestion, pollType: pollType);
    }

    // Dedupe so two identical option labels can't collide into the same
    // stored answer string (which would make them indistinguishable when
    // voting and double up in the results tally).
    final seenOptions = <String>{};
    final trimmedOptions = <String>[];
    for (final trimmed in options.map((o) => o.trim())) {
      if (trimmed.isEmpty || !seenOptions.add(trimmed)) continue;
      trimmedOptions.add(trimmed);
    }
    if (trimmedOptions.length < 2) return null;
    return PollData(question: trimmedQuestion, pollType: pollType, options: trimmedOptions);
  }
}

// Edits a PollDraft in place; does not submit anything itself. The parent
// compose screen owns the draft and re-checks draft.build() via onChanged.
class PollComposerCard extends StatefulWidget {
  final PollDraft draft;
  final VoidCallback onChanged;

  const PollComposerCard({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<PollComposerCard> createState() => _PollComposerCardState();
}

class _PollComposerCardState extends State<PollComposerCard> {
  late final TextEditingController _questionController =
      TextEditingController(text: widget.draft.question);
  late List<TextEditingController> _optionControllers;

  @override
  void initState() {
    super.initState();
    _optionControllers =
        widget.draft.options.map((o) => TextEditingController(text: o)).toList();
  }

  @override
  void didUpdateWidget(PollComposerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The parent may swap in a brand-new PollDraft instance (e.g. resetting
    // the composer) while this widget stays mounted at the same tree
    // position — initState won't rerun, so without this the text
    // controllers would keep showing the old draft's stale values while
    // silently writing edits into the new draft.
    if (oldWidget.draft != widget.draft) {
      _questionController.text = widget.draft.question;
      final options = widget.draft.options;
      while (_optionControllers.length < options.length) {
        _optionControllers.add(TextEditingController());
      }
      while (_optionControllers.length > options.length) {
        _optionControllers.removeLast().dispose();
      }
      for (var i = 0; i < options.length; i++) {
        _optionControllers[i].text = options[i];
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  void _setPollType(String pollType) {
    if (widget.draft.pollType == pollType) return;
    setState(() => widget.draft.pollType = pollType);
    widget.onChanged();
  }

  void _addOption() {
    if (widget.draft.options.length >= _maxOptions) return;
    setState(() {
      widget.draft.options.add('');
      _optionControllers.add(TextEditingController());
    });
    widget.onChanged();
  }

  void _removeOption(int index) {
    if (widget.draft.options.length <= 2) return;
    setState(() {
      widget.draft.options.removeAt(index);
      _optionControllers.removeAt(index).dispose();
    });
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _questionController,
            // threadPosts/messages cap `text` (which the question becomes)
            // at 500 chars server-side — enforce it here too so the error
            // surfaces before submit instead of as a raw permission-denied.
            maxLength: 500,
            decoration: _fieldDecoration('Andika swali lako...'),
            onChanged: (value) {
              widget.draft.question = value;
              widget.onChanged();
            },
          ),
          const SizedBox(height: 12),
          _buildTypeToggle(),
          const SizedBox(height: 12),
          if (widget.draft.pollType == PollType.multipleChoice) _buildOptionsList(),
        ],
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Row(
      children: [
        Expanded(child: _buildTypeButton('Chaguo Nyingi', PollType.multipleChoice)),
        const SizedBox(width: 8),
        Expanded(child: _buildTypeButton('Jibu la Maandishi', PollType.openText)),
      ],
    );
  }

  Widget _buildTypeButton(String label, String pollType) {
    final isSelected = widget.draft.pollType == pollType;
    return GestureDetector(
      onTap: () => _setPollType(pollType),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0077C2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0077C2) : const Color(0xFFE0E5EE),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < widget.draft.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _optionControllers[i],
                    decoration: _fieldDecoration('Chaguo ${i + 1}'),
                    onChanged: (value) {
                      widget.draft.options[i] = value;
                      widget.onChanged();
                    },
                  ),
                ),
                if (widget.draft.options.length > 2)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.black54),
                    onPressed: () => _removeOption(i),
                  ),
              ],
            ),
          ),
        if (widget.draft.options.length < _maxOptions)
          TextButton.icon(
            onPressed: _addOption,
            icon: const Icon(Icons.add, color: Color(0xFF0077C2)),
            label: const Text('Ongeza chaguo', style: TextStyle(color: Color(0xFF0077C2))),
          ),
      ],
    );
  }
}
