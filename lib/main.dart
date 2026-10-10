import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:upendo_app/utils/start_screen.dart';
import 'package:upendo_app/views/welcome_screen.dart';
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
  // google_sign_in v7 must be initialised once before authenticate(). The
  // serverClientId is the Firebase project's web OAuth client, needed on
  // Android so the returned idToken is accepted by Firebase Auth.
  await GoogleSignIn.instance.initialize(
    serverClientId:
        '630293487516-bvq0lru5161duniovg3po3blbev03hbg.apps.googleusercontent.com',
  );
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
      runApp(const NguvuYaUpendoApp(home: WelcomeScreen()));
    } else {
      // Fire-and-forget: re-register the current FCM token now that we have
      // a uid, so it gets attached to this user even if it was first
      // fetched before sign-in. Doesn't block/delay runApp() below.
      registerCurrentToken();
      try {
        // Same routing as sign-in: profile setup if details are missing,
        // otherwise payment or home.
        runApp(NguvuYaUpendoApp(home: await startScreenFor(user)));
      } catch (e) {
        // In case of error, default to welcome
        runApp(const NguvuYaUpendoApp(home: WelcomeScreen()));
      }
    }
  });
}

class NguvuYaUpendoApp extends StatelessWidget {
  final Widget home;
  const NguvuYaUpendoApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moyo App',
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
      home: home,
    );
  }
}
