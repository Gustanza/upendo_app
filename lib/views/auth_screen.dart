import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:upendo_app/utils/start_screen.dart';

/// Single entry point for both new and returning users: one Google button.
/// Where the user lands afterwards (profile setup, payment or home) is
/// decided by startScreenFor.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final credential = GoogleAuthProvider.credential(
        idToken: googleUser.authentication.idToken,
      );
      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCred.user;
      if (user == null) return;

      final next = await startScreenFor(user);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => next),
          (_) => false,
        );
      }
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) {
        _showError(e.description ?? 'Imeshindwa kuingia na Google');
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Hitilafu imetokea wakati wa kuingia');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00AEEF), Color(0xFF00008B)],
              ),
            ),
          ),
          // Decorative circles
          Positioned(top: -80, right: -80, child: _decorCircle(240, 0.07)),
          Positioned(bottom: 60, left: -100, child: _decorCircle(200, 0.05)),
          Positioned(top: 200, left: -50, child: _decorCircle(120, 0.04)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 3),
                  Image.asset('assets/images/logo.png',
                      height: 72, fit: BoxFit.contain),
                  const SizedBox(height: 12),
                  const Text(
                    'Jifunze · Kukua · Kupenda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(flex: 2),
                  const Text(
                    'Karibu Moyo App',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Endelea kwa akaunti yako ya Google',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 14),
                  ),
                  const SizedBox(height: 28),
                  _googleButton(),
                  const Spacer(flex: 3),
                  _buildTerms(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _googleButton() {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.white70,
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Color(0xFF0072FF), strokeWidth: 2.2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'ENDELEA NA GOOGLE',
                    style: TextStyle(
                      color: Color(0xFF1a1d2e),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTerms() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(color: Colors.white54, fontSize: 11),
          children: [
            TextSpan(text: 'Kwa kuendelea unakubaliana na '),
            TextSpan(
              text: 'Vigezo na masharti',
              style: TextStyle(
                  color: Colors.white, decoration: TextDecoration.underline),
            ),
          ],
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
