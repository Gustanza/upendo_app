import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:upendo_app/views/home_dashboard.dart';

enum _PaymentState { loading, selectPackage, initiating, waiting }

class ProfilePaymentScreen extends StatefulWidget {
  const ProfilePaymentScreen({super.key});

  @override
  State<ProfilePaymentScreen> createState() => _ProfilePaymentScreenState();
}

class _ProfilePaymentScreenState extends State<ProfilePaymentScreen> {
  static const _subscribeUrl = 'https://subscribe-dcnp2gn42a-uc.a.run.app';
  static const _callbackUrl  = 'https://moyoapptanzania-cf0e7.web.app';

  _PaymentState _state = _PaymentState.loading;
  List<Map<String, dynamic>> _packages = [];
  String? _selectedPackageId;
  String? _errorMessage;
  StreamSubscription<DocumentSnapshot>? _userSub;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────

  Future<void> _loadPackages() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('packages')
          .where('isActive', isEqualTo: true)
          .get();
      final pkgs = snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      if (!mounted) return;
      setState(() {
        _packages = pkgs;
        _selectedPackageId = pkgs.isNotEmpty ? pkgs.first['id'] as String : null;
        _state = _PaymentState.selectPackage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Imeshindwa kupakua vifurushi. Jaribu tena.';
        _state = _PaymentState.selectPackage;
      });
    }
  }

  Future<void> _initiatePayment() async {
    if (_selectedPackageId == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _state = _PaymentState.initiating;
      _errorMessage = null;
    });

    try {
      final resp = await http.post(
        Uri.parse(_subscribeUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': user.uid,
          'packageId': _selectedPackageId,
          'callback_url': _callbackUrl,
        }),
      );

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final err = data['error'];
      if (err != null) {
        if (!mounted) return;
        setState(() {
          _state = _PaymentState.selectPackage;
          _errorMessage = (err as Map)['message']?.toString() ?? 'Hitilafu imetokea.';
        });
        return;
      }

      final redirectUrl = data['redirect_url'] as String;
      await launchUrl(Uri.parse(redirectUrl), mode: LaunchMode.externalApplication);

      if (!mounted) return;
      setState(() => _state = _PaymentState.waiting);
      _listenForActivation(user.uid);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = _PaymentState.selectPackage;
        _errorMessage = 'Hitilafu imetokea. Angalia mtandao na ujaribu tena.';
      });
    }
  }

  void _listenForActivation(String uid) {
    _userSub?.cancel();
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          if (snap.data()?['isActive'] == true) {
            _userSub?.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeDashboard()),
            );
          }
        });
  }

  Future<void> _checkActivation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _errorMessage = null);

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!mounted) return;
    if (snap.data()?['isActive'] == true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeDashboard()),
      );
    } else {
      setState(() => _errorMessage = 'Malipo bado hayajathibitishwa. Subiri kidogo.');
    }
  }

  void _goBackToSelection() {
    _userSub?.cancel();
    setState(() {
      _state = _PaymentState.selectPackage;
      _errorMessage = null;
    });
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF00AEEF), Color(0xFF00008B)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header image
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: ShaderMask(
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.transparent],
                      stops: [0.7, 1.0],
                    ).createShader(rect),
                    blendMode: BlendMode.dstIn,
                    child: Image.asset('assets/images/g272.png', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 10),
                Image.asset('assets/images/logo.png', height: 55, fit: BoxFit.contain),
                const SizedBox(height: 24),

                // Body — swaps by state
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: switch (_state) {
                    _PaymentState.loading    => _buildLoading(),
                    _PaymentState.initiating => _buildInitiating(),
                    _PaymentState.waiting    => _buildWaiting(),
                    _PaymentState.selectPackage => _buildSelectPackage(),
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── State: loading packages ──────────────────────────────────

  Widget _buildLoading() {
    return const Padding(
      key: ValueKey('loading'),
      padding: EdgeInsets.symmetric(vertical: 50),
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  // ── State: calling subscribe function ────────────────────────

  Widget _buildInitiating() {
    return const Padding(
      key: ValueKey('initiating'),
      padding: EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Inaandaa malipo…',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ── State: browser open, waiting for PesaPal IPN ─────────────

  Widget _buildWaiting() {
    return Padding(
      key: const ValueKey('waiting'),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(38),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(77)),
            ),
            child: Column(
              children: [
                const Icon(Icons.open_in_browser_rounded, color: Colors.white, size: 44),
                const SizedBox(height: 14),
                const Text(
                  'Ukurasa wa malipo umefunguliwa',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kamilisha malipo kwenye kivinjari. Programu itafunguka moja kwa moja baada ya malipo kukubaliwa.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withAlpha(217),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 13),
              ),
            ),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _checkActivation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF00008B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Nimemaliza malipo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),

          TextButton(
            onPressed: _goBackToSelection,
            child: const Text(
              'Rudi nyuma',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── State: package selection ─────────────────────────────────

  Widget _buildSelectPackage() {
    return Padding(
      key: const ValueKey('selectPackage'),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),

          if (_packages.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(38),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Hakuna vifurushi vya usajili kwa sasa.\nTafadhali wasiliana na msimamizi.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
              ),
            )
          else ...[
            const Text(
              'Chagua kifurushi cha usajili',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),

            ..._packages.map(_buildPackageCard),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedPackageId != null ? _initiatePayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AEEF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white24,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'ENDELEA',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg) {
    final isSelected = _selectedPackageId == pkg['id'];
    final price    = (pkg['price'] as num?)?.toStringAsFixed(0) ?? '0';
    final currency = (pkg['currency'] as String?) ?? 'TZS';
    final days     = (pkg['durationDays'] as num?)?.toInt() ?? 30;
    final name     = (pkg['name'] as String?) ?? '';
    final desc     = (pkg['description'] as String?) ?? '';

    return GestureDetector(
      onTap: () => setState(() => _selectedPackageId = pkg['id'] as String),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withAlpha(38),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withAlpha(77),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF3b4cca) : Colors.white60,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF3b4cca) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),

            // Name + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF1a1d2e) : Colors.white,
                    ),
                  ),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.grey[600] : Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Price + duration
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$currency $price',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? const Color(0xFF1a1d2e) : Colors.white,
                  ),
                ),
                Text(
                  '$days siku',
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected ? Colors.grey[600] : Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
