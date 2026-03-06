import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class ChatFragment extends StatefulWidget {
  const ChatFragment({super.key});

  @override
  State<ChatFragment> createState() => _ChatFragmentState();
}

class _ChatFragmentState extends State<ChatFragment> {
  final UserService _userService = UserService();
  final ScrollController _scrollController = ScrollController();

  final List<UserModel> _users = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchUsers();
    }
  }

  Future<void> _fetchUsers() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newUsers = await _userService.getUsers(
        startAfter: _lastDocument,
        limit: 20,
      );

      if (newUsers.length < 20) {
        _hasMore = false;
      }

      if (newUsers.isNotEmpty) {
        // Need to get the last document for the next page
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .orderBy('fullName')
            .startAt([newUsers.last.fullName])
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          _lastDocument = snapshot.docs.first;
        }
      }

      setState(() {
        _users.addAll(newUsers);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching users: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    // Ensure phone number is in international format without + or extra chars for wa.me
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final url = 'https://wa.me/$cleanPhone';
    final uri = Uri.parse(url);

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error launching WhatsApp: $e')));
      }
    }
  }

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
          child: const Center(
            child: Text(
              'Zungumza na Wanachama',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // User List
        Expanded(
          child: _users.isEmpty && _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _users.clear();
                      _lastDocument = null;
                      _hasMore = true;
                    });
                    await _fetchUsers();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(15),
                    itemCount: _users.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _users.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final user = _users[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    user.fullName.isNotEmpty
                                        ? user.fullName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.fullName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 14,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              '${user.region}, ${user.country}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 25, thickness: 0.5),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => _launchWhatsApp(user.phone),
                                icon: const Icon(Icons.chat, size: 18),
                                label: const Text('Zungumza'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
