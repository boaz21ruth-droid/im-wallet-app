// test/services/wallet/swap/zerox_provider_test.dart
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openim/services/wallet/swap/remote_swap_config.dart';
import 'package:openim/services/wallet/swap/swap_models.dart';
import 'package:openim/services/wallet/swap/zerox_provider.dart';

RemoteSwapConfig _testConfig({String apiKey = 'test'}) {
  return RemoteSwapConfig(
    zerox: ZeroExRemoteConfig(
      apiKey: apiKey,
      apiBase: 'https://api.0x.org',
      version: 'v2',
    ),
    chains: const {
      'eth': RemoteChainConfig(
        rpcs: [],
        feeRecipient: '',
        allowedRouters: ['0x0000000000001fF3684f28c67538d4D072C22734'],
      ),
    },
    limits: const RemoteLimits(
      largeAmountUsdThreshold: 10000,
      priceDriftBps: 100,
      approveReceiptTimeoutSeconds: 60,
    ),
  );
}

/// Minimal in-memory interceptor: returns canned responses for a list of
/// (matcher → response) pairs. No external dep beyond dio.
class _FakeAdapter implements HttpClientAdapter {
  final List<({bool Function(RequestOptions) match, ResponseBody body})> rules;
  _FakeAdapter(this.rules);

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    for (final r in rules) {
      if (r.match(options)) return r.body;
    }
    return ResponseBody.fromString('{"reason":"unmatched"}', 404);
  }
}

ResponseBody _json(String body, int status) {
  return ResponseBody.fromString(body, status, headers: {
    'content-type': ['application/json'],
  });
}

Dio _makeDio(_FakeAdapter adapter) {
  final dio = Dio();
  dio.httpClientAdapter = adapter;
  return dio;
}

void main() {
  const ethToken =
      SwapToken(chainKey: 'eth', symbol: 'ETH', decimals: 18);
  const usdtToken = SwapToken(
    chainKey: 'eth',
    symbol: 'USDT',
    decimals: 6,
    contractAddress: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
  );

  SwapQuoteRequest req() => SwapQuoteRequest(
        chainKey: 'eth',
        sellToken: ethToken,
        buyToken: usdtToken,
        sellAmount: BigInt.parse('1000000000000000000'),
        takerAddress: '0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
        slippageBps: 50,
      );

  test('getPrice parses buyAmount and integrator fee', () async {
    final adapter = _FakeAdapter([
      (
        match: (o) => o.path.contains('/swap/allowance-holder/price'),
        body: _json(
          '{"buyAmount":"3245100000","sellAmount":"1000000000000000000",'
          '"gas":"150000","fees":{"integratorFee":{"amount":"9690000",'
          '"token":"0xdAC17F958D2ee523a2206206994597C13D831ec7","type":"volume"}}}',
          200,
        ),
      ),
    ]);
    final p = ZeroExProvider(dio: _makeDio(adapter), config: _testConfig());
    final r = await p.getPrice(req());
    expect(r.buyAmount, equals(BigInt.parse('3245100000')));
    expect(r.gasEstimate, equals(BigInt.from(150000)));
    expect(r.fees.integratorFeeAmount, equals(BigInt.from(9690000)));
    expect(r.providerId, equals('zerox'));
  });

  test('getPrice throws noApiKey when key empty', () async {
    final p = ZeroExProvider(dio: Dio(), config: _testConfig(apiKey: ''));
    expect(
      () => p.getPrice(req()),
      throwsA(isA<SwapException>().having((e) => e.kind, 'kind',
          SwapErrorKind.noApiKey)),
    );
  });

  test('getPrice maps 422 to noLiquidity', () async {
    final adapter = _FakeAdapter([
      (
        match: (o) => o.path.contains('/price'),
        body: _json('{"reason":"INSUFFICIENT_ASSET_LIQUIDITY"}', 422),
      ),
    ]);
    final p = ZeroExProvider(dio: _makeDio(adapter), config: _testConfig());
    expect(
      () => p.getPrice(req()),
      throwsA(isA<SwapException>().having((e) => e.kind, 'kind',
          SwapErrorKind.noLiquidity)),
    );
  });

  test('getPrice maps 429 to rateLimited', () async {
    final adapter = _FakeAdapter([
      (
        match: (o) => true,
        body: _json('{"reason":"throttled"}', 429),
      ),
    ]);
    final p = ZeroExProvider(dio: _makeDio(adapter), config: _testConfig());
    expect(
      () => p.getPrice(req()),
      throwsA(isA<SwapException>().having((e) => e.kind, 'kind',
          SwapErrorKind.rateLimited)),
    );
  });

  test('supportsChain matches EVM mainnets only', () {
    final p = ZeroExProvider(dio: Dio(), config: _testConfig());
    expect(p.supportsChain('eth'), isTrue);
    expect(p.supportsChain('polygon'), isTrue);
    expect(p.supportsChain('tron'), isFalse);
    expect(p.supportsChain('eth_sepolia'), isFalse);
  });
}
