import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_preferences.dart';
import 'profile_payment_screen.dart';
import 'welcome_screen.dart';

class AccountFragment extends StatefulWidget {
  const AccountFragment({super.key});

  @override
  State<AccountFragment> createState() => _AccountFragmentState();
}

class _AccountFragmentState extends State<AccountFragment> {
  final UserPreferences _userPreferences = UserPreferences();

  UserModel? _user;
  bool _isActive = false;
  DateTime? _subscriptionExpiry;
  String? _packageName;
  int? _packageDurationDays;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final local   = await _userPreferences.getUserData();
    final authUser = FirebaseAuth.instance.currentUser;

    bool isActive = false;
    DateTime? expiry;
    String? packageId;
    String? packageName;
    int? durationDays;

    if (authUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(authUser.uid)
          .get();

      final data = doc.data();
      isActive  = data?['isActive'] == true;
      packageId = data?['activePackageId'] as String?;

      final expiryRaw = data?['subscriptionExpiry'];
      if (expiryRaw is Timestamp) {
        expiry = expiryRaw.toDate();
      }

      if (packageId != null) {
        final pkgDoc = await FirebaseFirestore.instance
            .collection('packages')
            .doc(packageId)
            .get();
        packageName  = pkgDoc.data()?['name'] as String?;
        durationDays = (pkgDoc.data()?['durationDays'] as num?)?.toInt();
      }
    }

    if (!mounted) return;
    setState(() {
      _user                 = local;
      _isActive             = isActive;
      _subscriptionExpiry   = expiry;
      _packageName          = packageName;
      _packageDurationDays  = durationDays;
      _isLoading            = false;
    });
  }

  // ── Helpers ──────────────────────────────────────────────────

  int get _daysLeft {
    if (_subscriptionExpiry == null) return 0;
    final diff = _subscriptionExpiry!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  double get _progress {
    if (_subscriptionExpiry == null || _packageDurationDays == null || _packageDurationDays! <= 0) {
      return 0;
    }
    final elapsed = _packageDurationDays! - _daysLeft;
    return (elapsed / _packageDurationDays!).clamp(0.0, 1.0);
  }

  Color get _expiryColor {
    if (_daysLeft <= 3) return const Color(0xFFEF4444);
    if (_daysLeft <= 7) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  String _formatDate(DateTime date) {
    const months = [
      'Januari', 'Februari', 'Machi', 'Aprili', 'Mei', 'Juni',
      'Julai', 'Agosti', 'Septemba', 'Oktoba', 'Novemba', 'Desemba',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : 'U';
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Toka?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Je, una uhakika unataka kutoka kwenye akaunti?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hapana'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ndiyo, Toka',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      await _userPreferences.clearUserData();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (_) => false,
        );
      }
    }
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F6FB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildSubscriptionCard(),
                  const SizedBox(height: 20),
                  _buildInfoCard(
                    icon: Icons.person_outline_rounded,
                    label: 'Jina Kamili',
                    value: _user?.fullName ?? '—',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.phone_outlined,
                    label: 'Namba ya Simu',
                    value: _user?.phone.isNotEmpty == true ? _user!.phone : '—',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.location_on_outlined,
                    label: 'Mahali',
                    value: [_user?.region, _user?.country]
                        .where((s) => s != null && s.isNotEmpty && s != 'Unknown')
                        .join(', ')
                        .ifEmpty('—'),
                  ),
                  const SizedBox(height: 28),
                  _buildLogoutButton(),
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────

  Widget _buildHeader() {
    final name = _user?.fullName ?? 'Mtumiaji';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00AEEF), Color(0xFF00008B)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -30, right: -30,
            child: Container(
              width: 150, height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(15),
              ),
            ),
          ),
          Positioned(
            bottom: 10, left: -50,
            child: Container(
              width: 130, height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(10),
              ),
            ),
          ),
          // Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withAlpha(30),
                    border: Border.all(color: Colors.white.withAlpha(100), width: 2.5),
                  ),
                  child: Center(
                    child: Text(
                      _initials(name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                if (_user?.phone.isNotEmpty == true)
                  Text(
                    _user!.phone,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                const SizedBox(height: 14),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isActive
                        ? const Color(0xFF10B981).withAlpha(40)
                        : Colors.red.withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isActive
                          ? const Color(0xFF10B981).withAlpha(120)
                          : Colors.red.withAlpha(120),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isActive ? const Color(0xFF10B981) : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        _isActive ? 'Akaunti Hai' : 'Akaunti Imezimwa',
                        style: TextStyle(
                          color: _isActive ? const Color(0xFF10B981) : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Subscription card ────────────────────────────────────────

  Widget _buildSubscriptionCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A5F), Color(0xFF0A1628)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A1628).withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circle
          Positioned(
            top: -20, right: -20,
            child: Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(8),
              ),
            ),
          ),
          Positioned(
            bottom: -30, left: 60,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: _isActive && _subscriptionExpiry != null
                ? _buildActiveSubscription()
                : _buildNoSubscription(),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSubscription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFFFFD700), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Usajili Wako',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(40),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withAlpha(100)),
              ),
              child: const Text(
                'Hai',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Package name
        Text(
          _packageName ?? 'Kifurushi cha Usajili',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),

        // Expiry
        Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                color: Colors.white.withAlpha(150), size: 13),
            const SizedBox(width: 6),
            Text(
              'Unaisha: ${_formatDate(_subscriptionExpiry!)}',
              style: TextStyle(
                color: Colors.white.withAlpha(180),
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Progress bar
        if (_packageDurationDays != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Muda uliobaki',
                style: TextStyle(
                  color: Colors.white.withAlpha(150),
                  fontSize: 12,
                ),
              ),
              Text(
                '$_daysLeft siku',
                style: TextStyle(
                  color: _expiryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: Colors.white.withAlpha(25),
              valueColor: AlwaysStoppedAnimation<Color>(_expiryColor),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0',
                  style: TextStyle(
                      color: Colors.white.withAlpha(80), fontSize: 10)),
              Text('$_packageDurationDays siku',
                  style: TextStyle(
                      color: Colors.white.withAlpha(80), fontSize: 10)),
            ],
          ),
        ],

        // Renew nudge if expiring soon
        if (_daysLeft <= 7) ...[
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfilePaymentScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: _expiryColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _expiryColor.withAlpha(100)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.refresh_rounded, color: _expiryColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Fanya Upya Usajili',
                    style: TextStyle(
                      color: _expiryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNoSubscription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.workspace_premium_rounded,
                  color: Colors.white.withAlpha(120), size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'Usajili Wako',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(40),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withAlpha(100)),
              ),
              child: const Text(
                'Haina',
                style: TextStyle(
                    color: Colors.red, fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Huna usajili\nunaofanya kazi',
          style: TextStyle(
            color: Colors.white.withAlpha(200),
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Jiandikishe ili uendelee\nkufurahia maudhui yetu.',
          style: TextStyle(
            color: Colors.white.withAlpha(140),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ProfilePaymentScreen()),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFF00AEEF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_open_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text(
                  'Jiandikishe Sasa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Info card ────────────────────────────────────────────────

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: const Color(0xFF0077C2), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFADB5BD),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1D2E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Logout ───────────────────────────────────────────────────

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFFE0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
            SizedBox(width: 10),
            Text(
              'Toka Kwenye Akaunti',
              style: TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
