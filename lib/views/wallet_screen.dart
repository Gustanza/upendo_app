import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/l10n.dart';
import '../models/wallet_model.dart';
import '../services/wallet_service.dart';
import '../utils/wallet_rules.dart';
import '../widgets/referral_code_card.dart';
import 'withdraw_screen.dart';

/// Referral earnings: balance, withdrawal requests and the ledger. Every
/// figure here is computed server-side; this screen only reads.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _service = WalletService();
  late final Stream<Wallet> _wallet = _service.watchWallet();
  late final Stream<List<WalletTransaction>> _transactions = _service.watchTransactions();
  late final Stream<List<WithdrawalRequest>> _withdrawals = _service.watchMyWithdrawals();

  String _date(DateTime? d) => d == null
      ? ''
      : DateFormat.yMMMd(Localizations.localeOf(context).toString()).add_Hm().format(d);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(title: Text(l10n.walletTitle)),
      body: StreamBuilder<Wallet>(
        stream: _wallet,
        builder: (context, walletSnap) {
          final wallet = walletSnap.data ?? const Wallet();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _balanceCard(wallet),
              const SizedBox(height: 16),
              const ReferralCodeCard(),
              const SizedBox(height: 20),
              _sectionTitle(l10n.withdrawalRequests),
              StreamBuilder<List<WithdrawalRequest>>(
                stream: _withdrawals,
                builder: (context, snap) {
                  final items = snap.data ?? const <WithdrawalRequest>[];
                  if (items.isEmpty) return _emptyText(l10n.noWithdrawalsYet);
                  return Column(children: items.map(_withdrawalTile).toList());
                },
              ),
              const SizedBox(height: 20),
              _sectionTitle(l10n.walletHistory),
              StreamBuilder<List<WalletTransaction>>(
                stream: _transactions,
                builder: (context, snap) {
                  final items = snap.data ?? const <WalletTransaction>[];
                  if (items.isEmpty) return _emptyText(l10n.noWalletTransactionsYet);
                  return Column(children: items.map(_transactionTile).toList());
                },
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _balanceCard(Wallet wallet) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B2942), Color(0xFF5E1A2C)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.walletBalance, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            formatTzs(wallet.balance),
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _stat(l10n.walletPending, formatTzs(wallet.pendingWithdrawal)),
              _stat(l10n.walletTotalEarned, formatTzs(wallet.totalEarned)),
              _stat(l10n.walletReferrals, '${wallet.referralCount}'),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => WithdrawScreen(balance: wallet.balance)),
              ),
              icon: const Icon(Icons.account_balance_wallet_rounded),
              label: Text(l10n.withdraw),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A574),
                foregroundColor: const Color(0xFF2A0F17),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.withdrawMinimum(formatTzs(kMinWithdrawalTzs)),
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          Text(value,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      );

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1D2E))),
      );

  Widget _emptyText(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(text, style: const TextStyle(color: Colors.grey)),
      );

  Widget _withdrawalTile(WithdrawalRequest r) {
    final l10n = context.l10n;
    final (label, color) = switch (r.status) {
      WithdrawalRequest.paid => (l10n.withdrawalStatusPaid, const Color(0xFF10B981)),
      WithdrawalRequest.rejected => (l10n.withdrawalStatusRejected, Colors.redAccent),
      _ => (l10n.withdrawalStatusPending, const Color(0xFFF59E0B)),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.payments_outlined, color: color),
        title: Text(formatTzs(r.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text([
          _date(r.createdAt),
          if (r.adminNote != null && r.adminNote!.isNotEmpty) r.adminNote!,
        ].join('\n')),
        trailing: Chip(
          label: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
          backgroundColor: color.withValues(alpha: 0.1),
          side: BorderSide.none,
        ),
      ),
    );
  }

  Widget _transactionTile(WalletTransaction t) {
    final l10n = context.l10n;
    final String title;
    final IconData icon;
    final Color color;
    String amountText = '${t.amount >= 0 ? '+' : '−'}${formatTzs(t.amount.abs())}';
    switch (t.type) {
      case WalletTransaction.referralCredit:
        title = l10n.txReferralCredit(t.fromName?.isNotEmpty == true ? t.fromName! : l10n.userFallbackName);
        icon = Icons.card_giftcard_rounded;
        color = const Color(0xFF10B981);
      case WalletTransaction.withdrawalHold:
        title = l10n.txWithdrawalRequested;
        icon = Icons.north_east_rounded;
        color = const Color(0xFFF59E0B);
      case WalletTransaction.withdrawalRefund:
        title = l10n.txWithdrawalRefunded;
        icon = Icons.undo_rounded;
        color = const Color(0xFF0077C2);
      case WalletTransaction.withdrawalPaid:
        title = l10n.txWithdrawalPaid;
        icon = Icons.check_circle_rounded;
        color = const Color(0xFF10B981);
        amountText = formatTzs(t.withdrawalAmount ?? 0);
      default:
        title = t.type;
        icon = Icons.receipt_long_rounded;
        color = Colors.grey;
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(_date(t.createdAt), style: const TextStyle(fontSize: 12)),
        trailing: Text(amountText,
            style: TextStyle(fontWeight: FontWeight.w800, color: color)),
      ),
    );
  }
}
