import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:upendo_app/views/home_dashboard.dart';
import 'package:upendo_app/views/welcome_screen.dart';
import 'package:upendo_app/views/profile_payment_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ...
const lokol = "192.168.2.197";

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await FirebaseMessaging.instance.requestPermission();
  // Wait for a valid FCM token before subscribing, avoiding the
  // "Topic subscribe failed: Not Found" error on first launch.
  Future<void> registerToken(String token) async {
    await FirebaseFunctions.instance.httpsCallable('registerFcmToken').call({
      'token': token,
    });
  }

  // Fetches the current FCM token (if any) and (re-)registers it with the
  // backend. Shared by the startup path below and the auth-state-change
  // listener further down: if the token is first fetched before the user
  // signs in, request.auth is null server-side and the token never gets
  // attached to users/{uid}.fcmTokens — calling this again right after
  // sign-in fixes that without waiting for the rare onTokenRefresh event.
  Future<void> registerCurrentToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    try {
      await registerToken(token);
    } catch (e) {
      debugPrint('FCM register error: $e');
    }
  }

  // Fire-and-forget: this has no UI dependency, so it shouldn't hold up
  // runApp() (including the unauthenticated/login screen) on a network
  // round-trip. Matches the auth-state-change re-registration call below.
  registerCurrentToken();

  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    try {
      await registerToken(newToken);
    } catch (e) {
      debugPrint('FCM re-register error: $e');
    }
  });
  // if (kDebugMode) {
  //   try {
  //     // FirebaseStorage storage = FirebaseStorage.instance;
  //     FirebaseFirestore firestore = FirebaseFirestore.instance;
  //     firestore.settings = const Settings(
  //       host: "$lokol:8080",
  //       sslEnabled: false,
  //       persistenceEnabled: false,
  //     );
  //     // await storage.useStorageEmulator("$lokol", 9199);
  //   } catch (e) {
  //     debugPrint("Abject: $e");
  //   }
  // }
  FirebaseAuth.instance.authStateChanges().listen((User? user) async {
    if (user == null) {
      runApp(const NguvuYaUpendoApp(isSignedIn: false, isActive: false));
    } else {
      // Fire-and-forget: re-register the current FCM token now that we have
      // a uid, so it gets attached to this user even if it was first
      // fetched before sign-in. Doesn't block/delay runApp() below.
      registerCurrentToken();
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
