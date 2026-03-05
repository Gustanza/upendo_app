import 'package:flutter/material.dart';
import 'package:upendo_app/views/welcome_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ...

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const NguvuYaUpendoApp());
}

class NguvuYaUpendoApp extends StatelessWidget {
  const NguvuYaUpendoApp({super.key});

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
      home: const WelcomeScreen(),
    );
  }
}
