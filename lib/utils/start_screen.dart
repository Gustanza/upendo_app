import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/user_preferences.dart';
import '../views/home_dashboard.dart';
import '../views/profile_payment_screen.dart';
import '../views/profile_setup_screen.dart';

/// Profile fields every account must have before using the app. Google
/// sign-in only gives us a name and email, so new users (and older Google
/// accounts created with blank fields) are sent to ProfileSetupScreen first.
bool isProfileComplete(Map<String, dynamic>? data) {
  if (data == null) return false;
  bool filled(String key) => (data[key] as String? ?? '').trim().isNotEmpty;
  return filled('fullName') && filled('country') && filled('region') && filled('phone');
}

/// The screen a signed-in user should land on. Shared by app start-up
/// (main.dart), sign-in (AuthScreen) and profile setup, so the routing
/// rules live in one place.
Future<Widget> startScreenFor(User user) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  if (!isProfileComplete(doc.data())) return const ProfileSetupScreen();

  await UserPreferences().saveUserData(UserModel.fromFirestore(doc));
  return doc.data()?['isActive'] == true
      ? const HomeDashboard()
      : const ProfilePaymentScreen();
}
