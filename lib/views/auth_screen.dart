import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:upendo_app/views/home_dashboard.dart';
import 'package:upendo_app/views/profile_payment_screen.dart';
import 'package:upendo_app/services/user_preferences.dart';
import 'package:upendo_app/models/user_model.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Login Controllers
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();

  // Register Controllers
  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _regPasswordController = TextEditingController();
  final TextEditingController _regBirthYearController = TextEditingController();
  final TextEditingController _regCountryController = TextEditingController();
  final TextEditingController _regRegionController = TextEditingController();
  final TextEditingController _regPhoneController = TextEditingController();

  DateTime? _selectedBirthDate;
  String _completePhoneNumber = '';

  bool _isLoading = false;
  final UserPreferences _userPreferences = UserPreferences();

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _regNameController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regBirthYearController.dispose();
    _regCountryController.dispose();
    _regRegionController.dispose();
    _regPhoneController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_loginEmailController.text.isEmpty ||
        _loginPasswordController.text.isEmpty) {
      _showError('Tafadhali jaza nafasi zote');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text.trim(),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          await _userPreferences.saveUserData(UserModel.fromFirestore(userDoc));
          if (mounted) {
            if (userDoc.data()?['isActive'] == true) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeDashboard()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePaymentScreen(),
                ),
              );
            }
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
    if (_regNameController.text.isEmpty ||
        _regEmailController.text.isEmpty ||
        _regPasswordController.text.isEmpty ||
        _selectedBirthDate == null ||
        _regCountryController.text.isEmpty ||
        _regRegionController.text.isEmpty ||
        _completePhoneNumber.isEmpty) {
      _showError('Tafadhali jaza nafasi zote');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _regEmailController.text.trim(),
            password: _regPasswordController.text.trim(),
          );

      if (credential.user != null) {
        // Save to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
              'fullName': _regNameController.text.trim(),
              'email': _regEmailController.text.trim(),
              'birthDate': _selectedBirthDate!.toIso8601String(),
              'country': _regCountryController.text.trim(),
              'region': _regRegionController.text.trim(),
              'phone': _completePhoneNumber,
              'isActive': false,
              'expire_date': FieldValue.serverTimestamp(),
              'createdAt': FieldValue.serverTimestamp(),
            });

        // Save to SharedPreferences
        await _userPreferences.saveUserData(
          UserModel(
            id: credential.user!.uid,
            fullName: _regNameController.text.trim(),
            region: _regRegionController.text.trim(),
            country: _regCountryController.text.trim(),
            phone: _completePhoneNumber,
          ),
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProfilePaymentScreen(),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Hitilafu imetokea wakati wa kujisajili');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF00AEEF), // Light Blue
                Color(0xFF00008B), // Dark Blue
              ],
              stops: [0.0, 1.0],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      // Stylized Moyo Logo
                      _buildMoyoLogo(),
                      const SizedBox(height: 30),

                      // Glassmorphism Tab Container
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TabBar(
                                indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                indicatorSize: TabBarIndicatorSize.tab,
                                indicatorPadding: const EdgeInsets.all(5),
                                labelColor: Colors.white,
                                unselectedLabelColor: Colors.white60,
                                labelStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                tabs: const [
                                  Tab(text: 'Ingia'),
                                  Tab(text: 'Jisajili'),
                                ],
                              ),
                              SizedBox(
                                height: 650, // Increased height for more fields
                                child: TabBarView(
                                  children: [
                                    SingleChildScrollView(
                                      child: _buildLoginForm(),
                                    ),
                                    SingleChildScrollView(
                                      child: _buildRegisterForm(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      if (!_isLoading) ...[
                        const Text(
                          'Au endelea na',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 20),

                        // Social Login Buttons (Smaller version)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildMiniSocialButton(
                                icon: Icons.facebook,
                                color: const Color(0xFF1877F2),
                                onPressed: () {},
                              ),
                              _buildMiniSocialButton(
                                icon: Icons.mail_outline,
                                color: Colors.white,
                                iconColor: Colors.red,
                                onPressed: () async => await signInWithGoogle(),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const Spacer(),
                      // Footer Text
                      Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Kwa kuendelea unakubaliana na ',
                              ),
                              TextSpan(
                                text: 'Vigezo na masharti',
                                style: const TextStyle(
                                  color: Colors.white,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            label: 'Barua Pepe',
            icon: Icons.email_outlined,
            hint: 'mfano@barua.com',
            controller: _loginEmailController,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            label: 'Nenosiri',
            icon: Icons.lock_outline,
            hint: '••••••••',
            isPassword: true,
            controller: _loginPasswordController,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Umesahau nenosiri?',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildPrimaryButton(
            text: 'INGIA',
            onPressed: _isLoading ? () {} : _login,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            label: 'Jina Kamili',
            icon: Icons.person_outline,
            controller: _regNameController,
            capitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            label: 'Barua Pepe',
            icon: Icons.email_outlined,
            controller: _regEmailController,
            capitalization: TextCapitalization.none,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            label: 'Nenosiri',
            icon: Icons.lock_outline,
            isPassword: true,
            controller: _regPasswordController,
            capitalization: TextCapitalization.none,
          ),
          const SizedBox(height: 15),
          _buildTextField(
            label: 'Tarehe ya Kuzaliwa',
            icon: Icons.calendar_today_outlined,
            hint: 'Bonyeza hapa kuchagua',
            controller: _regBirthYearController,
            readOnly: true,
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(
                  const Duration(days: 365 * 18),
                ),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() {
                  _selectedBirthDate = picked;
                  _regBirthYearController.text =
                      "${picked.day}/${picked.month}/${picked.year}";
                });
              }
            },
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'Nchi',
                  icon: Icons.public_outlined,
                  hint: 'mf. Tanzania',
                  controller: _regCountryController,
                  capitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTextField(
                  label: 'Mkoa',
                  icon: Icons.location_city_outlined,
                  hint: 'mf. Dar es Salaam',
                  controller: _regRegionController,
                  capitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildPhoneField(),
          const SizedBox(height: 25),
          _buildPrimaryButton(
            text: 'JISAJILI',
            onPressed: _isLoading ? () {} : _register,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Namba ya Simu',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IntlPhoneField(
            controller: _regPhoneController,
            decoration: InputDecoration(
              hintText: '0754 xxx xxx',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
              counterStyle: const TextStyle(color: Colors.white70),
            ),
            initialCountryCode: 'TZ',
            style: const TextStyle(color: Colors.white),
            dropdownTextStyle: const TextStyle(color: Colors.white),
            dropdownIcon: const Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
            ),
            onChanged: (phone) {
              _completePhoneNumber = phone.completeNumber;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    String? hint,
    bool isPassword = false,
    bool readOnly = false,
    VoidCallback? onTap,
    TextCapitalization capitalization = TextCapitalization.sentences,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            readOnly: readOnly,
            onTap: onTap,
            textCapitalization: capitalization,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              prefixIcon: Icon(icon, color: Colors.white70, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }

  Widget _buildMiniSocialButton({
    required IconData icon,
    required Color color,
    Color? iconColor,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor ?? Colors.white, size: 28),
      ),
    );
  }

  Future signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
          .authenticate();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = googleUser?.authentication;

      // Authenticate with Google and navigate on success
      GoogleAuthProvider.credential(idToken: googleAuth?.idToken);

      // Once signed in, return the UserCredential
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeDashboard()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Widget _buildMoyoLogo() {
    return Image.asset(
      'assets/images/moyo_logo.png',
      height: 80,
      fit: BoxFit.contain,
    );
  }
}
