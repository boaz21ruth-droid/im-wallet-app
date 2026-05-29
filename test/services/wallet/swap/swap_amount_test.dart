import 'package:flutter_test/flutter_test.dart';
import 'package:openim/pages/wallet/swap/swap_logic.dart';

void main() {
  group('SwapLogic.parseDecimalAmount', () {
    test('preserves 18-decimal precision for 0.1', () {
      // 0.1 * 10^18 = 100_000_000_000_000_000 exactly.
      expect(
        SwapLogic.parseDecimalAmount('0.1', 18),
        equals(BigInt.parse('100000000000000000')),
      );
    });
    test('truncates extra fractional digits beyond decimals', () {
      expect(
        SwapLogic.parseDecimalAmount('1.123456789', 6),
        equals(BigInt.parse('1123456')),
      );
    });
    test('returns zero for invalid input', () {
      expect(SwapLogic.parseDecimalAmount('', 18), equals(BigInt.zero));
      expect(SwapLogic.parseDecimalAmount('abc', 18), equals(BigInt.zero));
      expect(SwapLogic.parseDecimalAmount('.', 18), equals(BigInt.zero));
    });
  });
}
