// test/pages/wallet/swap/swap_logic_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:openim/services/wallet/swap/swap_models.dart';

/// Mirrors _MainButton._resolveText. Kept here so we can drive it from a unit
/// test without spinning up the full GetX graph. Sync with swap_view.dart.
String resolveButtonText({
  required SwapToken? sell,
  required SwapToken? buy,
  required BigInt sellAmountRaw,
  required bool isFetchingPrice,
  required SwapException? lastError,
  required SwapPriceResult? priceResult,
  required BigInt? heldRawBalance,
  required BigInt? nativeRawBalance,
  required String? nativeSymbol,
  required BigInt? estGasInWei,
  required bool needsApproval,
}) {
  if (sell == null || buy == null) return '选择代币';
  final amt = sellAmountRaw;
  if (amt == BigInt.zero) return '输入金额';
  // Pre-flight: balance + gas insufficiency.
  if (heldRawBalance == null || heldRawBalance < amt) {
    return '余额不足';
  }
  if (nativeRawBalance != null &&
      estGasInWei != null &&
      nativeSymbol != null) {
    final gasNeeded = sell.isNative ? amt + estGasInWei : estGasInWei;
    if (nativeRawBalance < gasNeeded) {
      return '$nativeSymbol 不足支付 Gas';
    }
  }
  if (isFetchingPrice) return '查询报价中…';
  if (lastError != null) {
    switch (lastError.kind) {
      case SwapErrorKind.noApiKey:
        return 'Swap 未配置';
      case SwapErrorKind.noLiquidity:
        return '无可用路由';
      case SwapErrorKind.chainNotSupported:
        return '该链暂不支持 Swap';
      case SwapErrorKind.network:
        return '网络异常';
      case SwapErrorKind.rateLimited:
        return '请求过频';
      default:
        return '报价失败';
    }
  }
  if (priceResult == null) return '输入金额';
  if (needsApproval) return '授权 ${sell.symbol}';
  return 'Swap';
}

void main() {
  const eth = SwapToken(chainKey: 'eth', symbol: 'ETH', decimals: 18);
  const usdt = SwapToken(
      chainKey: 'eth',
      symbol: 'USDT',
      decimals: 6,
      contractAddress: '0xdAC17F958D2ee523a2206206994597C13D831ec7');

  // 0.5 ETH and 1 ETH as raw wei.
  final halfEth = BigInt.parse('500000000000000000');
  final oneEth = BigInt.parse('1000000000000000000');
  // 21k gas at 1 gwei
  final smallGas = BigInt.from(21000) * BigInt.from(1000000000);

  SwapPriceResult fakePrice() => SwapPriceResult(
      buyAmount: BigInt.from(123),
      fees: const SwapFees(),
      providerId: 'zerox');

  // Defaults that won't trip any pre-flight check.
  Map<String, dynamic> baseArgs() => {
        'sell': eth,
        'buy': usdt,
        'sellAmountRaw': BigInt.zero,
        'isFetchingPrice': false,
        'lastError': null,
        'priceResult': null,
        'heldRawBalance': BigInt.parse('100000000000000000000'), // 100 ETH
        'nativeRawBalance': BigInt.parse('100000000000000000000'),
        'nativeSymbol': 'ETH',
        'estGasInWei': smallGas,
        'needsApproval': false,
      };

  String call(Map<String, dynamic> overrides) {
    final args = {...baseArgs(), ...overrides};
    return resolveButtonText(
      sell: args['sell'] as SwapToken?,
      buy: args['buy'] as SwapToken?,
      sellAmountRaw: args['sellAmountRaw'] as BigInt,
      isFetchingPrice: args['isFetchingPrice'] as bool,
      lastError: args['lastError'] as SwapException?,
      priceResult: args['priceResult'] as SwapPriceResult?,
      heldRawBalance: args['heldRawBalance'] as BigInt?,
      nativeRawBalance: args['nativeRawBalance'] as BigInt?,
      nativeSymbol: args['nativeSymbol'] as String?,
      estGasInWei: args['estGasInWei'] as BigInt?,
      needsApproval: args['needsApproval'] as bool,
    );
  }

  test('no tokens → 选择代币', () {
    expect(call({'sell': null, 'buy': null}), equals('选择代币'));
  });

  test('tokens set, no amount → 输入金额', () {
    expect(call({}), equals('输入金额'));
  });

  test('fetching → 查询报价中…', () {
    expect(
        call({'sellAmountRaw': halfEth, 'isFetchingPrice': true}),
        equals('查询报价中…'));
  });

  test('no-liquidity error → 无可用路由', () {
    expect(
      call({
        'sellAmountRaw': halfEth,
        'lastError': const SwapException(SwapErrorKind.noLiquidity, ''),
      }),
      equals('无可用路由'),
    );
  });

  test('no-api-key error → Swap 未配置', () {
    expect(
      call({
        'sellAmountRaw': halfEth,
        'lastError': const SwapException(SwapErrorKind.noApiKey, ''),
      }),
      equals('Swap 未配置'),
    );
  });

  test('quote returned → Swap', () {
    expect(
      call({'sellAmountRaw': halfEth, 'priceResult': fakePrice()}),
      equals('Swap'),
    );
  });

  // New pre-flight states (spec §7).

  test('sell amount > held balance → 余额不足', () {
    expect(
      call({
        'sellAmountRaw': oneEth,
        // User only holds 0.5 ETH
        'heldRawBalance': halfEth,
      }),
      equals('余额不足'),
    );
  });

  test('native sell where sellAmt + gas > native balance → Gas 不足', () {
    expect(
      call({
        // User holds exactly the sell amount, no room for gas
        'sellAmountRaw': halfEth,
        'heldRawBalance': halfEth,
        'nativeRawBalance': halfEth,
      }),
      equals('ETH 不足支付 Gas'),
    );
  });

  test('ERC20 sell where native balance < gas → Gas 不足', () {
    // 1 USDT (decimals=6) — held balance must cover it.
    final oneUsdt = BigInt.from(1000000);
    expect(
      call({
        'sell': usdt,
        'sellAmountRaw': oneUsdt,
        'heldRawBalance': oneUsdt,
        // 0 ETH for gas
        'nativeRawBalance': BigInt.zero,
      }),
      equals('ETH 不足支付 Gas'),
    );
  });

  test('needsApproval=true → 授权 SYMBOL', () {
    final oneUsdt = BigInt.from(1000000);
    expect(
      call({
        'sell': usdt,
        'sellAmountRaw': oneUsdt,
        'heldRawBalance': oneUsdt,
        'priceResult': fakePrice(),
        'needsApproval': true,
      }),
      equals('授权 USDT'),
    );
  });
}
