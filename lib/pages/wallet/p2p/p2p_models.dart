class P2POrder {
  final int orderId;
  final String seller;
  final String buyer;
  final String token;
  final String amount;       // raw token units as string
  final int fiatAmount;      // ×100 (cents)
  final String fiatCurrency;
  final String payMethod;
  final int status;
  final String statusLabel;
  final String txHash;

  const P2POrder({
    required this.orderId,
    required this.seller,
    required this.buyer,
    required this.token,
    required this.amount,
    required this.fiatAmount,
    required this.fiatCurrency,
    required this.payMethod,
    required this.status,
    required this.statusLabel,
    required this.txHash,
  });

  factory P2POrder.fromJson(Map<String, dynamic> j) => P2POrder(
        orderId: (j['order_id'] as num).toInt(),
        seller: j['seller'] as String? ?? '',
        buyer: j['buyer'] as String? ?? '',
        token: j['token'] as String? ?? '',
        amount: j['amount'] as String? ?? '0',
        fiatAmount: (j['fiat_amount'] as num?)?.toInt() ?? 0,
        fiatCurrency: j['fiat_currency'] as String? ?? 'CNY',
        payMethod: j['pay_method'] as String? ?? '',
        status: (j['status'] as num?)?.toInt() ?? 0,
        statusLabel: j['status_label'] as String? ?? '',
        txHash: j['tx_hash'] as String? ?? '',
      );

  // status constants (mirror Solidity enum)
  static const open      = 0;
  static const locked    = 1;
  static const paid      = 2;
  static const released  = 3;
  static const cancelled = 4;
  static const disputed  = 5;

  double get fiatDisplay => fiatAmount / 100;

  // BSC Testnet USDT = 18 decimals; mainnet USDT = 6 decimals
  double get tokenDisplay =>
      (BigInt.tryParse(amount) ?? BigInt.zero).toDouble() / 1e18;

  double get unitPrice =>
      tokenDisplay > 0 ? fiatDisplay / tokenDisplay : 0;

  String get shortSeller =>
      seller.length > 12 ? '${seller.substring(0, 6)}...${seller.substring(seller.length - 4)}' : seller;
}
