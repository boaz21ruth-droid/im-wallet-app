// lib/services/wallet/swap/intent_service.dart
//
// Intent (CoW) swap client. The backend proxies CoW's orderbook; this fetches a
// ready-to-sign order, submits the client-signed order, and polls status.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openim_common/openim_common.dart';

import 'swap_models.dart';

class IntentService {
  final http.Client _client;

  IntentService({http.Client? client}) : _client = client ?? http.Client();

  Future<dynamic> _send(String method, String path,
      {Map<String, String>? query, Object? body}) async {
    final token = DataSp.chatToken ?? '';
    final uri =
        Uri.parse('${Config.appAuthUrl}/wallet/$path').replace(queryParameters: query);
    final http.Response resp;
    try {
      if (method == 'POST') {
        resp = await _client
            .post(uri,
                headers: {'token': token, 'Content-Type': 'application/json'},
                body: jsonEncode(body))
            .timeout(const Duration(seconds: 15));
      } else {
        resp = await _client
            .get(uri, headers: {'token': token})
            .timeout(const Duration(seconds: 15));
      }
    } catch (e) {
      throw SwapException(SwapErrorKind.network, 'network: $e');
    }
    if (resp.statusCode != 200) {
      throw SwapException(SwapErrorKind.network, 'http ${resp.statusCode}');
    }
    final b = jsonDecode(resp.body) as Map<String, dynamic>;
    final errCode = (b['errCode'] as int?) ?? -1;
    if (errCode != 0) {
      throw _mapErr(errCode, (b['errMsg'] as String?) ?? 'intent error');
    }
    return b['data'];
  }

  // Mirrors resp.CodeIntent* in im-business pkg/resp.
  SwapException _mapErr(int code, String msg) {
    switch (code) {
      case 1730:
        return SwapException(SwapErrorKind.noLiquidity, msg);
      case 1731:
        return SwapException(SwapErrorKind.invalidParams, msg);
      case 1732:
        return SwapException(SwapErrorKind.chainNotSupported, msg);
      default:
        return SwapException(SwapErrorKind.unknown, msg);
    }
  }

  Future<IntentQuote> quote({
    required String chainKey,
    required SwapToken sellToken,
    required SwapToken buyToken,
    required BigInt amount,
    required String from,
    required int slippageBps,
  }) async {
    final d = await _send('GET', 'intent/quote', query: {
      'chainKey': chainKey,
      'sellToken': sellToken.isNative ? 'native' : sellToken.contractAddress!,
      'buyToken': buyToken.isNative ? 'native' : buyToken.contractAddress!,
      'sellAmount': amount.toString(),
      'from': from,
      'slippageBps': slippageBps.toString(),
    }) as Map<String, dynamic>;
    return IntentQuote(
      order: IntentOrder.fromJson(d['order'] as Map<String, dynamic>),
      chainId: d['chainId'] as int,
      verifyingContract: d['verifyingContract'] as String,
      approvalSpender: d['approvalSpender'] as String,
      quoteId: d['quoteId'] as int,
      expectedBuyAmount: BigInt.parse(d['expectedBuyAmount'] as String),
    );
  }

  /// Submits a signed order; returns the CoW order UID.
  Future<String> submit({
    required String chainKey,
    required IntentOrder order,
    required String signatureHex,
    required String from,
    required int quoteId,
  }) async {
    final d = await _send('POST', 'intent/order', body: {
      'chainKey': chainKey,
      'order': order.toJson(),
      'signature': signatureHex,
      'from': from,
      'quoteId': quoteId,
    }) as Map<String, dynamic>;
    return d['orderUid'] as String;
  }

  Future<IntentStatus> status({
    required String chainKey,
    required String orderUid,
  }) async {
    final d = await _send('GET', 'intent/status',
        query: {'chainKey': chainKey, 'orderUid': orderUid}) as Map<String, dynamic>;
    return IntentStatus(IntentStatus.kindFrom(d['status'] as String?));
  }
}
