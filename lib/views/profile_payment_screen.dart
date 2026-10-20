import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:upendo_app/l10n/l10n.dart';
import 'package:upendo_app/utils/contact_actions.dart';
import 'package:upendo_app/views/home_dashboard.dart';

enum _PaymentState { loading, selectPackage, enterPhone, initiating, waiting, failed }

class ProfilePaymentScreen extends StatefulWidget {
  const ProfilePaymentScreen({super.key});

  @override
  State<ProfilePaymentScreen> createState() => _ProfilePaymentScreenState();
}

class _ProfilePaymentScreenState extends State<ProfilePaymentScreen> {
  static const _subscribeUrl = 'https://us-central1-moyoapptanzania-cf0e7.cloudfunctions.net/subscribeClickPesa';

  _PaymentState _state = _PaymentState.loading;
  List<Map<String, dynamic>> _packages = [];
  String? _selectedPackageId;
  String? _errorMessage;
  String _phoneNumber = '';
  bool _showAllPackages = false;
  static const _collapsedPackageCount = 4;
  StreamSubscription<DocumentSnapshot>? _userSub;
  StreamSubscription<DocumentSnapshot>? _subscriptionSub;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _subscriptionSub?.cancel();
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

      // Prefill the phone step with whatever number is already on the
      // account, stripped of the leading "+" auth_screen.dart stores it with.
      final user = FirebaseAuth.instance.currentUser;
      String initialPhone = '';
      if (user != null) {
        final userSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final stored = userSnap.data()?['phone'] as String?;
        if (stored != null) {
          initialPhone = stored.replaceFirst('+', '');
        }
      }

      if (!mounted) return;
      setState(() {
        _packages = pkgs;
        _selectedPackageId = pkgs.isNotEmpty ? pkgs.first['id'] as String : null;
        _phoneNumber = initialPhone;
        _state = _PaymentState.selectPackage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.l10n.paymentLoadPackagesFailed;
        _state = _PaymentState.selectPackage;
      });
    }
  }

  void _proceedToPhoneEntry() {
    if (_selectedPackageId == null) return;
    setState(() {
      _errorMessage = null;
      _state = _PaymentState.enterPhone;
    });
  }

  Future<void> _initiatePayment() async {
    if (_selectedPackageId == null || _phoneNumber.isEmpty) return;
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
          'phoneNumber': _phoneNumber,
        }),
      );

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final err = data['error'];
      if (err != null) {
        if (!mounted) return;
        setState(() {
          _state = _PaymentState.enterPhone;
          _errorMessage = (err as Map)['message']?.toString() ?? context.l10n.errorOccurred;
        });
        return;
      }

      final subscriptionId = data['subscription_id'] as String;

      if (!mounted) return;
      setState(() {
        _state = _PaymentState.waiting;
      });
      _listenForActivation(user.uid);
      _listenForFailure(subscriptionId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = _PaymentState.enterPhone;
        _errorMessage = context.l10n.errorCheckNetwork;
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
            _subscriptionSub?.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeDashboard()),
            );
          }
        });
  }

  // ClickPesa's webhook resolves within seconds of the customer entering (or
  // cancelling) their PIN, so we can surface a failure immediately instead of
  // leaving the user on an indefinite spinner like PesaPal's redirect flow did.
  void _listenForFailure(String subscriptionId) {
    _subscriptionSub?.cancel();
    _subscriptionSub = FirebaseFirestore.instance
        .collection('subscriptions')
        .doc(subscriptionId)
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          final status = snap.data()?['status'];
          // 'Underpaid': the provider confirmed a payment smaller than the
          // package price, so the server didn't activate the subscription.
          if (status == 'Failed' || status == 'Underpaid') {
            _userSub?.cancel();
            _subscriptionSub?.cancel();
            setState(() {
              _errorMessage = status == 'Underpaid'
                  ? context.l10n.paymentUnderpaid
                  : snap.data()?['message']?.toString() ??
                      context.l10n.paymentFailedMessage;
              _state = _PaymentState.failed;
            });
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
      setState(() => _errorMessage = context.l10n.paymentNotConfirmedYet);
    }
  }

  void _goBackToSelection() {
    _userSub?.cancel();
    _subscriptionSub?.cancel();
    setState(() {
      _state = _PaymentState.selectPackage;
      _errorMessage = null;
    });
  }

  void _retryFromFailure() {
    setState(() {
      _state = _PaymentState.enterPhone;
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
                    _PaymentState.loading      => _buildLoading(),
                    _PaymentState.enterPhone   => _buildEnterPhone(),
                    _PaymentState.initiating   => _buildInitiating(),
                    _PaymentState.waiting      => _buildWaiting(),
                    _PaymentState.failed       => _buildFailed(),
                    _PaymentState.selectPackage => _buildSelectPackage(),
                  },
                ),

                const SizedBox(height: 28),
                _buildSupportContacts(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Support contacts (tap a number to call / WhatsApp / copy) ─

  Widget _buildSupportContacts() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            context.l10n.paymentSupportPrompt,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final number in kSupportPhoneNumbers)
                Material(
                  color: Colors.white.withAlpha(38),
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => showContactOptions(context, number),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            number,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
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

  // ── State: confirm phone number for the USSD push ────────────

  Widget _buildEnterPhone() {
    return Padding(
      key: const ValueKey('enterPhone'),
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
          Text(
            context.l10n.paymentConfirmPhone,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.paymentPinPrompt,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),

          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            clipBehavior: Clip.antiAlias,
            child: IntlPhoneField(
              initialCountryCode: 'TZ',
              initialValue: _phoneNumber.isNotEmpty ? _phoneNumber : null,
              style: const TextStyle(color: Colors.black87),
              dropdownTextStyle: const TextStyle(color: Colors.black87),
              decoration: const InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                counterText: '',
                hintText: '0754 xxx xxx',
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
              onChanged: (p) => _phoneNumber = p.completeNumber.replaceFirst('+', ''),
            ),
          ),
          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _phoneNumber.isNotEmpty ? _initiatePayment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00AEEF),
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white24,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                context.l10n.payNow,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),

          TextButton(
            onPressed: _goBackToSelection,
            child: Text(
              context.l10n.goBack,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── State: calling subscribe function ────────────────────────

  Widget _buildInitiating() {
    return Padding(
      key: const ValueKey('initiating'),
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            context.l10n.paymentPreparing,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }

  // ── State: USSD push sent, waiting for customer to enter PIN ─

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
                const Icon(Icons.phonelink_ring_rounded, color: Colors.white, size: 44),
                const SizedBox(height: 14),
                Text(
                  context.l10n.paymentCheckPhone,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.paymentWaitingBody,
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
              child: Text(
                context.l10n.paymentDone,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),

          TextButton(
            onPressed: _goBackToSelection,
            child: Text(
              context.l10n.goBack,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── State: ClickPesa reported the payment failed ─────────────

  Widget _buildFailed() {
    return Padding(
      key: const ValueKey('failed'),
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
                const Icon(Icons.error_outline_rounded, color: Colors.orangeAccent, size: 44),
                const SizedBox(height: 14),
                Text(
                  context.l10n.paymentFailedTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? context.l10n.tryAgain,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withAlpha(217),
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _retryFromFailure,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF00008B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                context.l10n.tryAgainButton,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
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
              child: Text(
                context.l10n.paymentNoPackages,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
              ),
            )
          else ...[
            Text(
              context.l10n.paymentChoosePackage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),

            ...(_showAllPackages ? _packages : _packages.take(_collapsedPackageCount))
                .map(_buildPackageCard),

            if (_packages.length > _collapsedPackageCount)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton(
                  onPressed: () => setState(() => _showAllPackages = !_showAllPackages),
                  child: Text(
                    _showAllPackages
                        ? context.l10n.showFewer
                        : context.l10n.paymentShowMorePackages(
                            _packages.length - _collapsedPackageCount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedPackageId != null ? _proceedToPhoneEntry : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00AEEF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white24,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  context.l10n.continueButton,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                  context.l10n.daysCount(days),
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
