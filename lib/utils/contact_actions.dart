import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Support numbers shown on the payment screen.
const kSupportPhoneNumbers = [
  '+255 711 781 301',
  '+255 762 506 311',
];

/// Bottom sheet letting the user call, WhatsApp, or copy [number].
Future<void> showContactOptions(BuildContext context, String number) {
  final digits = number.replaceAll(RegExp(r'[^0-9+]'), '');

  Future<void> open(BuildContext sheetCtx, Uri uri) async {
    Navigator.pop(sheetCtx);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindwa kufungua programu husika')),
      );
    }
  }

  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            number,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.call_rounded, color: Color(0xFF0072FF)),
            title: const Text('Piga simu'),
            onTap: () => open(sheetCtx, Uri(scheme: 'tel', path: digits)),
          ),
          ListTile(
            leading: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
            title: const Text('Tuma ujumbe WhatsApp'),
            onTap: () => open(
              sheetCtx,
              Uri.parse('https://wa.me/${digits.replaceFirst('+', '')}'),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.copy_rounded),
            title: const Text('Nakili namba'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: digits));
              Navigator.pop(sheetCtx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Namba imenakiliwa')),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
