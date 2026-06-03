import 'dart:convert';
import 'package:http/http.dart' as http;

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

  factory NewsPost.fromJson(Map<String, dynamic> m) {
    return NewsPost(
      title: m['title'] as String? ?? '',
      source: (m['source'] as Map<String, dynamic>?)?['title'] as String? ?? '',
      url: m['url'] as String? ?? '',
      publishedAt: DateTime.tryParse(m['published_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class NewsService {
  static const _base = 'https://cryptopanic.com/api/v1/posts';

  // hot=false → 广场 (latest), hot=true → 公告 (hot filter)
  static Future<List<NewsPost>> fetch({bool hot = false}) async {
    final uri = Uri.parse('$_base/?public=true${hot ? '&filter=hot' : ''}');
    try {
      final resp = await http.get(uri, headers: {'Accept': 'application/json'});
      if (resp.statusCode != 200) return [];
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final results = json['results'] as List? ?? [];
      return results
          .map((e) => NewsPost.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
