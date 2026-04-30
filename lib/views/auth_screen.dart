import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:upendo_app/views/home_dashboard.dart';
import 'package:upendo_app/views/profile_payment_screen.dart';
import 'package:upendo_app/services/user_preferences.dart';
import 'package:upendo_app/models/user_model.dart';

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

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Login
  final _loginEmailCtrl    = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  bool _loginPassVisible   = false;

  // Register
  final _regNameCtrl      = TextEditingController();
  final _regEmailCtrl     = TextEditingController();
  final _regPasswordCtrl  = TextEditingController();
  final _regBirthCtrl     = TextEditingController();
  final _regCountryCtrl   = TextEditingController();
  final _regRegionCtrl    = TextEditingController();
  final _regPhoneCtrl     = TextEditingController();
  bool _regPassVisible    = false;
  String? _selectedCountry;
  DateTime? _selectedBirthDate;
  String _completePhone   = '';

  bool _isLoading = false;
  final _prefs    = UserPreferences();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _regNameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPasswordCtrl.dispose();
    _regBirthCtrl.dispose();
    _regCountryCtrl.dispose();
    _regRegionCtrl.dispose();
    _regPhoneCtrl.dispose();
    super.dispose();
  }

  // ── Auth logic (unchanged) ─────────────────────────────────────────────────

  Future<void> _login() async {
    if (_loginEmailCtrl.text.isEmpty || _loginPasswordCtrl.text.isEmpty) {
      _showError('Tafadhali jaza nafasi zote');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email:    _loginEmailCtrl.text.trim(),
        password: _loginPasswordCtrl.text.trim(),
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users').doc(user.uid).get();
        if (doc.exists) {
          await _prefs.saveUserData(UserModel.fromFirestore(doc));
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => doc.data()?['isActive'] == true
                    ? const HomeDashboard()
                    : const ProfilePaymentScreen(),
              ),
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Hitilafu imetokea wakati wa kuingia');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (_regNameCtrl.text.isEmpty ||
        _regEmailCtrl.text.isEmpty ||
        _regPasswordCtrl.text.isEmpty ||
        _selectedBirthDate == null ||
        _regCountryCtrl.text.isEmpty ||
        _regRegionCtrl.text.isEmpty ||
        _completePhone.isEmpty) {
      _showError('Tafadhali jaza nafasi zote');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email:    _regEmailCtrl.text.trim(),
        password: _regPasswordCtrl.text.trim(),
      );
      if (cred.user != null) {
        await FirebaseFirestore.instance
            .collection('users').doc(cred.user!.uid).set({
          'fullName':    _regNameCtrl.text.trim(),
          'email':       _regEmailCtrl.text.trim(),
          'birthDate':   _selectedBirthDate!.toIso8601String(),
          'country':     _regCountryCtrl.text.trim(),
          'region':      _regRegionCtrl.text.trim(),
          'phone':       _completePhone,
          'isActive':    false,
          'expire_date': FieldValue.serverTimestamp(),
          'createdAt':   FieldValue.serverTimestamp(),
        });
        await _prefs.saveUserData(UserModel(
          id:       cred.user!.uid,
          fullName: _regNameCtrl.text.trim(),
          region:   _regRegionCtrl.text.trim(),
          country:  _regCountryCtrl.text.trim(),
          phone:    _completePhone,
        ));
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePaymentScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Hitilafu imetokea wakati wa kujisajili');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleUser  = await GoogleSignIn.instance.authenticate();
      final googleAuth  = googleUser.authentication;
      GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeDashboard()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00AEEF), Color(0xFF00008B)],
                stops: [0.0, 1.0],
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -80, right: -80,
            child: _decorCircle(240, 0.07),
          ),
          Positioned(
            bottom: 60, left: -100,
            child: _decorCircle(200, 0.05),
          ),
          Positioned(
            top: 200, left: -50,
            child: _decorCircle(120, 0.04),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // ── Logo / Hero
                _buildHeroSection(),

                // ── Glass card
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2), width: 1),
                      ),
                      child: Column(
                        children: [
                          // Tab bar
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TabBar(
                              controller: _tabController,
                              indicator: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicatorPadding: const EdgeInsets.all(4),
                              labelColor: Colors.white,
                              unselectedLabelColor: Colors.white54,
                              labelStyle: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                              unselectedLabelStyle:
                                  const TextStyle(fontWeight: FontWeight.w500),
                              dividerColor: Colors.transparent,
                              tabs: const [
                                Tab(text: 'Ingia'),
                                Tab(text: 'Jisajili'),
                              ],
                            ),
                          ),
                          // Divider
                          Divider(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.15)),
                          // Tab content
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                        22, 22, 22, 22),
                                    child: _buildLoginForm()),
                                SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                        22, 18, 22, 22),
                                    child: _buildRegisterForm()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Social + footer
                _buildSocialFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 28, 0, 20),
      child: Column(
        children: [
          Image.asset('assets/images/moyo_logo.png',
              height: 64, fit: BoxFit.contain),
          const SizedBox(height: 10),
          const Text(
            'Jifunze · Kukua · Kupenda',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
      child: Column(
        children: [
          if (!_isLoading) ...[
            const Text('Au endelea na',
                style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _socialBtn(
                  icon: Icons.facebook_rounded,
                  bgColor: const Color(0xFF1877F2),
                  onPressed: () {},
                ),
                const SizedBox(width: 16),
                _socialBtn(
                  icon: Icons.mail_outline_rounded,
                  bgColor: Colors.white,
                  iconColor: Colors.red,
                  onPressed: signInWithGoogle,
                ),
              ],
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 12),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(color: Colors.white54, fontSize: 11),
                children: [
                  const TextSpan(text: 'Kwa kuendelea unakubaliana na '),
                  TextSpan(
                    text: 'Vigezo na masharti',
                    style: const TextStyle(
                        color: Colors.white,
                        decoration: TextDecoration.underline),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Login form ─────────────────────────────────────────────────────────────

  Widget _buildLoginForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          label: 'Barua Pepe',
          icon: Icons.email_outlined,
          hint: 'mfano@barua.com',
          controller: _loginEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          capitalization: TextCapitalization.none,
        ),
        const SizedBox(height: 14),
        _field(
          label: 'Nenosiri',
          icon: Icons.lock_outline_rounded,
          hint: '••••••••',
          controller: _loginPasswordCtrl,
          isPassword: true,
          passwordVisible: _loginPassVisible,
          onTogglePassword: () =>
              setState(() => _loginPassVisible = !_loginPassVisible),
          capitalization: TextCapitalization.none,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 4)),
            child: const Text('Umesahau nenosiri?',
                style: TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(height: 6),
        _primaryButton(text: 'INGIA', onPressed: _login),
      ],
    );
  }

  // ── Register form ──────────────────────────────────────────────────────────

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section: Taarifa za Kibinafsi
        _sectionLabel('Taarifa za Kibinafsi'),
        const SizedBox(height: 10),
        _field(
          label: 'Jina Kamili',
          icon: Icons.person_outline_rounded,
          controller: _regNameCtrl,
          capitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 12),
        _field(
          label: 'Tarehe ya Kuzaliwa',
          icon: Icons.cake_outlined,
          hint: 'Bonyeza hapa kuchagua',
          controller: _regBirthCtrl,
          readOnly: true,
          onTap: _pickBirthDate,
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

        const SizedBox(height: 20),
        // Section: Akaunti
        _sectionLabel('Akaunti'),
        const SizedBox(height: 10),
        _field(
          label: 'Barua Pepe',
          icon: Icons.email_outlined,
          hint: 'mfano@barua.com',
          controller: _regEmailCtrl,
          keyboardType: TextInputType.emailAddress,
          capitalization: TextCapitalization.none,
        ),
        const SizedBox(height: 12),
        _field(
          label: 'Nenosiri',
          icon: Icons.lock_outline_rounded,
          hint: '••••••••',
          controller: _regPasswordCtrl,
          isPassword: true,
          passwordVisible: _regPassVisible,
          onTogglePassword: () =>
              setState(() => _regPassVisible = !_regPassVisible),
          capitalization: TextCapitalization.none,
        ),
        const SizedBox(height: 12),
        _buildPhoneField(),
        const SizedBox(height: 24),
        _primaryButton(text: 'JISAJILI', onPressed: _register),
      ],
    );
  }

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF00AEEF),
            onPrimary: Colors.white,
            surface: Color(0xFF0a1a6e),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _regBirthCtrl.text =
            '${picked.day}/${picked.month}/${picked.year}';
      });
    }
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

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Text(text,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1)),
        const SizedBox(width: 8),
        Expanded(
            child: Divider(
                color: Colors.white.withValues(alpha: 0.15), height: 1)),
      ],
    );
  }

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
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0072FF).withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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
                  letterSpacing: 1.4,
                ),
              ),
      ),
    );
  }

  Widget _socialBtn({
    required IconData icon,
    required Color bgColor,
    Color? iconColor,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 24),
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
