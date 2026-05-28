// test/services/wallet/swap/swap_models_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:openim/services/wallet/swap/swap_models.dart';

void main() {
  group('SwapToken', () {
    test('two natives on same chain are equal', () {
      const a = SwapToken(chainKey: 'eth', symbol: 'ETH', decimals: 18);
      const b = SwapToken(chainKey: 'eth', symbol: 'ETH', decimals: 18);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('different contract addresses are not equal', () {
      const a = SwapToken(
        chainKey: 'eth', symbol: 'USDT', decimals: 6,
        contractAddress: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
      );
      const b = SwapToken(
        chainKey: 'eth', symbol: 'USDT', decimals: 6,
        contractAddress: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
      );
      expect(a == b, isFalse);
    });

    test('isNative reflects contractAddress', () {
      const a = SwapToken(chainKey: 'eth', symbol: 'ETH', decimals: 18);
      const b = SwapToken(
        chainKey: 'eth', symbol: 'USDT', decimals: 6,
        contractAddress: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
      );
      expect(a.isNative, isTrue);
      expect(b.isNative, isFalse);
    });
  });
}
