import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:web3dart/web3dart.dart';
import '../../../services/wallet/wallet_key.dart';
import '../wallet_logic.dart';
import 'p2p_models.dart';
import 'p2p_service.dart';

class P2PLogic extends GetxController {
  final _walletLogic = Get.find<WalletLogic>();

  final openOrders   = <P2POrder>[].obs;
  final mySellingOrders = <P2POrder>[].obs;
  final myBuyingOrders  = <P2POrder>[].obs;
  final isLoadingHall = false.obs;
  final isLoadingMine = false.obs;

  String get _address => _walletLogic.currentAddress;

  Future<void> refreshHall() async {
    isLoadingHall.value = true;
    openOrders.value = await P2PService.fetchOpen();
    isLoadingHall.value = false;
  }

  Future<void> refreshMine() async {
    if (_address.isEmpty) return;
    isLoadingMine.value = true;
    final results = await Future.wait([
      P2PService.fetchMySelling(_address),
      P2PService.fetchMyBuying(_address),
    ]);
    mySellingOrders.value = results[0];
    myBuyingOrders.value  = results[1];
    isLoadingMine.value   = false;
  }

  // ── Contract actions ──────────────────────────────────────────────────────

  Future<EthPrivateKey?> _loadKey() async {
    try {
      return await _walletLogic.vault.withCachedMnemonic((mBytes) async {
        final seed = WalletKey.mnemonicToSeed(mBytes);
        final key  = WalletKey.deriveEVMKey(seed, 0);
        seed.fillRange(0, seed.length, 0);
        return key;
      });
    } catch (_) {
      return null;
    }
  }

  Future<bool> doTakeOrder(P2POrder order) async {
    EasyLoading.show(status: '接单中...');
    try {
      final key = await _loadKey();
      if (key == null) { EasyLoading.dismiss(); return false; }
      await P2PService.takeOrder(key, order.orderId);
      EasyLoading.showSuccess('接单成功，请在30分钟内完成付款');
      await refreshHall();
      return true;
    } catch (e) {
      EasyLoading.showError('接单失败: $e');
      return false;
    }
  }

  Future<bool> doMarkPaid(P2POrder order) async {
    EasyLoading.show(status: '确认中...');
    try {
      final key = await _loadKey();
      if (key == null) { EasyLoading.dismiss(); return false; }
      await P2PService.markPaid(key, order.orderId);
      EasyLoading.showSuccess('已标记付款，等待卖家确认');
      await refreshMine();
      return true;
    } catch (e) {
      EasyLoading.showError('操作失败: $e');
      return false;
    }
  }

  Future<bool> doConfirmRelease(P2POrder order) async {
    EasyLoading.show(status: '确认放币中...');
    try {
      final key = await _loadKey();
      if (key == null) { EasyLoading.dismiss(); return false; }
      await P2PService.confirmRelease(key, order.orderId);
      EasyLoading.showSuccess('已放币，交易完成');
      await refreshMine();
      return true;
    } catch (e) {
      EasyLoading.showError('操作失败: $e');
      return false;
    }
  }

  Future<bool> doCancel(P2POrder order) async {
    EasyLoading.show(status: '取消中...');
    try {
      final key = await _loadKey();
      if (key == null) { EasyLoading.dismiss(); return false; }
      await P2PService.cancelOpenOrder(key, order.orderId);
      EasyLoading.showSuccess('订单已取消');
      await refreshMine();
      return true;
    } catch (e) {
      EasyLoading.showError('取消失败: $e');
      return false;
    }
  }

  Future<bool> doRaiseDispute(P2POrder order) async {
    EasyLoading.show(status: '申诉中...');
    try {
      final key = await _loadKey();
      if (key == null) { EasyLoading.dismiss(); return false; }
      await P2PService.raiseDispute(key, order.orderId);
      EasyLoading.showSuccess('申诉已提交，等待平台仲裁');
      await refreshMine();
      return true;
    } catch (e) {
      EasyLoading.showError('操作失败: $e');
      return false;
    }
  }

  Future<bool> doCreateOrder({
    required String usdtContract,
    required BigInt amount,
    required int fiatAmount,
    required String payMethod,
    required int lockMinutes,
  }) async {
    EasyLoading.show(status: '发布中...');
    try {
      final key = await _loadKey();
      if (key == null) { EasyLoading.dismiss(); return false; }
      // Step 1: approve
      EasyLoading.show(status: '授权 USDT...');
      await P2PService.approveUsdt(key: key, amount: amount, usdtContract: usdtContract);
      await Future.delayed(const Duration(seconds: 4)); // wait for tx to land
      // Step 2: createOrder
      EasyLoading.show(status: '发布订单...');
      await P2PService.createOrder(
        key: key,
        usdtContract: usdtContract,
        amount: amount,
        fiatAmount: fiatAmount,
        payMethod: payMethod,
        lockMinutes: lockMinutes,
      );
      EasyLoading.showSuccess('订单已发布，等待买家接单');
      await refreshMine();
      return true;
    } catch (e) {
      EasyLoading.showError('发布失败: $e');
      return false;
    }
  }
}
