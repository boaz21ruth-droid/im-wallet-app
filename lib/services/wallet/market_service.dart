import 'dart:convert';
import 'package:http/http.dart' as http;
import 'wallet_models.dart';

class MarketService {
  static const _baseUrl = 'https://api.coingecko.com/api/v3';

  // ids: comma-separated CoinGecko IDs e.g. 'ethereum,bitcoin,tether'
  static Future<Map<String, CoinPrice>> getPrices(
    List<String> ids, {
    String currency = 'usd',
  }) async {
    if (ids.isEmpty) return {};
    final joined = ids.join(',');
    final url = Uri.parse(
      '$_baseUrl/simple/price?ids=$joined'
      '&vs_currencies=$currency'
      '&include_24hr_change=true'
      '&include_market_cap=true'
      '&include_24hr_vol=true',
    );
    try {
      final resp = await http.get(url, headers: {'Accept': 'application/json'});
      if (resp.statusCode != 200) return {};
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final result = <String, CoinPrice>{};
      for (final entry in json.entries) {
        final data = entry.value as Map<String, dynamic>;
        result[entry.key] = CoinPrice(
          id: entry.key,
          symbol: entry.key,
          price: (data[currency] as num?)?.toDouble() ?? 0,
          change24h: (data['${currency}_24h_change'] as num?)?.toDouble() ?? 0,
          marketCap: (data['${currency}_market_cap'] as num?)?.toDouble() ?? 0,
          volume24h: (data['${currency}_24h_vol'] as num?)?.toDouble() ?? 0,
        );
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  static Future<List<CoinMarketData>> getMarketList({
    String currency = 'usd',
    int page = 1,
    int perPage = 50,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/coins/markets'
      '?vs_currency=$currency'
      '&order=market_cap_desc'
      '&per_page=$perPage'
      '&page=$page'
      '&sparkline=false'
      '&price_change_percentage=24h',
    );
    try {
      final resp = await http.get(url, headers: {'Accept': 'application/json'});
      if (resp.statusCode != 200) return [];
      final list = jsonDecode(resp.body) as List;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return CoinMarketData(
          id: m['id'] as String,
          symbol: (m['symbol'] as String).toUpperCase(),
          name: m['name'] as String,
          image: m['image'] as String? ?? '',
          price: (m['current_price'] as num?)?.toDouble() ?? 0,
          change24h: (m['price_change_percentage_24h'] as num?)?.toDouble() ?? 0,
          marketCap: (m['market_cap'] as num?)?.toDouble() ?? 0,
          volume24h: (m['total_volume'] as num?)?.toDouble() ?? 0,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}

class CoinMarketData {
  final String id;
  final String symbol;
  final String name;
  final String image;
  final double price;
  final double change24h;
  final double marketCap;
  final double volume24h;

  const CoinMarketData({
    required this.id,
    required this.symbol,
    required this.name,
    required this.image,
    required this.price,
    required this.change24h,
    required this.marketCap,
    required this.volume24h,
  });
}
