import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:upendo_app/views/home_dashboard.dart';
import 'package:upendo_app/views/welcome_screen.dart';
import 'package:upendo_app/views/profile_payment_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user == null) {
      runApp(const NguvuYaUpendoApp(isSignedIn: false, isActive: false));
    } else {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final bool isActive =
            userDoc.exists && userDoc.data()?['isActive'] == true;
        runApp(NguvuYaUpendoApp(isSignedIn: true, isActive: isActive));
      } catch (e) {
        // In case of error, default to inactive/welcome
        runApp(const NguvuYaUpendoApp(isSignedIn: false, isActive: false));
      }
    }
  });
}

class NguvuYaUpendoApp extends StatelessWidget {
  final bool isSignedIn;
  final bool isActive;
  const NguvuYaUpendoApp({
    super.key,
    required this.isSignedIn,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nguvu ya Upendo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B2942),
          brightness: Brightness.light,
          primary: const Color(0xFF8B2942),
          secondary: const Color(0xFFD4A574),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Color(0xFF8B2942),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
        ),
      ),
      home: isSignedIn
          ? (isActive ? const HomeDashboard() : const ProfilePaymentScreen())
          : const WelcomeScreen(),
    );
  }
}
