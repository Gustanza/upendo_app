// URL detection for post/message text and group-post links. Pure (no
// Flutter imports) so it's unit-tested in test/links_test.dart.

final RegExp _urlPattern = RegExp(
  r'((?:https?:\/\/|www\.)[^\s<>"]+)',
  caseSensitive: false,
);

// Punctuation that usually ends the sentence rather than the URL.
const _trailing = '.,;:!?)]}\'"';

/// A run of text that is either plain or a link.
class TextSegment {
  final String text;
  final Uri? link;
  const TextSegment(this.text, [this.link]);
  bool get isLink => link != null;
}

/// Turns user input like "www.example.com" or "https://x.y/path" into an
/// http(s) Uri, or null if it isn't a usable web link.
Uri? normalizeUrl(String raw) {
  var value = raw.trim();
  if (value.isEmpty || value.contains(RegExp(r'\s'))) return null;
  if (!value.toLowerCase().startsWith('http://') &&
      !value.toLowerCase().startsWith('https://')) {
    value = 'https://$value';
  }
  final uri = Uri.tryParse(value);
  if (uri == null) return null;
  if (uri.scheme != 'http' && uri.scheme != 'https') return null;
  if (uri.host.isEmpty || !uri.host.contains('.')) return null;
  return uri;
}

/// Splits [text] into plain and link segments, trimming trailing sentence
/// punctuation off detected URLs.
List<TextSegment> splitLinks(String text) {
  final segments = <TextSegment>[];
  var index = 0;
  for (final match in _urlPattern.allMatches(text)) {
    var candidate = match.group(0)!;
    var end = match.end;
    while (candidate.isNotEmpty && _trailing.contains(candidate[candidate.length - 1])) {
      candidate = candidate.substring(0, candidate.length - 1);
      end--;
    }
    final uri = normalizeUrl(candidate);
    if (uri == null) continue;
    if (match.start > index) segments.add(TextSegment(text.substring(index, match.start)));
    segments.add(TextSegment(candidate, uri));
    index = end;
  }
  if (index < text.length) segments.add(TextSegment(text.substring(index)));
  return segments;
}

/// Display host without a leading "www.".
String displayHost(Uri uri) =>
    uri.host.startsWith('www.') ? uri.host.substring(4) : uri.host;

/// Metadata scraped from a page for the basic link preview.
class LinkMetadata {
  final String? title;
  final String? description;
  final String? imageUrl;
  const LinkMetadata({this.title, this.description, this.imageUrl});
  bool get isEmpty => title == null && description == null && imageUrl == null;
}

String? _meta(String html, String property) {
  final patterns = [
    RegExp('<meta[^>]+(?:property|name)=["\']$property["\'][^>]*content=["\']([^"\']*)["\']',
        caseSensitive: false),
    RegExp('<meta[^>]+content=["\']([^"\']*)["\'][^>]*(?:property|name)=["\']$property["\']',
        caseSensitive: false),
  ];
  for (final p in patterns) {
    final m = p.firstMatch(html);
    final value = m?.group(1)?.trim();
    if (value != null && value.isNotEmpty) return _unescape(value);
  }
  return null;
}

String _unescape(String s) => s
    .replaceAll('&amp;', '&')
    .replaceAll('&quot;', '"')
    .replaceAll('&#39;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>');

/// Extracts OpenGraph/<title> metadata from raw HTML. Relative image URLs
/// are resolved against [pageUrl].
LinkMetadata parseLinkMetadata(String html, Uri pageUrl) {
  var title = _meta(html, 'og:title');
  if (title == null) {
    final m = RegExp(r'<title[^>]*>([^<]*)</title>', caseSensitive: false).firstMatch(html);
    final t = m?.group(1)?.trim();
    if (t != null && t.isNotEmpty) title = _unescape(t);
  }
  final description = _meta(html, 'og:description') ?? _meta(html, 'description');
  String? image = _meta(html, 'og:image');
  if (image != null) {
    final resolved = pageUrl.resolve(image);
    image = (resolved.scheme == 'http' || resolved.scheme == 'https') ? resolved.toString() : null;
  }
  return LinkMetadata(title: title, description: description, imageUrl: image);
}
