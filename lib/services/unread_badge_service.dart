import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_model.dart';
import '../models/notification_model.dart';
import 'category_service.dart';
import 'notification_service.dart';

/// Unread counts shown as badges on categories and posts.
///
/// An "activity" is either a new post (its created_at) or a notification
/// about a post (comment/like, carrying postId). An activity counts as unread
/// for a post until that post is opened, and for a category until that
/// category — or the sub-category / post it belongs to — is opened. "Opened"
/// times live in SharedPreferences, so they are per-device.
///
/// Anything older than the first time this ran on the device is treated as
/// already seen, so existing users don't open the app to hundreds of badges.
class UnreadBadgeService extends ChangeNotifier {
  UnreadBadgeService._();
  static final UnreadBadgeService instance = UnreadBadgeService._();

  static const _baselineKey = 'badge_baseline_ms';
  static const _seenKey = 'badge_seen';

  final _db = FirebaseFirestore.instance;

  SharedPreferences? _prefs;
  String? _startedForUid;
  int _baselineMs = 0;
  Map<String, int> _seen = {};

  // postId → time of the post's creation (only posts newer than baseline).
  final Map<String, int> _newPostTimes = {};
  // postId → times of notifications about that post.
  final Map<String, List<int>> _notifTimes = {};
  // postId → category_id, for every post that has activity.
  final Map<String, String> _postCategory = {};
  // categoryId → parentId (null for top-level).
  Map<String, String?> _parentOf = {};

  final List<StreamSubscription> _subs = [];

  Future<void> start() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid == _startedForUid) return;
    _startedForUid = uid;
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _newPostTimes.clear();
    _notifTimes.clear();

    _prefs = await SharedPreferences.getInstance();
    _baselineMs = _prefs!.getInt(_baselineKey) ?? 0;
    if (_baselineMs == 0) {
      _baselineMs = DateTime.now().millisecondsSinceEpoch;
      await _prefs!.setInt(_baselineKey, _baselineMs);
    }
    final raw = _prefs!.getString(_seenKey);
    _seen = raw == null
        ? {}
        : (jsonDecode(raw) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toInt()));

    _subs.add(CategoryService().getCategories().listen(_onCategories));
    _subs.add(_db
        .collection('posts')
        .where('created_at',
            isGreaterThan:
                Timestamp.fromMillisecondsSinceEpoch(_baselineMs))
        .snapshots()
        .listen(_onNewPosts, onError: (e) => debugPrint('badge posts: $e')));
    _subs.add(NotificationService()
        .getNotifications()
        .listen(_onNotifications,
            onError: (e) => debugPrint('badge notifs: $e')));
  }

  void _onCategories(List<Category> categories) {
    _parentOf = {for (final c in categories) c.id: c.parentId};
    notifyListeners();
  }

  void _onNewPosts(QuerySnapshot<Map<String, dynamic>> snap) {
    _newPostTimes.clear();
    for (final d in snap.docs) {
      final ts = d.data()['created_at'] as Timestamp?;
      if (ts == null) continue;
      _newPostTimes[d.id] = ts.millisecondsSinceEpoch;
      _postCategory[d.id] = (d.data()['category_id'] as String?) ?? '';
    }
    notifyListeners();
  }

  Future<void> _onNotifications(List<AppNotification> notifications) async {
    _notifTimes.clear();
    for (final n in notifications) {
      final postId = n.postId;
      final ms = n.createdAt?.millisecondsSinceEpoch ?? 0;
      if (postId == null || ms <= _baselineMs) continue;
      _notifTimes.putIfAbsent(postId, () => []).add(ms);
    }
    notifyListeners();

    // Resolve categories for posts we only know about via notifications.
    final missing =
        _notifTimes.keys.where((id) => !_postCategory.containsKey(id)).toList();
    for (var i = 0; i < missing.length; i += 30) {
      final chunk = missing.sublist(i, (i + 30).clamp(0, missing.length));
      try {
        final snap = await _db
            .collection('posts')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final d in snap.docs) {
          _postCategory[d.id] = (d.data()['category_id'] as String?) ?? '';
        }
      } catch (e) {
        debugPrint('badge post lookup: $e');
      }
    }
    if (missing.isNotEmpty) notifyListeners();
  }

  int _seenAt(String key) => _seen[key] ?? _baselineMs;

  Iterable<MapEntry<String, int>> _activities() sync* {
    for (final e in _newPostTimes.entries) {
      yield e;
    }
    for (final e in _notifTimes.entries) {
      for (final ms in e.value) {
        yield MapEntry(e.key, ms);
      }
    }
  }

  /// Unread activity on a single post.
  int postCount(String postId) {
    final seen = _seenAt('p:$postId');
    var n = 0;
    final created = _newPostTimes[postId];
    if (created != null && created > seen) n++;
    for (final ms in _notifTimes[postId] ?? const <int>[]) {
      if (ms > seen) n++;
    }
    return n;
  }

  /// Unread activity in a category, including its sub-categories.
  int categoryCount(String categoryId) {
    var n = 0;
    for (final a in _activities()) {
      final postCat = _postCategory[a.key];
      if (postCat == null) continue;
      final inCategory =
          postCat == categoryId || _parentOf[postCat] == categoryId;
      if (!inCategory) continue;
      final seen = [
        _seenAt('c:$categoryId'),
        _seenAt('c:$postCat'),
        _seenAt('p:${a.key}'),
      ].reduce((a, b) => a > b ? a : b);
      if (a.value > seen) n++;
    }
    return n;
  }

  void markCategorySeen(String categoryId) => _markSeen('c:$categoryId');
  void markPostSeen(String postId) => _markSeen('p:$postId');

  void _markSeen(String key) {
    _seen[key] = DateTime.now().millisecondsSinceEpoch;
    _prefs?.setString(_seenKey, jsonEncode(_seen));
    // Deferred: this is called from initState of a screen being pushed,
    // i.e. mid-build, where synchronously rebuilding listeners would throw.
    scheduleMicrotask(notifyListeners);
  }
}
