import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/user_preferences.dart';
import '../models/user_model.dart';
import 'welcome_screen.dart';

class AccountFragment extends StatefulWidget {
  const AccountFragment({super.key});

  @override
  State<AccountFragment> createState() => _AccountFragmentState();
}

class _AccountFragmentState extends State<AccountFragment> {
  final UserPreferences _userPreferences = UserPreferences();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = await _userPreferences.getUserData();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toka?'),
        content: const Text('Je, una uhakika unataka kutoka?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hapana'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Ndiyo, Toka',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      await _userPreferences.clearUserData();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            _buildHeader(),
            const SizedBox(height: 20),

            // Profile Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildInfoCard(
                    icon: Icons.person_outline,
                    title: 'Jina Kamili',
                    value: _user?.fullName ?? 'Haikupatikana',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.phone_outlined,
                    title: 'Namba ya Simu',
                    value: _user?.phone ?? 'Haikupatikana',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoCard(
                    icon: Icons.location_on_outlined,
                    title: 'Mahali',
                    value: '${_user?.region}, ${_user?.country}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Actions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [const SizedBox(height: 20), _buildLogoutButton()],
              ),
            ),
            const SizedBox(height: 100), // Spacing for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
      padding: const EdgeInsets.only(top: 80, bottom: 40),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              _user?.fullName.isNotEmpty == true
                  ? _user!.fullName[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00008B),
              ),
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              _user?.fullName ?? 'Mtumiaji',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            _user?.phone ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue.shade800),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _logout(context),
        icon: const Icon(Icons.logout, color: Colors.white),
        label: const Text(
          'TOKA KWENYE AKAUNTI',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade400,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
