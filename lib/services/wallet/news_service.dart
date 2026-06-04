import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class NewsPost {
  final String title;
  final String source;
  final String url;
  final DateTime publishedAt;

  const NewsPost({
    required this.title,
    required this.source,
    required this.url,
    required this.publishedAt,
  });
}

class NewsService {
  static const _cointelegraphRss = 'https://cointelegraph.com/rss';
  static const _decryptRss       = 'https://decrypt.co/feed';
  static const _decryptZhRss     = 'https://decrypt.co/zh-hans/feed';

  // hot=false → 最新 (CoinTelegraph, always English)
  // hot=true  → 热门 (Decrypt, language depends on Get.locale)
  static Future<List<NewsPost>> fetch({bool hot = false}) async {
    final String feedUrl;
    final String sourceName;
    if (hot) {
      final isChinese = Get.locale?.languageCode == 'zh';
      feedUrl    = isChinese ? _decryptZhRss : _decryptRss;
      sourceName = isChinese ? 'Decrypt 中文' : 'Decrypt';
    } else {
      feedUrl    = _cointelegraphRss;
      sourceName = 'CoinTelegraph';
    }
    try {
      final resp = await http.get(Uri.parse(feedUrl));
      if (resp.statusCode != 200) return [];
      return parseRss(resp.body, sourceName);
    } catch (_) {
      return [];
    }
  }

  // Translates [text] from English to Simplified Chinese via Google Translate
  // free endpoint. Returns null on any failure (network error, bad response).
  static Future<String?> translateTitle(String text) async {
    if (text.isEmpty) return null;
    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single',
      ).replace(queryParameters: {
        'client': 'gtx',
        'sl': 'en',
        'tl': 'zh-CN',
        'dt': 't',
        'q': text,
      });
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as List;
      return (data[0] as List)
          .map((e) => (e is List && e.isNotEmpty) ? e[0]?.toString() ?? '' : '')
          .join();
    } catch (_) {
      return null;
    }
  }

  // Exposed for testing.
  static List<NewsPost> parseRss(String xmlBody, String source) {
    try {
      final doc = XmlDocument.parse(xmlBody);
      return doc.findAllElements('item').map((item) {
        final title   = item.findElements('title').firstOrNull?.innerText.trim() ?? '';
        final link    = item.findElements('link').firstOrNull?.innerText.trim() ?? '';
        final pubDate = item.findElements('pubDate').firstOrNull?.innerText.trim() ?? '';
        return NewsPost(
          title: title,
          source: source,
          url: link,
          publishedAt: _parseRfc2822(pubDate),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // Parses RFC 2822 date: "Wed, 03 Jun 2026 23:00:03 +0000"
  static DateTime _parseRfc2822(String date) {
    try {
      final parts = date.trim().split(RegExp(r'\s+'));
      if (parts.length < 5) return DateTime.fromMillisecondsSinceEpoch(0);
      const months = {
        'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
        'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
        'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12',
      };
      final day   = parts[1].padLeft(2, '0');
      final month = months[parts[2]] ?? '01';
      final year  = parts[3];
      final time  = parts[4];
      return DateTime.tryParse('$year-$month-${day}T${time}Z') ??
          DateTime.fromMillisecondsSinceEpoch(0);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}
