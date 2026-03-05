import 'package:flutter/material.dart';
import 'package:upendo_app/views/home_dashboard.dart';

class ProfilePaymentScreen extends StatelessWidget {
  const ProfilePaymentScreen({super.key});

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
                const Text(
                  'Andika Taarifa zako',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),

                // Form Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      _buildInlineLabelField('Jina:', ''),
                      const SizedBox(height: 10),
                      _buildInlineLabelField('Mwaka wa Kuzaliwa:', ''),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildInlineLabelField('Nchi:', '')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInlineLabelField('Mkoa:', '')),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: _buildInlineLabelField('Simu:', '')),
                          const SizedBox(width: 10),
                          Expanded(child: _buildInlineLabelField('email:', '')),
                        ],
                      ),
                    ],
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
                      // Simulated Vodacom logo
                      const Icon(
                        Icons.radio_button_checked,
                        color: Colors.red,
                        size: 30,
                      ),
                      const SizedBox(width: 5),
                      const VerticalDivider(width: 1, color: Colors.grey),
                      const SizedBox(width: 5),
                      // Simulated M-pesa logo
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
                      _buildPaymentRow('Kifurushi:', _buildDropdown()),
                      const SizedBox(height: 10),
                      _buildPaymentRow(
                        'Andika Namba\nitakayolipia;',
                        _buildPaymentTextField('mf. 0754 xxx xxx'),
                      ),
                      const SizedBox(height: 10),
                      _buildPaymentRow(
                        'Code ya malipo:',
                        _buildPaymentTextField(''),
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HomeDashboard(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00AEEF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
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

  Widget _buildInlineLabelField(String label, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 13),
            ),
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

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: const [
          Expanded(
            child: Text(
              'Kwa siku - Tsh: 1,000/=',
              style: TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.more_vert, size: 16),
        ],
      ),
    );
  }

  Widget _buildPaymentTextField(String hint) {
    return Container(
      height: 35,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
          isDense: true,
          border: InputBorder.none,
        ),
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
