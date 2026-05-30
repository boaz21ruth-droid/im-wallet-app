// lib/services/wallet/swap/backend_quote_provider.dart
//
// The single SwapProvider the app uses. Quote aggregation (0x, 1inch, OKX,
// Paraswap, …) runs server-side in im-business; this client just asks the
// backend for the best price/quote and signs+broadcasts locally. The client
// holds no aggregator API key and calls no aggregator API directly.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openim_common/openim_common.dart';

import 'swap_config.dart' show kZeroxSupportedChains;
import 'swap_models.dart';
import 'swap_provider.dart';

class BackendQuoteProvider implements SwapProvider {
  final http.Client _client;

  /// The full ranked list (best first) from the most recent [getPrice] call,
  /// for the UI's aggregator comparison view. Updated on every price fetch.
  List<SwapPriceResult> lastComparison = const [];

  BackendQuoteProvider({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get id => 'best';

  @override
  String get displayName => '最佳价格';

  @override
  bool supportsChain(String chainKey) => kZeroxSupportedChains.contains(chainKey);

  Map<String, String> _params(SwapQuoteRequest req) => {
        'chainKey': req.chainKey,
        'sellToken': req.sellToken.isNative ? 'native' : req.sellToken.contractAddress!,
        'buyToken': req.buyToken.isNative ? 'native' : req.buyToken.contractAddress!,
        'sellDecimals': req.sellToken.decimals.toString(),
        'buyDecimals': req.buyToken.decimals.toString(),
        'sellAmount': req.sellAmount.toString(),
        'taker': req.takerAddress,
        'slippageBps': req.slippageBps.toString(),
      };

  /// GET `/wallet/{path}`; returns the `data` object ({best, all}) or throws.
  Future<Map<String, dynamic>> _getData(String path, SwapQuoteRequest req) async {
    final token = DataSp.chatToken ?? '';
    final uri = Uri.parse('${Config.appAuthUrl}/wallet/$path')
        .replace(queryParameters: _params(req));

    final http.Response resp;
    try {
      resp = await _client
          .get(uri, headers: {'token': token})
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      throw SwapException(SwapErrorKind.network, 'network: $e');
    }
    if (resp.statusCode != 200) {
      throw SwapException(SwapErrorKind.network, 'http ${resp.statusCode}');
    }

    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final errCode = (body['errCode'] as int?) ?? -1;
    if (errCode != 0) {
      throw _mapErr(errCode, (body['errMsg'] as String?) ?? 'swap error');
    }
    final data = body['data'] as Map<String, dynamic>?;
    if (data == null || data['best'] is! Map<String, dynamic>) {
      throw const SwapException(SwapErrorKind.noLiquidity, 'no quote');
    }
    return data;
  }

  SwapPriceResult _priceFromJson(Map<String, dynamic> j) => SwapPriceResult(
        buyAmount: BigInt.parse(j['buyAmount'] as String),
        gasEstimate: _tryBig(j['gasEstimate']),
        fees: _parseFees(j['fees']),
        providerId: (j['provider'] as String?) ?? id,
      );

  // Mirrors resp.CodeSwap* in im-business pkg/resp.
  SwapException _mapErr(int code, String msg) {
    switch (code) {
      case 1700:
        return SwapException(SwapErrorKind.noLiquidity, msg);
      case 1701:
        return SwapException(SwapErrorKind.invalidParams, msg);
      case 1702:
        return SwapException(SwapErrorKind.chainNotSupported, msg);
      default:
        return SwapException(SwapErrorKind.unknown, msg);
    }
  }

  @override
  Future<SwapPriceResult> getPrice(SwapQuoteRequest req) async {
    final data = await _getData('price', req);
    final all = (data['all'] as List?) ?? const [];
    lastComparison = all
        .whereType<Map<String, dynamic>>()
        .map(_priceFromJson)
        .toList(growable: false);
    return _priceFromJson(data['best'] as Map<String, dynamic>);
  }

  @override
  Future<SwapQuote> getQuote(SwapQuoteRequest req) async {
    final best = (await _getData('quote', req))['best'] as Map<String, dynamic>;
    ApprovalIssue? approval;
    final a = best['approval'];
    if (a is Map<String, dynamic>) {
      approval = ApprovalIssue(
        tokenAddress: a['tokenAddress'] as String,
        spender: a['spender'] as String,
        requiredAmount: BigInt.parse(a['requiredAmount'] as String),
      );
    }
    return SwapQuote(
      buyAmount: BigInt.parse(best['buyAmount'] as String),
      minBuyAmount: BigInt.parse(best['minBuyAmount'] as String),
      to: best['to'] as String,
      data: best['data'] as String,
      value: BigInt.parse((best['value'] ?? '0').toString()),
      gas: _tryBig(best['gas']),
      gasPrice: _tryBig(best['gasPrice']),
      approval: approval,
      fees: _parseFees(best['fees']),
      providerId: (best['provider'] as String?) ?? id,
    );
  }

  BigInt? _tryBig(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : BigInt.tryParse(s);
  }

  SwapFees _parseFees(dynamic raw) {
    if (raw is! Map<String, dynamic>) return const SwapFees();
    return SwapFees(
      integratorFeeAmount: _tryBig(raw['integratorFeeAmount']),
      integratorFeeToken: raw['integratorFeeToken'] as String?,
      zeroExFeeAmount: _tryBig(raw['zeroExFeeAmount']),
      gasFeeAmount: _tryBig(raw['gasFeeAmount']),
    );
  }
}
