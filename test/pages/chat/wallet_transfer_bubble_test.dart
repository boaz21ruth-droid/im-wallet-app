import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openim/pages/chat/wallet_transfer_bubble.dart';

Widget _wrap(Widget child) => ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  group('WalletTransferBubble', () {
    testWidgets('sent: shows 已转账 + amount + symbol', (tester) async {
      await tester.pumpWidget(_wrap(WalletTransferBubble(
        amount: '0.1',
        symbol: 'ETH',
        chain: 'eth',
        hash: '0xabc123def456789',
        isSentByMe: true,
      )));
      expect(find.textContaining('已转账'), findsOneWidget);
      expect(find.textContaining('0.1 ETH'), findsOneWidget);
    });

    testWidgets('received: shows 收到 + amount + symbol', (tester) async {
      await tester.pumpWidget(_wrap(WalletTransferBubble(
        amount: '5.0',
        symbol: 'USDT',
        chain: 'bsc',
        hash: '0xdef',
        isSentByMe: false,
      )));
      expect(find.textContaining('收到'), findsOneWidget);
      expect(find.textContaining('5.0 USDT'), findsOneWidget);
    });

    testWidgets('shows truncated hash', (tester) async {
      await tester.pumpWidget(_wrap(WalletTransferBubble(
        amount: '1',
        symbol: 'TRX',
        chain: 'tron',
        hash: '0x1234567890abcdef',
        isSentByMe: false,
      )));
      expect(find.textContaining('0x1234'), findsOneWidget);
    });
  });
}
