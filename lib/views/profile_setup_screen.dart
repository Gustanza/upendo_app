import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:upendo_app/utils/start_screen.dart';
import 'package:upendo_app/views/welcome_screen.dart';

// ── Data ─────────────────────────────────────────────────────────────────────

const _countries = [
  'Tanzania', 'Kenya', 'Uganda', 'Rwanda', 'Burundi', 'Ethiopia',
  'Nigeria', 'Ghana', 'South Africa', 'Zimbabwe', 'Zambia',
  'Mozambique', 'Malawi', 'DRC', 'Cameroon', 'Angola', 'Somalia',
  'Sudan', 'Egypt', 'Morocco', 'Ufaransa', 'Uingereza', 'Marekani',
  'Canada', 'Australia', 'Ujerumani', 'Italia', 'Uholanzi',
];

const _tanzaniaRegions = [
  'Arusha', 'Dar es Salaam', 'Dodoma', 'Geita', 'Iringa',
  'Kagera', 'Katavi', 'Kigoma', 'Kilimanjaro', 'Lindi',
  'Manyara', 'Mara', 'Mbeya', 'Morogoro', 'Mtwara',
  'Mwanza', 'Njombe', 'Pemba Kaskazini', 'Pemba Kusini',
  'Pwani', 'Rukwa', 'Ruvuma', 'Shinyanga', 'Simiyu',
  'Singida', 'Songwe', 'Tabora', 'Tanga', 'Unguja Kaskazini',
  'Unguja Kusini', 'Mjini Magharibi',
];


// ── Widget ───────────────────────────────────────────────────────────────────

/// Shown after Google sign-in when the account is missing details Google
/// doesn't provide (country, region, phone). Saves them on users/{uid} and
/// then continues to payment or home via startScreenFor.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _regNameCtrl    = TextEditingController();
  final _regCountryCtrl = TextEditingController();
  final _regRegionCtrl  = TextEditingController();
  final _regPhoneCtrl   = TextEditingController();
  String? _selectedCountry;
  String _completePhone = '';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  // Name from Google, plus anything already saved on an older account.
  Future<void> _prefill() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    _regNameCtrl.text = user.displayName ?? '';
    final doc = await FirebaseFirestore.instance
        .collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data == null || !mounted) return;
    setState(() {
      final name = (data['fullName'] as String? ?? '').trim();
      if (name.isNotEmpty) _regNameCtrl.text = name;
      final country = (data['country'] as String? ?? '').trim();
      if (country.isNotEmpty) {
        _regCountryCtrl.text = country;
        _selectedCountry = country;
      }
      _regRegionCtrl.text = (data['region'] as String? ?? '').trim();
    });
  }

  @override
  void dispose() {
    _regNameCtrl.dispose();
    _regCountryCtrl.dispose();
    _regRegionCtrl.dispose();
    _regPhoneCtrl.dispose();
    super.dispose();
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_regNameCtrl.text.trim().isEmpty ||
        _regCountryCtrl.text.isEmpty ||
        _regRegionCtrl.text.trim().isEmpty ||
        _completePhone.isEmpty) {
      _showError('Tafadhali jaza nafasi zote');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final existing = await ref.get();
      await ref.set({
        'fullName': _regNameCtrl.text.trim(),
        'email':    user.email ?? '',
        'country':  _regCountryCtrl.text.trim(),
        'region':   _regRegionCtrl.text.trim(),
        'phone':    _completePhone,
        // New account — locked behind a subscription until payment.
        if (!existing.exists) ...{
          'isActive':  false,
          'createdAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));

      final next = await startScreenFor(user);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => next),
          (_) => false,
        );
      }
    } catch (e) {
      _showError('Imeshindwa kuhifadhi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _useAnotherAccount() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // ── Picker bottom-sheet ────────────────────────────────────────────────────

  Future<String?> _showPickerSheet(String title, List<String> items) async {
    String query = '';
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final filtered = query.isEmpty
              ? items
              : items
                  .where((i) => i.toLowerCase().contains(query.toLowerCase()))
                  .toList();
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            maxChildSize: 0.9,
            builder: (_, ctrl) => Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0a1a6e),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Column(
                      children: [
                        Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 14),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            autofocus: true,
                            onChanged: (v) => setSheet(() => query = v),
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Tafuta…',
                              hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.35)),
                              prefixIcon: const Icon(Icons.search_rounded,
                                  color: Colors.white54, size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: ctrl,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => InkWell(
                        onTap: () => Navigator.pop(ctx, filtered[i]),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.06)),
                            ),
                          ),
                          child: Text(filtered[i],
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 15)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00AEEF), Color(0xFF00008B)],
              ),
            ),
          ),
          Positioned(top: -80, right: -80, child: _decorCircle(240, 0.07)),
          Positioned(bottom: 60, left: -100, child: _decorCircle(200, 0.05)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/images/logo.png',
                      height: 56, fit: BoxFit.contain),
                  const SizedBox(height: 18),
                  const Text(
                    'Kamilisha Taarifa Zako',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    email == null
                        ? 'Tunahitaji taarifa chache kabla ya kuendelea'
                        : 'Umeingia kama $email',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2), width: 1),
                    ),
                    child: _buildRegisterForm(),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading ? null : _useAnotherAccount,
                    child: const Text('Tumia akaunti nyingine ya Google',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          label: 'Jina Kamili',
          icon: Icons.person_outline_rounded,
          controller: _regNameCtrl,
          capitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        // Nchi dropdown
        _dropdownField(
          label: 'Nchi',
          icon: Icons.public_outlined,
          value: _regCountryCtrl.text.isEmpty ? null : _regCountryCtrl.text,
          hint: 'Chagua nchi yako',
          onTap: () async {
            final result = await _showPickerSheet('Chagua Nchi', _countries);
            if (result != null) {
              setState(() {
                _regCountryCtrl.text = result;
                _selectedCountry = result;
                _regRegionCtrl.clear();
              });
            }
          },
        ),
        const SizedBox(height: 12),
        // Mkoa — dropdown for Tanzania, text field otherwise
        if (_selectedCountry == 'Tanzania')
          _dropdownField(
            label: 'Mkoa',
            icon: Icons.location_city_outlined,
            value: _regRegionCtrl.text.isEmpty ? null : _regRegionCtrl.text,
            hint: 'Chagua mkoa wako',
            onTap: () async {
              final result =
                  await _showPickerSheet('Chagua Mkoa', _tanzaniaRegions);
              if (result != null) setState(() => _regRegionCtrl.text = result);
            },
          )
        else
          _field(
            label: 'Mkoa / Jimbo',
            icon: Icons.location_city_outlined,
            hint: _selectedCountry == null
                ? 'Chagua nchi kwanza'
                : 'Mkoa au jimbo lako',
            controller: _regRegionCtrl,
            enabled: _selectedCountry != null,
            capitalization: TextCapitalization.words,
          ),
        const SizedBox(height: 12),
        _buildPhoneField(),
        const SizedBox(height: 24),
        _primaryButton(text: 'HIFADHI NA ENDELEA', onPressed: _save),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Namba ya Simu',
            style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: IntlPhoneField(
            controller: _regPhoneCtrl,
            initialCountryCode: 'TZ',
            style: const TextStyle(color: Colors.white, fontSize: 15),
            dropdownTextStyle: const TextStyle(color: Colors.white),
            dropdownIcon: const Icon(Icons.arrow_drop_down_rounded,
                color: Colors.white70),
            decoration: InputDecoration(
              hintText: '0754 xxx xxx',
              hintStyle:
                  TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              counterStyle: const TextStyle(color: Colors.white54),
            ),
            onChanged: (p) => _completePhone = p.completeNumber,
          ),
        ),
      ],
    );
  }

  // ── Reusable widgets ───────────────────────────────────────────────────────

  Widget _field({
    required String label,
    required IconData icon,
    String? hint,
    bool isPassword = false,
    bool passwordVisible = false,
    VoidCallback? onTogglePassword,
    bool readOnly = false,
    bool enabled = true,
    VoidCallback? onTap,
    TextCapitalization capitalization = TextCapitalization.sentences,
    TextInputType? keyboardType,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 7),
        Container(
          decoration: BoxDecoration(
            color: enabled
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !passwordVisible,
            readOnly: readOnly || !enabled,
            onTap: onTap,
            textCapitalization: capitalization,
            keyboardType: keyboardType,
            style: TextStyle(
                color: enabled ? Colors.white : Colors.white38,
                fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  TextStyle(color: Colors.white.withValues(alpha: 0.3)),
              prefixIcon:
                  Icon(icon, color: Colors.white54, size: 19),
              suffixIcon: isPassword
                  ? IconButton(
                      onPressed: onTogglePassword,
                      icon: Icon(
                        passwordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white38,
                        size: 19,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required String hint,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 7),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white54, size: 19),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      color: value != null
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.white38,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  Widget _primaryButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
        ),
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.2),
              )
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }

  Widget _decorCircle(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );
}
