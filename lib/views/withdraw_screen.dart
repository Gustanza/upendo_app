import 'dart:io';

import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../models/attachment_model.dart';
import '../services/attachment_service.dart';
import '../services/wallet_service.dart';
import '../utils/wallet_rules.dart';

/// Withdrawal request form. The server re-validates everything and reserves
/// the amount atomically; this only catches obvious mistakes early.
class WithdrawScreen extends StatefulWidget {
  final double balance;
  const WithdrawScreen({super.key, required this.balance});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  WithdrawalIdType _idType = WithdrawalIdType.nationalId;
  PendingAttachment? _idPhoto;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  String _idTypeLabel(WithdrawalIdType t) {
    final l10n = context.l10n;
    return switch (t) {
      WithdrawalIdType.nationalId => l10n.idTypeNational,
      WithdrawalIdType.driversLicense => l10n.idTypeDriversLicense,
      WithdrawalIdType.passport => l10n.idTypePassport,
    };
  }

  Future<void> _pickPhoto({required bool camera}) async {
    final service = AttachmentService();
    final picked = camera
        ? await service.takePhoto()
        : (await service.pickImages(1)).firstOrNull;
    if (picked != null && mounted) setState(() => _idPhoto = picked);
  }

  String _reasonMessage(String reason) {
    final l10n = context.l10n;
    return switch (reason) {
      'insufficient-balance' => l10n.withdrawErrorBalance,
      'below-minimum' => l10n.withdrawMinimum(formatTzs(kMinWithdrawalTzs)),
      'invalid-phone' => l10n.withdrawErrorPhone,
      'invalid-name' => l10n.withdrawErrorName,
      _ => l10n.errorWithDetails(reason),
    };
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (_idPhoto == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.withdrawErrorIdPhoto)));
      return;
    }
    setState(() => _submitting = true);
    try {
      await WalletService().requestWithdrawal(
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        amount: num.parse(_amount.text.replaceAll(',', '').trim()),
        notes: _notes.text.trim(),
        idType: _idType,
        idPhoto: _idPhoto!,
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.withdrawSubmitted)));
      Navigator.pop(context, true);
    } on WithdrawalException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        messenger.showSnackBar(SnackBar(content: Text(_reasonMessage(e.reason))));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorWithDetails('$e'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.withdraw)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${l10n.walletBalance}: ${formatTzs(widget.balance)}\n'
                '${l10n.withdrawMinimum(formatTzs(kMinWithdrawalTzs))}',
                style: const TextStyle(fontWeight: FontWeight.w600, height: 1.5),
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.fullName, border: const OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().length < 3) ? l10n.withdrawErrorName : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.withdrawPhoneLabel,
                hintText: '+255 7XX XXX XXX',
                border: const OutlineInputBorder(),
              ),
              validator: (v) => RegExp(r'^\+?[0-9][0-9 ]{7,18}$').hasMatch(v?.trim() ?? '')
                  ? null
                  : l10n.withdrawErrorPhone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.withdrawAmountLabel,
                prefixText: 'TZS ',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final amount = num.tryParse((v ?? '').replaceAll(',', '').trim());
                return switch (checkWithdrawalAmount(amount, widget.balance)) {
                  WithdrawalAmountError.invalid => l10n.withdrawErrorAmount,
                  WithdrawalAmountError.belowMinimum =>
                    l10n.withdrawMinimum(formatTzs(kMinWithdrawalTzs)),
                  WithdrawalAmountError.aboveBalance => l10n.withdrawErrorBalance,
                  null => null,
                };
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(labelText: l10n.withdrawNotesLabel, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<WithdrawalIdType>(
              initialValue: _idType,
              decoration: InputDecoration(labelText: l10n.withdrawIdTypeLabel, border: const OutlineInputBorder()),
              items: WithdrawalIdType.values
                  .map((t) => DropdownMenuItem(value: t, child: Text(_idTypeLabel(t))))
                  .toList(),
              onChanged: (t) => setState(() => _idType = t ?? _idType),
            ),
            const SizedBox(height: 14),
            Text(l10n.withdrawIdPhotoLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (_idPhoto != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(_idPhoto!.localPath), height: 180, fit: BoxFit.cover),
              ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: _submitting ? null : () => _pickPhoto(camera: true),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.takePhoto),
                ),
                TextButton.icon(
                  onPressed: _submitting ? null : () => _pickPhoto(camera: false),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.chooseFromGallery),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2942),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l10n.withdrawSubmit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
