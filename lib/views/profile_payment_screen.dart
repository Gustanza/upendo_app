import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:upendo_app/views/home_dashboard.dart';

class ProfilePaymentScreen extends StatefulWidget {
  const ProfilePaymentScreen({super.key});

  @override
  State<ProfilePaymentScreen> createState() => _ProfilePaymentScreenState();
}

class _ProfilePaymentScreenState extends State<ProfilePaymentScreen> {
  final TextEditingController _mpesaNumberController = TextEditingController();
  final TextEditingController _paymentCodeController = TextEditingController();

  bool _isLoading = false;
  String? _lastSubmittedData;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _mpesaNumberController.dispose();
    _paymentCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleEndelea() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // 1. Fresh check for isActive
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists && userDoc.data()?['isActive'] == true) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeDashboard()),
          );
        }
        return;
      }

      // 2. If not active, check if we need to submit a new payment request
      final String currentData =
          "${_mpesaNumberController.text.trim()}-${_paymentCodeController.text.trim()}";

      if (_mpesaNumberController.text.isEmpty ||
          _paymentCodeController.text.isEmpty) {
        setState(() {
          _errorMessage = 'Tafadhali jaza namba ya simu na code ya malipo';
          _isLoading = false;
        });
        return;
      }

      if (currentData != _lastSubmittedData) {
        // Submit new request
        await FirebaseFirestore.instance.collection('payment_requests').add({
          'userId': user.uid,
          'userEmail': user.email,
          'mpesaNumber': _mpesaNumberController.text.trim(),
          'paymentCode': _paymentCodeController.text.trim(),
          'amount': 3000,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        _lastSubmittedData = currentData;
        setState(() {
          _successMessage = 'Ombi lako limetumwa. Subiri uhakiki wa Admin.';
        });
      } else {
        setState(() {
          _errorMessage = 'Ombi lako bado linashughulikiwa. Subiri kidogo.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Hitilafu imetokea. Jaribu tena baadae.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
            colors: [
              Color(0xFF00AEEF), // Light Blue
              Color(0xFF00008B), // Dark Blue
            ],
            stops: [0.0, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header Image with Fade
                SizedBox(
                  height: 250,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: ShaderMask(
                          shaderCallback: (rect) {
                            return const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black, Colors.transparent],
                              stops: [0.7, 1.0],
                            ).createShader(rect);
                          },
                          blendMode: BlendMode.dstIn,
                          child: Image.asset(
                            'assets/images/g272.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Stylized Moyo Logo (Smaller for this screen)
                const SizedBox(height: 10),
                _buildMoyoLogo(),
                const SizedBox(height: 10),

                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 5,
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (_successMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 5,
                    ),
                    child: Text(
                      _successMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.lightGreenAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 15),
                const Text(
                  'Lipa kwa M-pesa',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 10),

                // M-pesa Logo Placeholder
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.radio_button_checked,
                        color: Colors.red,
                        size: 30,
                      ),
                      const SizedBox(width: 5),
                      const VerticalDivider(width: 1, color: Colors.grey),
                      const SizedBox(width: 5),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.phone_android,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                          const Text(
                            'm-pesa',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // Payment Box (Red Container)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildPaymentRow('Kifurushi:', _buildPackageDisplay()),
                      const SizedBox(height: 15),
                      _buildPaymentRow(
                        'Andika Namba\nitakayolipia;',
                        _buildPaymentTextField(
                          'mf. 0754 xxx xxx',
                          _mpesaNumberController,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildPaymentRow(
                        'Code ya malipo:',
                        _buildPaymentTextField(
                          'mf. RQX7...',
                          _paymentCodeController,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ENDELEA Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleEndelea,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AEEF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'ENDELEA',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoyoLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLogoLetter('M', 40),
        const Icon(Icons.favorite, color: Colors.pinkAccent, size: 25),
        _buildLogoLetter('y', 40),
        const Icon(Icons.favorite, color: Colors.pinkAccent, size: 25),
      ],
    );
  }

  Widget _buildLogoLetter(String letter, double size) {
    return Text(
      letter,
      style: TextStyle(
        color: Colors.white,
        fontSize: size,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.pinkAccent.withOpacity(0.5),
            blurRadius: 5,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, Widget field) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(flex: 3, child: field),
      ],
    );
  }

  Widget _buildPackageDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Mwezi 1 - Tsh: 3,000/=',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPaymentTextField(String hint, TextEditingController controller) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
          isDense: true,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
