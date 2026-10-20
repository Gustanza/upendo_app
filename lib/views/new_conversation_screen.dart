import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/l10n.dart';
import '../models/user_model.dart';
import '../services/conversation_service.dart';
import '../services/user_service.dart';
import 'conversation_screen.dart';

// Reached from conversations_screen.dart's app bar — the only way today to
// start a conversation with someone you haven't already found via a post
// (see thread_detail_screen.dart's message button, which this screen's tap
// handler mirrors exactly).
class NewConversationScreen extends StatefulWidget {
  const NewConversationScreen({super.key});

  @override
  State<NewConversationScreen> createState() => _NewConversationScreenState();
}

class _NewConversationScreenState extends State<NewConversationScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<UserModel> _results = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  // Bumped on every new search (including clearing the field) so a slower,
  // older in-flight request can recognize it's been superseded and skip
  // applying its (now stale) results — e.g. typing "Jo" then quickly "John"
  // shouldn't let "Jo"'s results land after "John"'s if "Jo"'s round-trip
  // happens to finish last.
  int _searchRequestId = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(query));
  }

  Future<void> _search(String query) async {
    final trimmed = query.trim();

    if (trimmed.isEmpty) {
      _searchRequestId++; // invalidate any still-in-flight request
      setState(() {
        _results = [];
        _hasSearched = false;
        _isSearching = false;
      });
      return;
    }

    final requestId = ++_searchRequestId;
    setState(() => _isSearching = true);
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      final users = await _userService.searchUsersByName(trimmed);
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _results = users.where((u) => u.id != currentUid).toList();
        _hasSearched = true;
      });
    } catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.searchFailed('$e'))));
    } finally {
      if (mounted && requestId == _searchRequestId) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _openConversation(UserModel user) async {
    try {
      final conversationId = await ConversationService().getOrCreateConversation(
        otherUid: user.id,
        otherName: user.fullName,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConversationScreen(
            conversationId: conversationId,
            otherName: user.fullName,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.openConversationFailed('$e'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: Text(context.l10n.newMessage),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1D2E),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE8EAF0), height: 1),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onQueryChanged,
              decoration: InputDecoration(
                hintText: context.l10n.searchUserHint,
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_hasSearched && !_isSearching) {
      return Center(
        child: Text(
          context.l10n.newMessagePrompt,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        ),
      );
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          context.l10n.noUserFound,
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, i) {
        final user = _results[i];
        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ),
          title: Text(
            user.fullName,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          onTap: () => _openConversation(user),
        );
      },
    );
  }
}
