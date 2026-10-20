import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/l10n.dart';
import '../services/referral_service.dart';
import '../utils/share_app.dart';
import '../utils/wallet_rules.dart';

/// "Your referral code" card: generate (once, server-side), copy, share.
/// The code is read live from users/{uid}.referralCode, which only the
/// generateReferralCode function writes.
class ReferralCodeCard extends StatefulWidget {
  const ReferralCodeCard({super.key});

  @override
  State<ReferralCodeCard> createState() => _ReferralCodeCardState();
}

class _ReferralCodeCardState extends State<ReferralCodeCard> {
  final ReferralService _service = ReferralService();
  late final Stream<String?> _code = FirebaseFirestore.instance
      .collection('users')
      .doc(FirebaseAuth.instance.currentUser!.uid)
      .snapshots()
      .map((d) => d.data()?['referralCode'] as String?);
  bool _generating = false;

  Future<void> _generate() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _generating = true);
    try {
      await _service.generateMyCode();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.referralGenerateFailed('$e'))));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _copy(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.referralCodeCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD4A574).withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: StreamBuilder<String?>(
        stream: _code,
        builder: (context, snapshot) {
          final code = snapshot.data;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.card_giftcard_rounded, color: Color(0xFF8B2942)),
                  const SizedBox(width: 8),
                  Text(l10n.referralCodeTitle,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.referralCodeExplainer((kReferralCommissionRate * 100).round()),
                style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 14),
              if (code == null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _generating || snapshot.connectionState == ConnectionState.waiting
                        ? null
                        : _generate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B2942),
                      foregroundColor: Colors.white,
                    ),
                    child: _generating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l10n.referralGenerate),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF4F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SelectableText(
                          code,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: Color(0xFF8B2942),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: l10n.copy,
                      onPressed: () => _copy(code),
                      icon: const Icon(Icons.copy_rounded),
                    ),
                    Builder(
                      builder: (btnContext) => IconButton.filled(
                        tooltip: l10n.share,
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFF8B2942)),
                        onPressed: () => shareReferralCode(btnContext, code),
                        icon: const Icon(Icons.share_rounded),
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
