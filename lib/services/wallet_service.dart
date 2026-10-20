import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/attachment_model.dart';
import '../models/wallet_model.dart';
import '../utils/wallet_rules.dart';

/// A withdrawal the server refused; [reason] comes from
/// functions/wallet/withdrawals.js (e.g. 'insufficient-balance').
class WithdrawalException implements Exception {
  final String reason;
  const WithdrawalException(this.reason);
  @override
  String toString() => 'WithdrawalException($reason)';
}

/// Read side of the wallet plus the withdrawal request. Clients can never
/// write wallets/ledger/withdrawalRequests (firestore.rules) — balances
/// only move inside Cloud Function transactions.
class WalletService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> get _wallet => _db.collection('wallets').doc(_uid);

  Stream<Wallet> watchWallet() => _wallet.snapshots().map((d) => Wallet.fromMap(d.data()));

  Stream<List<WalletTransaction>> watchTransactions({int limit = 50}) {
    return _wallet
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WalletTransaction.fromFirestore(d.id, d.data()))
            .toList());
  }

  Stream<List<WithdrawalRequest>> watchMyWithdrawals({int limit = 20}) {
    return _db
        .collection('withdrawalRequests')
        .where('uid', isEqualTo: _uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => WithdrawalRequest.fromFirestore(d.id, d.data()))
            .toList());
  }

  /// Uploads the ID photo to withdrawals/{uid}/ (private to the user and
  /// admins) and asks the server to reserve [amount] from the balance.
  Future<void> requestWithdrawal({
    required String fullName,
    required String phone,
    required num amount,
    required String notes,
    required WithdrawalIdType idType,
    required PendingAttachment idPhoto,
  }) async {
    final ext = idPhoto.name.contains('.') ? idPhoto.name.split('.').last.toLowerCase() : 'jpg';
    final path = 'withdrawals/$_uid/${DateTime.now().millisecondsSinceEpoch}_id.$ext';
    await FirebaseStorage.instance.ref(path).putFile(
          File(idPhoto.localPath),
          SettableMetadata(contentType: ext == 'png' ? 'image/png' : 'image/jpeg'),
        );
    try {
      await FirebaseFunctions.instance.httpsCallable('requestWithdrawal').call({
        'fullName': fullName,
        'phone': phone,
        'amount': amount,
        'notes': notes,
        'idType': idType.value,
        'idPhotoPath': path,
      });
    } on FirebaseFunctionsException catch (e) {
      final details = e.details;
      throw WithdrawalException(
          (details is Map ? details['reason'] as String? : null) ?? e.message ?? e.code);
    }
  }
}
