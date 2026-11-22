import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/message_envelope.dart';

/// Builds link previews on the sender's phone (like Signal). Only the sender contacts the
/// site, and only for a link they chose to share; the result travels encrypted.
abstract final class LinkPreviewService {
  static final _url = RegExp(r'https?://[^\s<>"]+', caseSensitive: false);

  static String? firstUrl(String text) => _url.firstMatch(text)?.group(0);

  /// Null when the page can't be fetched or has no title. Never throws.
  static Future<LinkPreview?> fetch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) return null;
    try {
      final res = await http
          .get(uri, headers: {'User-Agent': 'Mozilla/5.0 (compatible; HakiPreview)', 'Accept': 'text/html'})
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200 || !(res.headers['content-type'] ?? '').contains('html')) return null;
      // Metadata lives in <head>; don't scan megabytes of body
      final bytes = res.bodyBytes;
      final html = utf8.decode(bytes.length > 300000 ? bytes.sublist(0, 300000) : bytes, allowMalformed: true);
      return parse(url, html);
    } catch (_) {
      return null;
    }
  }

  /// Open Graph first, then <title> / meta description.
  // ponytail: regex over <head>, not a real HTML parser; fine for OG tags, upgrade if odd sites break
  static LinkPreview? parse(String url, String html) {
    String? meta(String key) {
      final a = RegExp('<meta[^>]+(?:property|name)=["\']$key["\'][^>]*content=["\']([^"\']*)["\']', caseSensitive: false);
      final b = RegExp('<meta[^>]+content=["\']([^"\']*)["\'][^>]*(?:property|name)=["\']$key["\']', caseSensitive: false);
      final v = (a.firstMatch(html) ?? b.firstMatch(html))?.group(1);
      return v == null || v.trim().isEmpty ? null : _unescape(v.trim());
    }

    final titleTag = RegExp(r'<title[^>]*>([^<]*)</title>', caseSensitive: false).firstMatch(html)?.group(1);
    final title = meta('og:title') ?? (titleTag == null ? null : _unescape(titleTag.trim()));
    if (title == null || title.isEmpty) return null;
    final description = meta('og:description') ?? meta('description');
    return LinkPreview(
      url: url,
      title: _clip(title, 120),
      description: description == null ? null : _clip(description, 200),
      site: meta('og:site_name') ?? Uri.parse(url).host,
    );
  }

  static String _clip(String s, int max) => s.length <= max ? s : '${s.substring(0, max - 1)}…';

  static String _unescape(String s) => s
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&#x27;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ');
}
