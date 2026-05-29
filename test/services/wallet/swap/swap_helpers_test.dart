import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

/// Reproduces the hex parser inside EvmService.sendRaw — keep in sync.
Uint8List parseHex(String dataHex) {
  final hex = dataHex.startsWith('0x') ? dataHex.substring(2) : dataHex;
  return Uint8List.fromList(
    [for (var i = 0; i < hex.length; i += 2) int.parse(hex.substring(i, i + 2), radix: 16)],
  );
}

void main() {
  group('parseHex', () {
    test('strips 0x prefix', () {
      expect(parseHex('0x1234'), equals([0x12, 0x34]));
    });
    test('accepts no prefix', () {
      expect(parseHex('1234'), equals([0x12, 0x34]));
    });
    test('handles 32-byte word', () {
      final input = '0x${'ff' * 32}';
      expect(parseHex(input).length, equals(32));
      expect(parseHex(input).every((b) => b == 0xff), isTrue);
    });
    test('throws on odd-length hex', () {
      expect(() => parseHex('0x123'), throwsA(isA<RangeError>()));
    });
    test('throws on non-hex chars', () {
      expect(() => parseHex('0x12zz'), throwsA(isA<FormatException>()));
    });
  });
}
