import 'package:flutter/material.dart';
import 'package:upendo_app/views/profile_payment_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

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
          child: Column(
            children: [
              // Header Image with Fade (Reusing style from WelcomeScreen)
              Expanded(
                flex: 4,
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
              const SizedBox(height: 20),
              // Stylized Moyo Logo
              _buildMoyoLogo(),
              const SizedBox(height: 20),
              const Text(
                'Jisajili Sasa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tengeneza akaunti yako kwa njia zifuatazo',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 30),
              // Social Login Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  children: [
                    _buildSocialButton(
                      text: 'Endelea na Facebook',
                      color: const Color(0xFF0077C2), // Facebook Blue
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePaymentScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    _buildSocialButton(
                      text: 'Endelea na Gmail',
                      color: const Color(0xFFFF0000), // Gmail Red
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePaymentScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Footer Text
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 30.0,
                  left: 30,
                  right: 30,
                ),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    children: [
                      const TextSpan(
                        text: 'Kwa kujisajili humu unakubaliana na ',
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
    );
  }

  Widget _buildMoyoLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLogoLetter('M'),
        Icon(Icons.favorite, color: Colors.pinkAccent.shade100, size: 40),
        _buildLogoLetter('y'),
        Icon(Icons.favorite, color: Colors.pinkAccent.shade100, size: 40),
      ],
    );
  }

  Widget _buildLogoLetter(String letter) {
    return Text(
      letter,
      style: TextStyle(
        color: Colors.white,
        fontSize: 64,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.pinkAccent.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(2, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
