import 'package:uuid/uuid.dart';

enum WalletState { loading, noWallet, locked, unlocked }

class WalletAccount {
  final String id;
  final String name;
  final int index;
  final Map<String, String> addresses;

  WalletAccount({
    required this.id,
    required this.name,
    required this.index,
    required this.addresses,
  });

  factory WalletAccount.create({required String name, required int index}) =>
      WalletAccount(
        id: const Uuid().v4(),
        name: name,
        index: index,
        addresses: {},
      );

  WalletAccount copyWith({
    String? name,
    Map<String, String>? addresses,
  }) =>
      WalletAccount(
        id: id,
        name: name ?? this.name,
        index: index,
        addresses: addresses ?? Map.from(this.addresses),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'index': index,
        'addresses': addresses,
      };

  factory WalletAccount.fromJson(Map<String, dynamic> json) => WalletAccount(
        id: json['id'] as String,
        name: json['name'] as String,
        index: json['index'] as int,
        addresses: Map<String, String>.from(json['addresses'] as Map),
      );
}

class CustomToken {
  final String chainKey;
  final String contractAddress;
  final String symbol;
  final int decimals;

  const CustomToken({
    required this.chainKey,
    required this.contractAddress,
    required this.symbol,
    required this.decimals,
  });

  Map<String, dynamic> toJson() => {
        'chainKey': chainKey,
        'contractAddress': contractAddress,
        'symbol': symbol,
        'decimals': decimals,
      };

  factory CustomToken.fromJson(Map<String, dynamic> json) => CustomToken(
        chainKey: json['chainKey'] as String,
        contractAddress: json['contractAddress'] as String,
        symbol: json['symbol'] as String,
        decimals: json['decimals'] as int,
      );
}

class WalletSettings {
  final String currency;
  final int autoLockSeconds;
  final bool biometricEnabled;
  final List<String> enabledChainKeys;
  final List<CustomToken> customTokens;
  final bool testnetMode;

  const WalletSettings({
    required this.currency,
    required this.autoLockSeconds,
    required this.biometricEnabled,
    required this.enabledChainKeys,
    required this.customTokens,
    this.testnetMode = false,
  });

  static WalletSettings get defaults => const WalletSettings(
        currency: 'USD',
        autoLockSeconds: 300,
        biometricEnabled: false,
        enabledChainKeys: ['eth', 'bsc', 'polygon'],
        customTokens: [],
        testnetMode: false,
      );

  WalletSettings copyWith({
    String? currency,
    int? autoLockSeconds,
    bool? biometricEnabled,
    List<String>? enabledChainKeys,
    List<CustomToken>? customTokens,
    bool? testnetMode,
  }) =>
      WalletSettings(
        currency: currency ?? this.currency,
        autoLockSeconds: autoLockSeconds ?? this.autoLockSeconds,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        enabledChainKeys: enabledChainKeys ?? List.from(this.enabledChainKeys),
        customTokens: customTokens ?? List.from(this.customTokens),
        testnetMode: testnetMode ?? this.testnetMode,
      );

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'autoLockSeconds': autoLockSeconds,
        'biometricEnabled': biometricEnabled,
        'enabledChainKeys': enabledChainKeys,
        'customTokens': customTokens.map((t) => t.toJson()).toList(),
        'testnetMode': testnetMode,
      };

  factory WalletSettings.fromJson(Map<String, dynamic> json) => WalletSettings(
        currency: json['currency'] as String? ?? 'USD',
        autoLockSeconds: json['autoLockSeconds'] as int? ?? 300,
        biometricEnabled: json['biometricEnabled'] as bool? ?? false,
        enabledChainKeys: List<String>.from(json['enabledChainKeys'] as List? ?? ['eth']),
        customTokens: (json['customTokens'] as List? ?? [])
            .map((e) => CustomToken.fromJson(e as Map<String, dynamic>))
            .toList(),
        testnetMode: json['testnetMode'] as bool? ?? false,
      );
}

class TxRecord {
  final String hash;
  final String from;
  final String to;
  final BigInt value;
  final int decimals;
  final DateTime timestamp;
  final String status;
  final String chainKey;
  final String? tokenSymbol;
  final String? tokenContract;

  const TxRecord({
    required this.hash,
    required this.from,
    required this.to,
    required this.value,
    required this.decimals,
    required this.timestamp,
    required this.status,
    required this.chainKey,
    this.tokenSymbol,
    this.tokenContract,
  });

  bool get isNative => tokenSymbol == null;

  String get shortHash =>
      hash.length > 12 ? '${hash.substring(0, 6)}...${hash.substring(hash.length - 4)}' : hash;
}

class CoinPrice {
  final String symbol;
  final String id;
  final double price;
  final double change24h;
  final double marketCap;
  final double volume24h;

  const CoinPrice({
    required this.symbol,
    required this.id,
    required this.price,
    required this.change24h,
    this.marketCap = 0,
    this.volume24h = 0,
  });
}

class AssetBalance {
  final String chainKey;
  final String symbol;
  final BigInt rawBalance;
  final int decimals;
  final String? contractAddress;
  final double? priceUsd;

  const AssetBalance({
    required this.chainKey,
    required this.symbol,
    required this.rawBalance,
    required this.decimals,
    this.contractAddress,
    this.priceUsd,
  });

  bool get isNative => contractAddress == null;

  double get balance =>
      rawBalance == BigInt.zero ? 0 : rawBalance.toDouble() / BigInt.from(10).pow(decimals).toDouble();

  double get valueUsd => balance * (priceUsd ?? 0);
}
