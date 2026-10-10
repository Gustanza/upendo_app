import 'package:flutter/material.dart';
import '../services/thread_interaction_service.dart';

class ThreadStatsRow extends StatefulWidget {
  final String postId;
  final int likeCount;
  final int commentCount;
  final Color iconColor;
  final double fontSize;

  const ThreadStatsRow({
    super.key,
    required this.postId,
    required this.likeCount,
    required this.commentCount,
    this.iconColor = Colors.grey,
    this.fontSize = 12,
  });

  @override
  State<ThreadStatsRow> createState() => _ThreadStatsRowState();
}

class _ThreadStatsRowState extends State<ThreadStatsRow> {
  final ThreadInteractionService _interactionService = ThreadInteractionService();
  late final Stream<bool> _likedByMe =
      _interactionService.likedByMe(widget.postId);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<bool>(
          stream: _likedByMe,
          builder: (context, snapshot) {
            final isLiked = snapshot.data ?? false;
            return GestureDetector(
              onTap: () => _interactionService.toggleLike(widget.postId),
              behavior: HitTestBehavior.opaque,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 16,
                color: isLiked ? Colors.redAccent : widget.iconColor,
              ),
            );
          },
        ),
        const SizedBox(width: 4),
        Text('${widget.likeCount}',
            style: TextStyle(fontSize: widget.fontSize, color: widget.iconColor)),
        const SizedBox(width: 16),
        Icon(Icons.chat_bubble_outline, size: 16, color: widget.iconColor),
        const SizedBox(width: 4),
        Text('${widget.commentCount}',
            style: TextStyle(fontSize: widget.fontSize, color: widget.iconColor)),
      ],
    );
  }
}
