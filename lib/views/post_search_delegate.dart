import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../widgets/post_stats_row.dart';
import 'post_detail_screen.dart';

class PostSearchDelegate extends SearchDelegate<PostModel?> {
  final PostService _postService = PostService();

  @override
  String get searchFieldLabel => currentL10n.searchTopicsHint;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildPostList(context, query);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildPostList(context, query);
  }

  Widget _buildPostList(BuildContext context, String query) {
    if (query.isEmpty) {
      return Center(child: Text(context.l10n.searchTopicPrompt));
    }

    return FutureBuilder<List<PostModel>>(
      future: _postService.searchPosts(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: Text(context.l10n.errorWithDetails('${snapshot.error}')));
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Center(child: Text(context.l10n.topicNotFound));
        }

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: post.thumbnail.isNotEmpty
                    ? Image.network(
                        post.thumbnail,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
              title: Text(
                post.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    post.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  PostStatsRow(
                    postId: post.id,
                    likeCount: post.likeCount,
                    commentCount: post.commentCount,
                    fontSize: 11,
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(post: post),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
