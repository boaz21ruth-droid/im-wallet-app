import 'package:flutter_test/flutter_test.dart';
import 'package:openim/services/wallet/news_service.dart';

const _sampleRss = '''<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <item>
      <title>Bitcoin hits new ATH</title>
      <link>https://example.com/article</link>
      <pubDate>Wed, 03 Jun 2026 10:00:03 +0000</pubDate>
    </item>
    <item>
      <title>DeFi TVL surges</title>
      <link>https://example.com/defi</link>
      <pubDate>Wed, 03 Jun 2026 08:00:00 +0000</pubDate>
    </item>
  </channel>
</rss>''';

const _badDateRss = '''<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <item>
      <title>Bad date item</title>
      <link>https://example.com/bad</link>
      <pubDate>not-a-date</pubDate>
    </item>
  </channel>
</rss>''';

void main() {
  group('NewsService.parseRss', () {
    test('parses title, url, source, and publishedAt correctly', () {
      final posts = NewsService.parseRss(_sampleRss, 'CoinTelegraph');
      expect(posts.length, 2);
      expect(posts[0].title, 'Bitcoin hits new ATH');
      expect(posts[0].url, 'https://example.com/article');
      expect(posts[0].source, 'CoinTelegraph');
      expect(posts[0].publishedAt, DateTime.utc(2026, 6, 3, 10, 0, 3));
    });

    test('defaults publishedAt to epoch on bad date', () {
      final posts = NewsService.parseRss(_badDateRss, 'CoinDesk');
      expect(posts.length, 1);
      expect(posts[0].publishedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('returns empty list on malformed XML', () {
      final posts = NewsService.parseRss('not xml at all', 'CoinTelegraph');
      expect(posts, isEmpty);
    });
  });

  group('NewsService.translateTitle', () {
    test('returns null for empty string without throwing', () async {
      final result = await NewsService.translateTitle('');
      expect(result, anyOf(isNull, isEmpty));
    });
  });
}
