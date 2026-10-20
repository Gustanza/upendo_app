import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/poll_model.dart';
import '../services/poll_service.dart';

// Self-contained poll body (no Scaffold/AppBar) meant to be embedded inside
// existing post cards / message bubbles by dashboard, community-wall and
// chat screens.
class PollView extends StatefulWidget {
  final PollData poll;
  final CollectionReference<Map<String, dynamic>> responsesRef;

  const PollView({
    super.key,
    required this.poll,
    required this.responsesRef,
  });

  @override
  State<PollView> createState() => _PollViewState();
}

class _PollViewState extends State<PollView> {
  final PollService _pollService = PollService();
  final TextEditingController _answerController = TextEditingController();
  bool _submitting = false;
  // Only meaningful for open-text polls' answered state — toggles that
  // Column between "showing my answer" and "editing my answer" (multiple-
  // choice doesn't need this: tapping any other option resubmits directly).
  bool _editing = false;
  // Created once (not inline in build()) so a rebuild triggered by something
  // else on screen — e.g. a sibling poll-composer's setState — doesn't hand
  // StreamBuilder a new Stream instance and force it to tear down and
  // reattach this poll's Firestore listener. Same fix as _messagesStream in
  // conversation_screen.dart.
  late final Stream<List<PollResponseModel>> _responsesStream =
      _pollService.watchResponses(widget.responsesRef);

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submit(String answer) async {
    if (answer.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      await _pollService.submitResponse(
        responsesRef: widget.responsesRef,
        answer: answer,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.sendFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _retract() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await _pollService.retractResponse(widget.responsesRef);
      _answerController.clear();
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.deleteFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  PollResponseModel? _findMine(List<PollResponseModel> responses, String? uid) {
    if (uid == null) return null;
    for (final response in responses) {
      if (response.uid == uid) return response;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: StreamBuilder<List<PollResponseModel>>(
        stream: _responsesStream,
        builder: (context, snapshot) {
          final responses = snapshot.data ?? [];
          final mine = _findMine(responses, currentUid);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.poll.question,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.pollResponsesCount(responses.length),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              if (mine == null)
                _buildUnanswered()
              else
                _buildAnswered(responses, mine, currentUid),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUnanswered() {
    if (widget.poll.isMultipleChoice) {
      return Column(
        children: widget.poll.options.map((option) => _buildOptionRow(option)).toList(),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _answerController,
          minLines: 2,
          maxLines: 4,
          enabled: !_submitting,
          decoration: InputDecoration(
            hintText: context.l10n.pollAnswerHint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _submitting ? null : () => _submit(_answerController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0077C2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(context.l10n.send),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionRow(String option) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _submitting ? null : () => _submit(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E5EE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.radio_button_unchecked, color: Color(0xFF0077C2), size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(option, style: const TextStyle(fontSize: 14))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswered(
    List<PollResponseModel> responses,
    PollResponseModel mine,
    String? currentUid,
  ) {
    if (widget.poll.isMultipleChoice) {
      final total = responses.length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...widget.poll.options.map((option) {
            final count = responses.where((r) => r.answer == option).length;
            final pct = total == 0 ? 0.0 : count / total;
            final isMine = option == mine.answer;
            return _buildResultRow(option, count, pct, isMine);
          }),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: _buildSmallTextButton(context.l10n.pollRetract, _retract,
                color: Colors.redAccent),
          ),
        ],
      );
    }

    final others = responses.where((r) => r.uid != currentUid).toList();

    if (_editing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _answerController,
            minLines: 2,
            maxLines: 4,
            enabled: !_submitting,
            decoration: InputDecoration(
              hintText: context.l10n.pollAnswerHint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildSmallTextButton(
                context.l10n.cancel,
                _submitting ? null : () => setState(() => _editing = false),
              ),
              const SizedBox(width: 4),
              ElevatedButton(
                onPressed: _submitting
                    ? null
                    : () async {
                        await _submit(_answerController.text.trim());
                        if (mounted) setState(() => _editing = false);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0077C2),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(context.l10n.save),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              context.l10n.pollYourAnswer,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0077C2)),
            ),
            const Spacer(),
            _buildSmallTextButton(
              context.l10n.edit,
              _submitting
                  ? null
                  : () {
                      _answerController.text = mine.answer;
                      setState(() => _editing = true);
                    },
            ),
            _buildSmallTextButton(context.l10n.delete, _retract,
                color: Colors.redAccent),
          ],
        ),
        Text(mine.answer, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        if (others.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          ...others.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(r.answer, style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSmallTextButton(String label, VoidCallback? onPressed, {Color? color}) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color ?? Colors.black54,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildResultRow(String option, int count, double pct, bool isMine) {
    final barColor = isMine ? const Color(0xFF0077C2) : const Color(0xFFADB5BD);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          // Tapping a different option switches your vote (submitResponse
          // overwrites via SetOptions.merge); tapping your own current pick
          // is a no-op — use "Futa jibu" to retract it instead.
          onTap: _submitting || isMine ? null : () => _submit(option),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isMine ? FontWeight.bold : FontWeight.normal,
                        color: isMine ? const Color(0xFF0077C2) : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    '${(pct * 100).round()}% ($count)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      fontWeight: isMine ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  children: [
                    Container(height: 8, color: const Color(0xFFE9ECF3)),
                    FractionallySizedBox(
                      widthFactor: pct.clamp(0.0, 1.0),
                      child: Container(height: 8, color: barColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
