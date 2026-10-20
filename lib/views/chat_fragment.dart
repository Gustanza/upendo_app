import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../widgets/thread_feed.dart';

/// The community wall tab ("Ukuta wa Jumuiya"). The feed itself is the
/// shared ThreadFeed, also used by subcategory and user-group feeds.
class ChatFragment extends StatelessWidget {
  const ChatFragment({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF00AEEF), Color(0xFF00008B)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          padding: const EdgeInsets.only(
            top: 80,
            left: 25,
            right: 25,
            bottom: 40,
          ),
          child: Center(
            child: Text(
              context.l10n.communityWall,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Feed
        const Expanded(child: ThreadFeed()),
      ],
    );
  }
}
