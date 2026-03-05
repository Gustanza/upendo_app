import 'package:flutter/material.dart';
import 'package:upendo_app/views/auth_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _onNextPressed() {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
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
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [_buildFirstPage(), _buildSecondPage()],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // "ENDELEA" Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _onNextPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF00AEEF,
                          ), // Cyan/Light Blue
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'ENDELEA',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Page Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPageIndicator(_currentPage == 0),
                        _buildPageIndicator(_currentPage == 1),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirstPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // Stylized Moyo Logo
          _buildMoyoLogo(),
          const Spacer(flex: 2),
          // Welcome Text
          const Text(
            'Karibu\nKatika Upendo App',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Hii ni App kwa ajili gani',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Lorem ipsum dolor sit amet, consectetuer\nadipiscing elit, sed diam nonummy nibh\neuismod tincidunt ut laoreet dolore',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildSecondPage() {
    return Column(
      children: [
        // Header Image with Fade
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
                      stops: [
                        0.7,
                        1.0,
                      ], // Adjust this to control where it starts fading
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
          'Humu utafaidika nini?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 15),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.0),
          child: Text(
            'Lorem ipsum dolor sit amet, consectetuer\nadipiscing elit, sed diam nonummy nibh\neuismod tincidunt ut laoreet dolore',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
        ),
        const Spacer(flex: 1),
      ],
    );
  }

  Widget _buildMoyoLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'M',
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
        ),
        Icon(Icons.favorite, color: Colors.pinkAccent.shade100, size: 40),
        Text(
          'y',
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
        ),
        Icon(Icons.favorite, color: Colors.pinkAccent.shade100, size: 40),
      ],
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 12.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
