// test/pages/wallet/swap/swap_logic_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:openim/services/wallet/swap/swap_models.dart';

/// Mirrors _MainButton._resolveText. Kept here so we can drive it from a unit
/// test without spinning up the full GetX graph.
String resolveButtonText({
  required SwapToken? sell,
  required SwapToken? buy,
  required BigInt sellAmountRaw,
  required bool isFetchingPrice,
  required SwapException? lastError,
  required SwapPriceResult? priceResult,
}) {
  if (sell == null || buy == null) return '选择代币';
  if (sellAmountRaw == BigInt.zero) return '输入金额';
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
  return 'Swap';
}

void main() {
  const eth =
      SwapToken(chainKey: 'eth', symbol: 'ETH', decimals: 18);
  const usdt = SwapToken(
      chainKey: 'eth',
      symbol: 'USDT',
      decimals: 6,
      contractAddress: '0xdAC17F958D2ee523a2206206994597C13D831ec7');

  SwapPriceResult fakePrice() => SwapPriceResult(
      buyAmount: BigInt.from(123), fees: const SwapFees(), providerId: 'zerox');

  test('no tokens → 选择代币', () {
    expect(
        resolveButtonText(
          sell: null, buy: null, sellAmountRaw: BigInt.zero,
          isFetchingPrice: false, lastError: null, priceResult: null,
        ),
        equals('选择代币'));
  });

  test('tokens set, no amount → 输入金额', () {
    expect(
        resolveButtonText(
          sell: eth, buy: usdt, sellAmountRaw: BigInt.zero,
          isFetchingPrice: false, lastError: null, priceResult: null,
        ),
        equals('输入金额'));
  });

  test('fetching → 查询报价中…', () {
    expect(
        resolveButtonText(
          sell: eth, buy: usdt, sellAmountRaw: BigInt.from(1),
          isFetchingPrice: true, lastError: null, priceResult: null,
        ),
        equals('查询报价中…'));
  });

  test('no-liquidity error → 无可用路由', () {
    expect(
        resolveButtonText(
          sell: eth, buy: usdt, sellAmountRaw: BigInt.from(1),
          isFetchingPrice: false,
          lastError: const SwapException(SwapErrorKind.noLiquidity, ''),
          priceResult: null,
        ),
        equals('无可用路由'));
  });

  test('no-api-key error → Swap 未配置', () {
    expect(
        resolveButtonText(
          sell: eth, buy: usdt, sellAmountRaw: BigInt.from(1),
          isFetchingPrice: false,
          lastError: const SwapException(SwapErrorKind.noApiKey, ''),
          priceResult: null,
        ),
        equals('Swap 未配置'));
  });

  test('quote returned → Swap', () {
    expect(
        resolveButtonText(
          sell: eth, buy: usdt, sellAmountRaw: BigInt.from(1),
          isFetchingPrice: false, lastError: null, priceResult: fakePrice(),
        ),
        equals('Swap'));
  });
}
