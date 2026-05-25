import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../services/wallet/chain_config.dart';
import '../../services/wallet/evm_service.dart';
import '../../services/wallet/market_service.dart';
import '../../services/wallet/mnemonic_vault.dart';
import '../../services/wallet/tron_service.dart';
import '../../services/wallet/wallet_key.dart';
import '../../services/wallet/wallet_models.dart';
import '../../services/wallet/wallet_store.dart';

class WalletLogic extends GetxController with WidgetsBindingObserver {
  final walletState = WalletState.loading.obs;
  final accounts = <WalletAccount>[].obs;
  final selectedAccount = Rxn<WalletAccount>();
  final selectedChainKey = 'eth'.obs;
  final settings = Rx<WalletSettings>(WalletSettings.defaults);

  final balances = <String, AssetBalance>{}.obs; // key: "$chainKey:$symbol"
  final coinPrices = <String, CoinPrice>{}.obs;   // key: symbol (e.g. "ETH")
  final txHistory = <TxRecord>[].obs;
  final marketList = <CoinMarketData>[].obs;

  final isLoadingBalances = false.obs;
  final isLoadingPrices = false.obs;
  final isLoadingMarket = false.obs;

  final newsFilter = 0.obs; // 0=广场, 1=公告

  final vault = MnemonicVault();
  Timer? _autoLockTimer;
  DateTime? _backgroundedAt;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoLockTimer?.cancel();
    vault.lock();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final bg = _backgroundedAt;
      if (bg != null) {
        final elapsed = DateTime.now().difference(bg).inSeconds;
        if (elapsed >= settings.value.autoLockSeconds) lockWallet();
      }
      _backgroundedAt = null;
    }
  }

  Future<void> _init() async {
    walletState.value = WalletState.loading;
    try {
      final has = await WalletStore.hasWallet();
      if (!has) {
        walletState.value = WalletState.noWallet;
        return;
      }
      settings.value = await WalletStore.loadSettings();
      final accs = await WalletStore.loadAccounts();
      accounts.assignAll(accs);
      if (accs.isNotEmpty) selectedAccount.value = accs.first;
      walletState.value = WalletState.locked;
    } catch (_) {
      // Plugin not initialized or Keychain error — treat as fresh wallet
      walletState.value = WalletState.noWallet;
    }
  }

  // ── Unlock ────────────────────────────────────────────────────────────────

  Future<bool> unlockWithPassword(String password) async {
    final ok = await vault.unlock(password);
    if (ok) {
      walletState.value = WalletState.unlocked;
      _scheduleAutoLock();
      unawaited(refreshBalances());
      unawaited(refreshPrices());
    }
    return ok;
  }

  Future<bool> unlockWithBiometric() async {
    final ok = await vault.unlockWithBiometric();
    if (ok) {
      walletState.value = WalletState.unlocked;
      _scheduleAutoLock();
      unawaited(refreshBalances());
      unawaited(refreshPrices());
    }
    return ok;
  }

  void lockWallet() {
    vault.lock();
    _autoLockTimer?.cancel();
    walletState.value = WalletState.locked;
  }

  void _scheduleAutoLock() {
    _autoLockTimer?.cancel();
    final secs = settings.value.autoLockSeconds;
    if (secs <= 0) return;
    _autoLockTimer = Timer(Duration(seconds: secs), lockWallet);
  }

  void resetAutoLockTimer() {
    if (walletState.value == WalletState.unlocked) _scheduleAutoLock();
  }

  // ── Create / Import ───────────────────────────────────────────────────────

  Future<String> generateNewMnemonic() async => WalletKey.generateMnemonic();

  Future<void> createWallet(String mnemonic, String password) async {
    final bytes = Uint8List.fromList(utf8.encode(mnemonic));
    await vault.create(bytes, password);
    bytes.fillRange(0, bytes.length, 0);
    await _deriveAndSaveFirstAccount(password);
    await _afterCreate(password);
  }

  Future<void> importWallet(String mnemonic, String password) async {
    if (!WalletKey.validateMnemonic(mnemonic)) throw ArgumentError('Invalid mnemonic');
    final bytes = Uint8List.fromList(utf8.encode(mnemonic));
    await vault.create(bytes, password);
    bytes.fillRange(0, bytes.length, 0);
    await _deriveAndSaveFirstAccount(password);
    await _afterCreate(password);
  }

  Future<void> _deriveAndSaveFirstAccount(String password) async {
    final account = await vault.withMnemonic(password, (mBytes) async {
      final seed = WalletKey.mnemonicToSeed(mBytes);
      try {
        final addrs = _deriveAddresses(seed, 0);
        return WalletAccount.create(name: 'Account 1', index: 0)
            .copyWith(addresses: addrs);
      } finally {
        seed.fillRange(0, seed.length, 0);
      }
    });
    await WalletStore.saveAccounts([account]);
    await WalletStore.saveNextIndex(1);
    accounts.assignAll([account]);
    selectedAccount.value = account;
  }

  Future<void> _afterCreate(String password) async {
    await vault.unlock(password);
    settings.value = await WalletStore.loadSettings();
    walletState.value = WalletState.unlocked;
    _scheduleAutoLock();
    unawaited(refreshBalances());
    unawaited(refreshPrices());
  }

  Map<String, String> _deriveAddresses(Uint8List seed, int index) {
    final evmAddr  = WalletKey.deriveEVMAddress(seed, index);
    final tronAddr = WalletKey.deriveTRONAddress(seed, index);
    return {
      'eth': evmAddr,
      'bsc': evmAddr,
      'polygon': evmAddr,
      'arbitrum': evmAddr,
      'optimism': evmAddr,
      'bsc_testnet': evmAddr,
      'eth_sepolia': evmAddr,
      'tron': tronAddr,
      'tron_shasta': tronAddr,
    };
  }

  // ── Balances ──────────────────────────────────────────────────────────────

  Future<void> refreshBalances() async {
    final account = selectedAccount.value;
    if (account == null) return;
    isLoadingBalances.value = true;
    try {
      final chainKey = selectedChainKey.value;
      var address = account.addresses[chainKey];
      if (address == null) {
        final cfg = chains[chainKey];
        if (cfg?.isTron == true) {
          address = account.addresses['tron'];
        } else if (cfg?.isTestnet == true) {
          address = account.addresses['eth'];
        }
        if (address == null) return;
      }

      if (chains[chainKey]?.isTron == true) {
        final list = await TronService(chainKey: chainKey).getAllBalances(address);
        for (final b in list) {
          balances['$chainKey:${b.symbol}'] = b;
        }
      } else {
        final config = chains[chainKey];
        if (config == null) return;
        final svc = EvmService(config, chainKey);
        final list = await svc.getAllBalances(address);
        for (final b in list) {
          balances['$chainKey:${b.symbol}'] = b;
        }
        svc.dispose();
      }
    } catch (_) {
    } finally {
      isLoadingBalances.value = false;
    }
  }

  // ── Prices ────────────────────────────────────────────────────────────────

  Future<void> refreshPrices() async {
    isLoadingPrices.value = true;
    try {
      final ids = coinGeckoIds.values.toSet().toList();
      final prices = await MarketService.getPrices(ids);
      final result = <String, CoinPrice>{};
      for (final entry in coinGeckoIds.entries) {
        final p = prices[entry.value];
        if (p != null) result[entry.key] = p;
      }
      coinPrices.assignAll(result);
    } finally {
      isLoadingPrices.value = false;
    }
  }

  Future<void> refreshMarketList() async {
    isLoadingMarket.value = true;
    try {
      marketList.assignAll(await MarketService.getMarketList());
    } finally {
      isLoadingMarket.value = false;
    }
  }

  // ── Chain / Account ───────────────────────────────────────────────────────

  void switchChain(String key) {
    selectedChainKey.value = key;
    unawaited(refreshBalances());
  }

  void switchAccount(WalletAccount account) {
    selectedAccount.value = account;
    balances.clear();
    unawaited(refreshBalances());
  }

  // ── Computed ──────────────────────────────────────────────────────────────

  double get totalUsd {
    double t = 0;
    for (final b in balances.values) {
      t += b.balance * (coinPrices[b.symbol]?.price ?? 0);
    }
    return t;
  }

  String get currentAddress {
    final chainKey = selectedChainKey.value;
    final account = selectedAccount.value;
    if (account == null) return '';
    var address = account.addresses[chainKey];
    if (address == null) {
      final cfg = chains[chainKey];
      if (cfg?.isTron == true) {
        address = account.addresses['tron'];
      } else if (cfg?.isTestnet == true) {
        address = account.addresses['eth'];
      }
    }
    return address ?? '';
  }

  List<AssetBalance> get currentChainBalances {
    final key = selectedChainKey.value;
    return balances.values.where((b) => b.chainKey == key).toList();
  }

  // ── Tx History ────────────────────────────────────────────────────────────

  Future<void> loadTxHistory() async {
    final account = selectedAccount.value;
    if (account == null) return;
    final chainKey = selectedChainKey.value;
    var address = account.addresses[chainKey];
    if (address == null) {
      final cfg = chains[chainKey];
      if (cfg?.isTron == true) {
        address = account.addresses['tron'];
      } else if (cfg?.isTestnet == true) {
        address = account.addresses['eth'];
      }
      if (address == null) return;
    }
    try {
      if (chains[chainKey]?.isTron == true) {
        txHistory.assignAll(await TronService(chainKey: chainKey).getTransactionHistory(address));
      } else {
        final config = chains[chainKey];
        if (config == null) return;
        final svc = EvmService(config, chainKey);
        txHistory.assignAll(await svc.getTransactionHistory(address));
        svc.dispose();
      }
    } catch (_) {}
  }

  // ── Testnet mode ──────────────────────────────────────────────────────────

  List<String> get effectiveEnabledChainKeys {
    final keys = settings.value.enabledChainKeys;
    if (!settings.value.testnetMode) return keys;
    return keys
        .map((k) => testnetEquivalents[k] ?? k)
        .where((k) => chains.containsKey(k))
        .toList();
  }

  Future<void> toggleTestnetMode() async {
    final newMode = !settings.value.testnetMode;
    settings.value = settings.value.copyWith(testnetMode: newMode);
    await WalletStore.saveSettings(settings.value);

    final current = selectedChainKey.value;
    final cfg = chains[current];
    if (newMode && cfg != null && !cfg.isTestnet) {
      final equiv = testnetEquivalents[current];
      if (equiv != null) selectedChainKey.value = equiv;
    } else if (!newMode && cfg?.isTestnet == true) {
      final mainnet = testnetEquivalents.entries
          .where((e) => e.value == current)
          .map((e) => e.key)
          .firstOrNull;
      if (mainnet != null) selectedChainKey.value = mainnet;
    }
    unawaited(refreshBalances());
  }
}
