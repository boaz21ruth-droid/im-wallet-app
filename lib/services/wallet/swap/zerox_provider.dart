// lib/services/wallet/swap/zerox_provider.dart
import 'package:dio/dio.dart';
import 'swap_config.dart';
import 'swap_models.dart';
import 'swap_provider.dart';

class ZeroExProvider implements SwapProvider {
  static const String baseUrl = 'https://api.0x.org';

  /// Maps wallet chain keys to 0x `chainId`.
  static const Map<String, int> _chainIds = {
    'eth': 1,
    'bsc': 56,
    'polygon': 137,
    'arbitrum': 42161,
    'optimism': 10,
  };

  final Dio _dio;
  final String _apiKey;

  ZeroExProvider({Dio? dio, String? apiKey})
      : _dio = dio ?? Dio(BaseOptions(connectTimeout: const Duration(seconds: 10), receiveTimeout: const Duration(seconds: 10))),
        _apiKey = apiKey ?? kZeroxApiKey;

  @override
  String get id => 'zerox';

  @override
  String get displayName => '0x';

  @override
  bool supportsChain(String chainKey) => _chainIds.containsKey(chainKey);

  String _toApiAddress(SwapToken t) =>
      t.isNative ? kNativeTokenSentinel : t.contractAddress!;

  Map<String, dynamic> _baseParams(SwapQuoteRequest req) {
    final params = <String, dynamic>{
      'chainId': _chainIds[req.chainKey],
      'sellToken': _toApiAddress(req.sellToken),
      'buyToken': _toApiAddress(req.buyToken),
      'sellAmount': req.sellAmount.toString(),
      'taker': req.takerAddress,
      'slippageBps': req.slippageBps,
    };
    final recipient = kFeeRecipients[req.chainKey];
    if (recipient != null && recipient.isNotEmpty) {
      params['swapFeeBps'] = kSwapFeeBps;
      params['swapFeeRecipient'] = recipient;
      params['swapFeeToken'] = _toApiAddress(req.buyToken);
    }
    return params;
  }

  Map<String, String> get _headers => {
        '0x-api-key': _apiKey,
        '0x-version': 'v2',
      };

  void _validateBeforeCall(SwapQuoteRequest req) {
    if (_apiKey.isEmpty) {
      throw const SwapException(SwapErrorKind.noApiKey, '0x API key not set');
    }
    if (!supportsChain(req.chainKey)) {
      throw SwapException(
          SwapErrorKind.chainNotSupported, 'Chain ${req.chainKey} not supported by 0x');
    }
  }

  @override
  Future<SwapPriceResult> getPrice(SwapQuoteRequest req) async {
    _validateBeforeCall(req);
    try {
      final resp = await _dio.get(
        '$baseUrl/swap/allowance-holder/price',
        queryParameters: _baseParams(req),
        options: Options(headers: _headers),
      );
      final data = resp.data as Map<String, dynamic>;
      return SwapPriceResult(
        buyAmount: BigInt.parse(data['buyAmount'] as String),
        gasEstimate: data['gas'] != null
            ? BigInt.tryParse(data['gas'].toString())
            : null,
        fees: _parseFees(data['fees']),
        providerId: id,
      );
    } on DioException catch (e) {
      throw _toSwapException(e);
    } on SwapException {
      rethrow;
    } catch (e) {
      throw SwapException(SwapErrorKind.unknown, 'parse failed: $e');
    }
  }

  @override
  Future<SwapQuote> getQuote(SwapQuoteRequest req) async {
    _validateBeforeCall(req);
    try {
      final resp = await _dio.get(
        '$baseUrl/swap/allowance-holder/quote',
        queryParameters: _baseParams(req),
        options: Options(headers: _headers),
      );
      final data = resp.data as Map<String, dynamic>;
      final tx = data['transaction'] as Map<String, dynamic>? ?? data;
      final buyAmount = BigInt.parse(data['buyAmount'] as String);
      final slippageBps = req.slippageBps;
      final minBuy =
          buyAmount * BigInt.from(10000 - slippageBps) ~/ BigInt.from(10000);
      ApprovalIssue? approval;
      final issues = data['issues'] as Map<String, dynamic>?;
      final allowanceIssue = issues?['allowance'];
      if (allowanceIssue is Map<String, dynamic>) {
        approval = ApprovalIssue(
          tokenAddress: req.sellToken.contractAddress!,
          spender: allowanceIssue['spender'] as String,
          requiredAmount: req.sellAmount,
        );
      }
      final to = tx['to'] as String;
      if (!kZeroxAllowedRouters.any((a) => a.toLowerCase() == to.toLowerCase())) {
        throw SwapException(
          SwapErrorKind.invalidParams,
          'quote.to is not a known 0x router: $to',
        );
      }
      return SwapQuote(
        buyAmount: buyAmount,
        minBuyAmount: minBuy,
        to: to,
        data: tx['data'] as String,
        value: BigInt.parse((tx['value'] ?? '0').toString()),
        gas: tx['gas'] != null ? BigInt.tryParse(tx['gas'].toString()) : null,
        gasPrice: tx['gasPrice'] != null
            ? BigInt.tryParse(tx['gasPrice'].toString())
            : null,
        approval: approval,
        fees: _parseFees(data['fees']),
        providerId: id,
      );
    } on DioException catch (e) {
      throw _toSwapException(e);
    } on SwapException {
      rethrow;
    } catch (e) {
      throw SwapException(SwapErrorKind.unknown, 'parse failed: $e');
    }
  }

  SwapFees _parseFees(dynamic raw) {
    if (raw is! Map<String, dynamic>) return const SwapFees();
    BigInt? amount(dynamic field) {
      if (field is Map<String, dynamic>) {
        final v = field['amount'];
        return v == null ? null : BigInt.tryParse(v.toString());
      }
      return null;
    }
    String? token(dynamic field) {
      if (field is Map<String, dynamic>) {
        return field['token'] as String?;
      }
      return null;
    }
    return SwapFees(
      integratorFeeAmount: amount(raw['integratorFee']),
      integratorFeeToken: token(raw['integratorFee']),
      zeroExFeeAmount: amount(raw['zeroExFee']),
      gasFeeAmount: amount(raw['gasFee']),
    );
  }

  SwapException _toSwapException(DioException e) {
    final status = e.response?.statusCode;
    if (status == null) return SwapException(SwapErrorKind.network, e.message ?? 'network');
    if (status == 429) return const SwapException(SwapErrorKind.rateLimited, 'rate limited');
    if (status == 422) return const SwapException(SwapErrorKind.noLiquidity, 'no liquidity');
    if (status >= 400 && status < 500) {
      return SwapException(
          SwapErrorKind.invalidParams, '0x $status: ${e.response?.data}');
    }
    return SwapException(SwapErrorKind.unknown, '0x $status: ${e.response?.data}');
  }
}
