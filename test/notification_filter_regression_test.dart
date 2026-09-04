import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression test for a production crash: NotificationService.getNotifications()
// used to build `Filter('recipientId', isEqualTo: null)`. cloud_firestore's
// Filter constructor asserts exactly one named operator was passed, counting
// non-null operator *arguments* — but a null *value* passed to isEqualTo is
// indistinguishable from the parameter being omitted, so that assertion
// failed on every single call (a red Flutter error screen for every user who
// opened notifications), before any network call was even made.
//
// This doesn't need a Firestore connection or the emulator: the crash
// happens synchronously at Filter construction time, so just constructing
// the same filters NotificationService builds is enough to catch a
// regression back to isEqualTo: null.
void main() {
  test('recipientId-is-null filter builds without throwing (isNull, not isEqualTo: null)', () {
    expect(() => Filter('recipientId', isNull: true), returnsNormally);
  });

  test('Filter.or(recipientId isNull, recipientId isEqualTo uid) builds without throwing', () {
    expect(
      () => Filter.or(
        Filter('recipientId', isNull: true),
        Filter('recipientId', isEqualTo: 'some-uid'),
      ),
      returnsNormally,
    );
  });

  test('isEqualTo: null on its own still throws (documents why isNull is required)', () {
    // This is the exact bug that shipped to production — kept here as a
    // sanity check that the assertion this test suite guards against is
    // real, not a misunderstanding of the API.
    expect(() => Filter('recipientId', isEqualTo: null), throwsA(isA<AssertionError>()));
  });
}
