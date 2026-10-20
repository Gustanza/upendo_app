import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/category_model.dart';
import '../models/chat_channel.dart';
import '../models/thread_scope.dart';
import '../widgets/chat_room_view.dart';
import '../widgets/thread_feed.dart';
import 'category_posts_screen.dart';
import 'user_groups_tab.dart';

/// What a subcategory opens: the admin-curated topics it always had, plus
/// the community spaces every user can use inside it —
///  * Community: a thread feed (text, ≤5 images, ≤5-min video, PDF ≤50 MB,
///    audio, polls) with replies,
///  * Chat: a real-time chat room for the whole subcategory,
///  * Groups: user-created groups with their own posts and chat.
class SubcategoryHubScreen extends StatelessWidget {
  final Category category;

  const SubcategoryHubScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    category.color.withValues(alpha: 0.8),
                    category.color,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(top: 50, left: 12, right: 12, bottom: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Icon(category.icon, color: Colors.white, size: 30),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          category.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.white,
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(icon: const Icon(Icons.menu_book_rounded, size: 20), text: l10n.tabTopics),
                      Tab(icon: const Icon(Icons.forum_rounded, size: 20), text: l10n.tabCommunity),
                      Tab(icon: const Icon(Icons.chat_rounded, size: 20), text: l10n.tabChat),
                      Tab(icon: const Icon(Icons.groups_rounded, size: 20), text: l10n.tabGroups),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  CategoryPostsScreen(category: category, embedded: true),
                  ThreadFeed(scope: ThreadScope.subcategory(category.id)),
                  ChatRoomView(channel: ChatChannel.subcategory(category.id)),
                  UserGroupsTab(subcategory: category),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
