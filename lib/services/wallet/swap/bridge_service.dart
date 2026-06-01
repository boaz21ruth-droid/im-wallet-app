// lib/services/wallet/swap/bridge_service.dart
//
// Cross-chain swap client. Quote aggregation across bridges (LI.FI) runs
// server-side in im-business; this just fetches the best route + source-chain
// calldata, which the app signs+broadcasts locally, then polls for delivery.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openim_common/openim_common.dart';

import 'swap_models.dart';

class BridgeService {
  final http.Client _client;

  BridgeService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> _get(
      String path, Map<String, String> params) async {
    final token = DataSp.chatToken ?? '';
    final uri = Uri.parse('${Config.appAuthUrl}/wallet/$path')
        .replace(queryParameters: params);
    final http.Response resp;
    try {
      resp = await _client
          .get(uri, headers: {'token': token})
          .timeout(const Duration(seconds: 20));
    } catch (e) {
      throw SwapException(SwapErrorKind.network, 'network: $e');
    }
    if (resp.statusCode != 200) {
      throw SwapException(SwapErrorKind.network, 'http ${resp.statusCode}');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final errCode = (body['errCode'] as int?) ?? -1;
    if (errCode != 0) {
      throw _mapErr(errCode, (body['errMsg'] as String?) ?? 'bridge error');
    }
    return (body['data'] as Map<String, dynamic>?) ?? const {};
  }

  // Mirrors resp.CodeBridge* in im-business pkg/resp.
  SwapException _mapErr(int code, String msg) {
    switch (code) {
      case 1720:
        return SwapException(SwapErrorKind.noLiquidity, msg);
      case 1721:
        return SwapException(SwapErrorKind.invalidParams, msg);
      case 1722:
        return SwapException(SwapErrorKind.chainNotSupported, msg);
      default:
        return SwapException(SwapErrorKind.unknown, msg);
    }
  }

  Future<BridgeQuote> quote({
    required String fromChain,
    required String toChain,
    required SwapToken fromToken,
    required SwapToken toToken,
    required BigInt amount,
    required String fromAddress,
    required String toAddress,
    required int slippageBps,
  }) async {
    final d = await _get('bridge/quote', {
      'fromChain': fromChain,
      'toChain': toChain,
      'fromToken': fromToken.isNative ? 'native' : fromToken.contractAddress!,
      'toToken': toToken.isNative ? 'native' : toToken.contractAddress!,
      'fromAmount': amount.toString(),
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'slippageBps': slippageBps.toString(),
    });
    ApprovalIssue? approval;
    final a = d['approval'];
    if (a is Map<String, dynamic>) {
      approval = ApprovalIssue(
        tokenAddress: a['tokenAddress'] as String,
        spender: a['spender'] as String,
        requiredAmount: BigInt.parse(a['requiredAmount'] as String),
      );
    }
    return BridgeQuote(
      tool: (d['tool'] as String?) ?? 'lifi',
      fromChain: fromChain,
      toChain: toChain,
      toAmount: BigInt.parse(d['toAmount'] as String),
      toAmountMin: BigInt.parse((d['toAmountMin'] ?? d['toAmount']) as String),
      to: d['to'] as String,
      data: d['data'] as String,
      value: BigInt.parse((d['value'] ?? '0').toString()),
      gas: _tryBig(d['gas']),
      gasPrice: _tryBig(d['gasPrice']),
      approval: approval,
      executionDurationSec: (d['executionDurationSec'] as int?) ?? 0,
    );
  }

  Future<BridgeStatus> status({
    required String txHash,
    required String fromChain,
    required String toChain,
    String? tool,
  }) async {
    final d = await _get('bridge/status', {
      'txHash': txHash,
      'fromChain': fromChain,
      'toChain': toChain,
      if (tool != null && tool.isNotEmpty) 'tool': tool,
    });
    return BridgeStatus(
      kind: BridgeStatus.kindFrom(d['status'] as String?),
      destTxHash: d['destTxHash'] as String?,
      explorer: d['explorer'] as String?,
    );
  }

  BigInt? _tryBig(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : BigInt.tryParse(s);
  }
}
