import 'package:flutter/material.dart';
import '../services/unread_badge_service.dart';

/// Red count pill driven by [UnreadBadgeService]. Renders nothing at zero.
/// Pass exactly one of [categoryId] / [postId].
class UnreadBadge extends StatelessWidget {
  final String? categoryId;
  final String? postId;

  const UnreadBadge({super.key, this.categoryId, this.postId})
      : assert((categoryId == null) != (postId == null));

  @override
  Widget build(BuildContext context) {
    final service = UnreadBadgeService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final count = categoryId != null
            ? service.categoryCount(categoryId!)
            : service.postCount(postId!);
        if (count == 0) return const SizedBox.shrink();
        return Container(
          constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white, width: 1.5),
          ),
          child: Text(
            count > 99 ? '99+' : '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
      },
    );
  }
}
