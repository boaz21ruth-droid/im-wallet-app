import 'package:flutter_test/flutter_test.dart';
import 'package:openim/services/wallet/news_service.dart';

void main() {
  group('NewsPost.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'title': 'Bitcoin hits new ATH',
        'url': 'https://example.com/article',
        'published_at': '2026-06-03T10:00:00Z',
        'source': {'title': 'CoinDesk'},
      };
      final post = NewsPost.fromJson(json);
      expect(post.title, 'Bitcoin hits new ATH');
      expect(post.url, 'https://example.com/article');
      expect(post.source, 'CoinDesk');
      expect(post.publishedAt, DateTime.utc(2026, 6, 3, 10, 0, 0));
    });

    test('handles missing source gracefully', () {
      final json = {
        'title': 'DeFi news',
        'url': 'https://example.com/defi',
        'published_at': '2026-06-01T08:00:00Z',
        'source': <String, dynamic>{},
      };
      final post = NewsPost.fromJson(json);
      expect(post.source, '');
    });

    test('defaults publishedAt to epoch on bad timestamp', () {
      final json = {
        'title': '',
        'url': '',
        'published_at': 'not-a-date',
        'source': <String, dynamic>{},
      };
      final post = NewsPost.fromJson(json);
      expect(post.publishedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });
}
