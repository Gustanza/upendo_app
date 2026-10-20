import 'package:cloud_firestore/cloud_firestore.dart';

double _money(dynamic v) => (v is num) ? v.toDouble() : 0;

/// wallets/{uid} — written only by Cloud Functions (referral credits,
/// withdrawal holds/refunds). A user without a wallet doc has an empty one.
class Wallet {
  final double balance;
  final double pendingWithdrawal;
  final double totalEarned;
  final double totalWithdrawn;
  final int referralCount;

  const Wallet({
    this.balance = 0,
    this.pendingWithdrawal = 0,
    this.totalEarned = 0,
    this.totalWithdrawn = 0,
    this.referralCount = 0,
  });

  factory Wallet.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const Wallet();
    return Wallet(
      balance: _money(data['balance']),
      pendingWithdrawal: _money(data['pendingWithdrawal']),
      totalEarned: _money(data['totalEarned']),
      totalWithdrawn: _money(data['totalWithdrawn']),
      referralCount: (data['referralCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// wallets/{uid}/transactions/{id} — the wallet's ledger.
class WalletTransaction {
  static const referralCredit = 'referral_credit';
  static const withdrawalHold = 'withdrawal_hold';
  static const withdrawalRefund = 'withdrawal_refund';
  static const withdrawalPaid = 'withdrawal_paid';

  final String id;
  final String type;
  // Signed: + credit, − hold. 0 for the informational "paid" entry, whose
  // amount is in withdrawalAmount.
  final double amount;
  final double? withdrawalAmount;
  final String? fromName;
  final double? paymentAmount;
  final DateTime? createdAt;

  WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.withdrawalAmount,
    this.fromName,
    this.paymentAmount,
    this.createdAt,
  });

  factory WalletTransaction.fromFirestore(String id, Map<String, dynamic> data) {
    return WalletTransaction(
      id: id,
      type: data['type'] as String? ?? '',
      amount: _money(data['amount']),
      withdrawalAmount: (data['withdrawalAmount'] as num?)?.toDouble(),
      fromName: data['fromName'] as String?,
      paymentAmount: (data['paymentAmount'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// withdrawalRequests/{id} — created by the requestWithdrawal function,
/// resolved (paid/rejected) by an admin.
class WithdrawalRequest {
  static const pending = 'pending';
  static const paid = 'paid';
  static const rejected = 'rejected';

  final String id;
  final double amount;
  final String status;
  final String phone;
  final String? adminNote;
  final DateTime? createdAt;

  WithdrawalRequest({
    required this.id,
    required this.amount,
    required this.status,
    this.phone = '',
    this.adminNote,
    this.createdAt,
  });

  factory WithdrawalRequest.fromFirestore(String id, Map<String, dynamic> data) {
    return WithdrawalRequest(
      id: id,
      amount: _money(data['amount']),
      status: data['status'] as String? ?? pending,
      phone: data['phone'] as String? ?? '',
      adminNote: data['adminNote'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
