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
import '../../services/wallet/backend_wallet_service.dart';
import '../../services/wallet/swap/swap_config_service.dart';
import '../../core/controller/im_controller.dart';
import '../../services/wallet/wallet_store.dart';

class WalletLogic extends GetxController with WidgetsBindingObserver {
  final walletState = WalletState.loading.obs;
  final accounts = <WalletAccount>[].obs;
  final selectedAccount = Rxn<WalletAccount>();
  final selectedChainKey = 'eth'.obs;
  final settings = Rx<WalletSettings>(WalletSettings.defaults);

  final balances = <String, AssetBalance>{}.obs; // key: "$chainKey:$symbol"
  final coinPrices = <String, CoinPrice>{}.obs; // key: symbol (e.g. "ETH")
  final txHistory = <TxRecord>[].obs;
  final tokenHistory = <TxRecord>[].obs;
  final marketList = <CoinMarketData>[].obs;

  final isLoadingBalances = false.obs;
  final isLoadingPrices = false.obs;
  final isLoadingMarket = false.obs;
  final isLoadingTokenHistory = false.obs;

  final newsFilter = 0.obs; // 0=广场, 1=公告

  late WalletStore _store;
  late MnemonicVault vault;
  Timer? _autoLockTimer;
  DateTime? _backgroundedAt;

  @override
  void onInit() {
    super.onInit();
    final userID = Get.find<IMController>().userInfo.value.userID ?? '';
    _store = WalletStore(userID);
    vault = MnemonicVault(userID);
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
      final has = await _store.hasWallet();
      if (!has) {
        walletState.value = WalletState.noWallet;
        return;
      }
      settings.value = await _store.loadSettings();
      final accs = await _store.loadAccounts();
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
      unawaited(_registerBackendAddresses());
      unawaited(_refreshSwapConfig());
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
      unawaited(_registerBackendAddresses());
      unawaited(_refreshSwapConfig());
    }
    return ok;
  }

  /// Pulls the latest swap config (0x key, per-chain RPCs / fee recipient /
  /// router whitelist, limits) so the swap page sees rotated values without
  /// requiring an app release. Silently no-ops if SwapConfigService isn't
  /// registered (it lives behind SwapBinding, which is permanent once first
  /// touched).
  Future<void> _refreshSwapConfig() async {
    if (!Get.isRegistered<SwapConfigService>()) return;
    await SwapConfigService.to.fetchAndCache();
  }

  Future<void> _registerBackendAddresses() async {
    final account = selectedAccount.value;
    if (account == null || account.addresses.isEmpty) return;
    await BackendWalletService.registerAddresses(account.addresses);
  }

  void lockWallet() {
    vault.lock();
    _autoLockTimer?.cancel();
    walletState.value = WalletState.locked;
  }

  Future<void> deleteLocalWallet() async {
    _autoLockTimer?.cancel();

    // Storage deletes can fail independently (Keychain ACL, locked device).
    // Catch each so a single failure doesn't abort the whole cleanup, and so
    // the caller sees a single aggregated error.
    final errors = <String>[];
    try {
      await vault.deleteWallet();
    } catch (e) {
      debugPrint('vault.deleteWallet failed: $e');
      errors.add('vault: $e');
    }
    try {
      await _store.clear();
    } catch (e) {
      debugPrint('_store.clear failed: $e');
      errors.add('store: $e');
    }

    // Always reset in-memory state — Obx-driven UI will switch to
    // WalletOnboardView. Even if storage deletes failed, the user is locked
    // out of the wallet until they re-enter a password.
    accounts.clear();
    selectedAccount.value = null;
    balances.clear();
    txHistory.clear();
    tokenHistory.clear();
    walletState.value = WalletState.noWallet;

    if (errors.isNotEmpty) {
      throw Exception(errors.join('; '));
    }
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
    if (!WalletKey.validateMnemonic(mnemonic)) {
      throw ArgumentError('Invalid mnemonic');
    }
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
    await _store.saveAccounts([account]);
    await _store.saveNextIndex(1);
    accounts.assignAll([account]);
    selectedAccount.value = account;
  }

  Future<void> _afterCreate(String password) async {
    await vault.unlock(password);
    settings.value = await _store.loadSettings();
    walletState.value = WalletState.unlocked;
    _scheduleAutoLock();
    unawaited(refreshBalances());
    unawaited(refreshPrices());
    unawaited(_registerBackendAddresses());
    unawaited(_refreshSwapConfig());
  }

  Map<String, String> _deriveAddresses(Uint8List seed, int index) {
    final evmAddr = WalletKey.deriveEVMAddress(seed, index);
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
    isLoadingBalances.value = true;
    try {
      await _fetchBalancesFor(selectedChainKey.value);
    } finally {
      isLoadingBalances.value = false;
    }
  }

  /// Refreshes balances for an arbitrary chain — used by Swap when its picker
  /// is on a chain the wallet main page hasn't selected.
  Future<void> refreshBalancesForChain(String chainKey) =>
      _fetchBalancesFor(chainKey);

  Future<void> _fetchBalancesFor(String chainKey) async {
    final account = selectedAccount.value;
    if (account == null) return;
    try {
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
        final list =
            await TronService(chainKey: chainKey).getAllBalances(address);
        for (final b in list) {
          balances['$chainKey:${b.symbol}'] = b;
        }
      } else {
        final config = chains[chainKey];
        if (config == null) return;
        final rpcsOverride = _swapConfigRpcs(chainKey);
        final svc = EvmService(config, chainKey, rpcsOverride: rpcsOverride);
        final list = await svc.getAllBalances(address);
        for (final b in list) {
          balances['$chainKey:${b.symbol}'] = b;
        }
        svc.dispose();
      }
    } catch (_) {}
  }

  /// Returns the RPC list the swap config wants for `chainKey`, or null when
  /// the service isn't registered yet (i.e. before the first Swap entry).
  List<String>? _swapConfigRpcs(String chainKey) {
    if (!Get.isRegistered<SwapConfigService>()) return null;
    final rpcs = SwapConfigService.to.current.chains[chainKey]?.rpcs;
    return (rpcs == null || rpcs.isEmpty) ? null : rpcs;
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

  List<AssetBalance> get currentChainBalances =>
      balancesForChain(selectedChainKey.value);

  /// Returns the held balances for `chainKey`, irrespective of which chain the
  /// wallet main view currently has selected. Used by Swap, which has its own
  /// independent chain picker.
  List<AssetBalance> balancesForChain(String chainKey) =>
      balances.values.where((b) => b.chainKey == chainKey).toList();

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
        txHistory.assignAll(await TronService(chainKey: chainKey)
            .getTransactionHistory(address));
      } else {
        final config = chains[chainKey];
        if (config == null) return;
        final svc = EvmService(config, chainKey);
        txHistory.assignAll(await svc.getTransactionHistory(address));
        svc.dispose();
      }
    } catch (_) {}
  }

  Future<void> loadTokenHistory(AssetBalance asset) async {
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

    isLoadingTokenHistory.value = true;
    tokenHistory.clear();
    try {
      // Try backend first
      final backendRecords = await BackendWalletService.getTxHistory(
        chainKey: chainKey,
        contractAddress: asset.contractAddress,
      );
      if (backendRecords != null) {
        tokenHistory.assignAll(backendRecords);
        return;
      }

      // Fall back to client-side RPC
      List<TxRecord> records;
      if (chains[chainKey]?.isTron == true) {
        final svc = TronService(chainKey: chainKey);
        if (asset.isNative) {
          records = await svc.getTransactionHistory(address);
        } else {
          records = await svc.getTrc20TransferHistory(
              address, asset.contractAddress!);
        }
      } else {
        final config = chains[chainKey];
        if (config == null) return;
        final svc = EvmService(config, chainKey);
        if (asset.isNative) {
          records = await svc.getTransactionHistory(address);
        } else {
          records = await svc.getErc20TransferHistory(
              address, asset.contractAddress!);
        }
        svc.dispose();
      }
      tokenHistory.assignAll(records);
    } catch (_) {
    } finally {
      isLoadingTokenHistory.value = false;
    }
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<void> setAutoLockSeconds(int seconds) async {
    settings.value = settings.value.copyWith(autoLockSeconds: seconds);
    await _store.saveSettings(settings.value);
    _scheduleAutoLock();
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
    await _store.saveSettings(settings.value);

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
