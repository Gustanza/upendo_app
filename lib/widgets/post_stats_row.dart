import 'package:flutter/material.dart';
import '../services/post_interaction_service.dart';

class PostStatsRow extends StatefulWidget {
  final String postId;
  final int likeCount;
  final int commentCount;
  final Color iconColor;
  final double fontSize;

  const PostStatsRow({
    super.key,
    required this.postId,
    required this.likeCount,
    required this.commentCount,
    this.iconColor = Colors.grey,
    this.fontSize = 12,
  });

  @override
  State<PostStatsRow> createState() => _PostStatsRowState();
}

class _PostStatsRowState extends State<PostStatsRow> {
  late final Stream<bool> _likedByMe =
      PostInteractionService().likedByMe(widget.postId);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<bool>(
          stream: _likedByMe,
          builder: (context, snapshot) {
            final isLiked = snapshot.data ?? false;
            return Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              size: 14,
              color: isLiked ? Colors.redAccent : widget.iconColor,
            );
          },
        ),
        const SizedBox(width: 4),
        Text('${widget.likeCount}',
            style: TextStyle(fontSize: widget.fontSize, color: widget.iconColor)),
        const SizedBox(width: 12),
        Icon(Icons.chat_bubble_outline, size: 14, color: widget.iconColor),
        const SizedBox(width: 4),
        Text('${widget.commentCount}',
            style: TextStyle(fontSize: widget.fontSize, color: widget.iconColor)),
      ],
    );
  }
}
