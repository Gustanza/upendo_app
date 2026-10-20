import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../l10n/l10n.dart';
import '../utils/links.dart';

Future<void> openExternalLink(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = context.l10n.openLinkFailed;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok) messenger.showSnackBar(SnackBar(content: Text(failed)));
}

/// Text with any http(s)/www. URLs rendered as tappable links that open in
/// the browser.
class LinkifiedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Color linkColor;
  final int? maxLines;

  const LinkifiedText(
    this.text, {
    super.key,
    this.style,
    this.linkColor = const Color(0xFF0077C2),
    this.maxLines,
  });

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final segments = splitLinks(widget.text);
    if (segments.every((s) => !s.isLink)) {
      return Text(
        widget.text,
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.maxLines == null ? null : TextOverflow.ellipsis,
      );
    }
    final children = <InlineSpan>[];
    for (final s in segments) {
      if (!s.isLink) {
        children.add(TextSpan(text: s.text));
        continue;
      }
      final recognizer = TapGestureRecognizer()
        ..onTap = () => openExternalLink(context, s.link!);
      _recognizers.add(recognizer);
      children.add(TextSpan(
        text: s.text,
        style: TextStyle(
          color: widget.linkColor,
          decoration: TextDecoration.underline,
          decorationColor: widget.linkColor,
        ),
        recognizer: recognizer,
      ));
    }
    return Text.rich(
      TextSpan(style: widget.style, children: children),
      maxLines: widget.maxLines,
      overflow: widget.maxLines == null ? null : TextOverflow.ellipsis,
    );
  }
}

/// Basic preview card for a shared link: page title, description and image
/// scraped from its HTML (OpenGraph tags or <title>), falling back to just
/// the domain when the page can't be fetched. Results are cached per URL
/// for the app session.
class LinkPreviewCard extends StatefulWidget {
  final Uri url;
  const LinkPreviewCard({super.key, required this.url});

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  static final Map<String, Future<LinkMetadata>> _cache = {};
  late final Future<LinkMetadata> _metadata =
      _cache.putIfAbsent(widget.url.toString(), () => _fetch(widget.url));

  static Future<LinkMetadata> _fetch(Uri url) async {
    try {
      final resp = await http
          .get(url, headers: {'User-Agent': 'Mozilla/5.0 (MoyoApp link preview)'})
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200) return const LinkMetadata();
      final type = resp.headers['content-type'] ?? '';
      if (!type.contains('html')) return const LinkMetadata();
      // Only the <head> matters; cap what we scan on huge pages.
      final body = utf8.decode(resp.bodyBytes, allowMalformed: true);
      final head = body.length > 200000 ? body.substring(0, 200000) : body;
      return parseLinkMetadata(head, url);
    } catch (_) {
      return const LinkMetadata();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LinkMetadata>(
      future: _metadata,
      builder: (context, snapshot) {
        final meta = snapshot.data ?? const LinkMetadata();
        return Material(
          color: const Color(0xFFF4F6FB),
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => openExternalLink(context, widget.url),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (meta.imageUrl != null)
                  Image.network(
                    meta.imageUrl!,
                    height: 140,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, size: 20, color: Color(0xFF8B2942)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              meta.title ?? displayHost(widget.url),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            if (meta.description != null)
                              Text(
                                meta.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                            Text(
                              displayHost(widget.url),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF0077C2)),
                            ),
                          ],
                        ),
                      ),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
