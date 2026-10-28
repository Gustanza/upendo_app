// TEST-ONLY HARNESS — never active in release/profile builds.
//
// Wires the app to the LOCAL Firebase emulators and (optionally) signs in an
// email/password test account on the Auth emulator, because Google sign-in
// can't work on an emulator without a device account.
//
// Active only when BOTH hold:
//   * kDebugMode (a compile-time const: false in profile/release, so the
//     whole body is tree-shaken out of those builds), and
//   * --dart-define=USE_FIREBASE_EMULATORS=true was passed.
//
// Usage (Android emulator; the host is 10.0.2.2 from inside it):
//   flutter run -d emulator-5554 --dart-define=USE_FIREBASE_EMULATORS=true \
//     --dart-define=TEST_EMAIL=alice@test.moyo --dart-define=TEST_PASSWORD=secret123
//   flutter test integration_test/e2e_journeys_test.dart -d emulator-5554 \
//     --dart-define=USE_FIREBASE_EMULATORS=true
// Ports match firebase.json (auth 9099, firestore 8080, storage 9199,
// functions 5001). Debug-only cleartext to 10.0.2.2 is allowed by
// android/app/src/debug/res/xml/network_security_config.xml.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

const bool _useEmulatorsDefine = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
const String _emulatorHost = String.fromEnvironment('EMULATOR_HOST', defaultValue: '10.0.2.2');
const String _testEmail = String.fromEnvironment('TEST_EMAIL');
const String _testPassword = String.fromEnvironment('TEST_PASSWORD');

/// True only in a debug build started with USE_FIREBASE_EMULATORS=true.
const bool kUsingFirebaseEmulators = kDebugMode && _useEmulatorsDefine;

bool _connected = false;

/// Call right after Firebase.initializeApp(). No-op unless
/// [kUsingFirebaseEmulators]. Safe to call more than once.
Future<void> connectFirebaseEmulatorsIfRequested() async {
  if (!kUsingFirebaseEmulators || _connected) return;
  _connected = true;
  debugPrint('[emulator_harness] using Firebase emulators at $_emulatorHost');
  await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
  FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
  // No stale cache from a previous emulator run.
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
  await FirebaseStorage.instance.useStorageEmulator(_emulatorHost, 9199);
  FirebaseFunctions.instance.useFunctionsEmulator(_emulatorHost, 5001);
}

/// Signs in TEST_EMAIL/TEST_PASSWORD on the Auth emulator if both were
/// passed (debug + emulators only). Returns true when it signed in.
Future<bool> signInTestAccountIfRequested() async {
  if (!kUsingFirebaseEmulators || _testEmail.isEmpty || _testPassword.isEmpty) return false;
  final current = FirebaseAuth.instance.currentUser;
  if (current?.email == _testEmail) return true;
  await FirebaseAuth.instance.signInWithEmailAndPassword(email: _testEmail, password: _testPassword);
  debugPrint('[emulator_harness] signed in $_testEmail');
  return true;
}
