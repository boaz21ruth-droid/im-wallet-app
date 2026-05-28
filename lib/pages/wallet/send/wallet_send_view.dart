import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';
import '../../../services/totp_service.dart';
import '../../../services/wallet/chain_config.dart';
import '../../../services/wallet/evm_service.dart';
import '../../../services/wallet/tron_service.dart';
import '../../../services/wallet/wallet_key.dart';
import '../../../services/wallet/wallet_models.dart';
import '../wallet_logic.dart';
import 'totp_verify_dialog.dart';

class WalletSendView extends StatefulWidget {
  final String? prefillAddress;
  final AssetBalance? prefillAsset;

  const WalletSendView({super.key, this.prefillAddress, this.prefillAsset});

  @override
  State<WalletSendView> createState() => _WalletSendViewState();
}

class _WalletSendViewState extends State<WalletSendView> {
  final logic = Get.find<WalletLogic>();
  final _addrCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();

  AssetBalance? _selectedAsset;
  BigInt _estimatedGas = BigInt.zero;
  BigInt _gasPrice = BigInt.zero;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.prefillAddress != null) _addrCtrl.text = widget.prefillAddress!;
    _selectedAsset = widget.prefillAsset ?? logic.currentChainBalances.firstOrNull;
  }

  @override
  void dispose() {
    _addrCtrl.dispose();
    _amtCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _estimateGas() async {
    final addr = _addrCtrl.text.trim();
    final amtText = _amtCtrl.text.trim();
    final asset = _selectedAsset;
    if (addr.isEmpty || amtText.isEmpty || asset == null) return;

    try {
      final chainKey = logic.selectedChainKey.value;
      final config = chains[chainKey];
      if (config == null) return;
      final svc = EvmService(config, chainKey);
      _gasPrice = await svc.getGasPrice();
      final from = logic.currentAddress;
      final amtDouble = double.tryParse(amtText) ?? 0;
      final amtRaw = BigInt.from(amtDouble * BigInt.from(10).pow(asset.decimals).toDouble());
      _estimatedGas = await svc.estimateTransferGas(
        from: from,
        to: addr,
        value: asset.isNative ? amtRaw : BigInt.zero,
      );
      svc.dispose();
      setState(() {});
    } catch (_) {
      _estimatedGas = BigInt.from(21000);
    }
  }

  double get _gasCostEth {
    if (_estimatedGas == BigInt.zero || _gasPrice == BigInt.zero) return 0;
    final weiCost = _estimatedGas * _gasPrice;
    return weiCost.toDouble() / 1e18;
  }

  void _showConfirm() {
    final addr = _addrCtrl.text.trim();
    final amtText = _amtCtrl.text.trim();
    if (addr.isEmpty) {
      setState(() => _error = '请输入收款地址');
      return;
    }
    if (amtText.isEmpty || (double.tryParse(amtText) ?? 0) <= 0) {
      setState(() => _error = '请输入有效金额');
      return;
    }
    setState(() => _error = null);
    _showPasswordDialog();
  }

  void _showPasswordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Styles.c_FFFFFF,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          20.w,
          20.h,
          20.w,
          MediaQuery.of(context).viewInsets.bottom + 20.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '确认交易',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Styles.c_0C1C33),
            ),
            SizedBox(height: 16.h),
            _buildConfirmRow('发送', '${_amtCtrl.text} ${_selectedAsset?.symbol ?? ''}'),
            _buildConfirmRow('至', _addrCtrl.text),
            if (_gasCostEth > 0)
              _buildConfirmRow('手续费', '≈ ${_gasCostEth.toStringAsFixed(8)} ETH'),
            SizedBox(height: 16.h),
            Text('输入密码确认', style: TextStyle(fontSize: 14.sp, color: Styles.c_8E9AB0)),
            SizedBox(height: 8.h),
            TextField(
              controller: _pwdCtrl,
              obscureText: true,
              style: TextStyle(fontSize: 16.sp),
              decoration: InputDecoration(
                hintText: '钱包密码',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _sending ? null : _sendTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Styles.c_0089FF,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '确认发送',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          SizedBox(
            width: 60.w,
            child: Text(label, style: TextStyle(fontSize: 14.sp, color: Styles.c_8E9AB0)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14.sp, color: Styles.c_0C1C33, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTransaction() async {
    setState(() => _sending = true);
    Get.back(); // close password bottom sheet

    // Gate on Google Authenticator (TOTP) if the user has it enabled.
    // The dialog only completes when the backend accepts the code or the user
    // explicitly cancels. The backend treats users without TOTP as a pass-through.
    final totpEnabled = await TotpService.status();
    if (totpEnabled) {
      if (!mounted) {
        setState(() => _sending = false);
        return;
      }
      final ok = await showTotpVerifyDialog(context);
      if (!ok) {
        setState(() => _sending = false);
        return;
      }
    }

    EasyLoading.show(status: '发送中...');
    try {
      final pwd = _pwdCtrl.text;
      final to = _addrCtrl.text.trim();
      final amtDouble = double.tryParse(_amtCtrl.text.trim()) ?? 0;
      final asset = _selectedAsset!;
      final amtRaw = BigInt.from(amtDouble * BigInt.from(10).pow(asset.decimals).toDouble());
      final chainKey = logic.selectedChainKey.value;

      String? txHash;

      await logic.vault.withMnemonic(pwd, (mBytes) async {
        final seed = WalletKey.mnemonicToSeed(mBytes);
        try {
          if (chains[chainKey]?.isTron == true) {
            final privKey = WalletKey.deriveTRONPrivKey(seed, logic.selectedAccount.value!.index);
            try {
              final svc = TronService(chainKey: chainKey);
              if (asset.isNative) {
                txHash = await svc.sendTrx(privateKey: privKey, to: to, amountSun: amtRaw);
              } else {
                txHash = await svc.sendTrc20(
                  privateKey: privKey,
                  contractAddress: asset.contractAddress!,
                  to: to,
                  amount: amtRaw,
                );
              }
            } finally {
              privKey.fillRange(0, privKey.length, 0);
            }
          } else {
            final config = chains[chainKey]!;
            final evmKey = WalletKey.deriveEVMKey(seed, logic.selectedAccount.value!.index);
            final svc = EvmService(config, chainKey);
            if (asset.isNative) {
              txHash = await svc.sendNative(senderKey: evmKey, to: to, value: amtRaw);
            } else {
              txHash = await svc.sendToken(
                senderKey: evmKey,
                tokenContract: asset.contractAddress!,
                to: to,
                amount: amtRaw,
              );
            }
            svc.dispose();
          }
        } finally {
          seed.fillRange(0, seed.length, 0);
        }
      });

      EasyLoading.dismiss();
      if (txHash != null) {
        EasyLoading.showSuccess('交易已广播\n$txHash');
        Get.back();
      } else {
        EasyLoading.showError('交易失败');
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('错误: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  Future<void> _pasteAddress() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isNotEmpty) {
      setState(() {
        _addrCtrl.text = text;
        _error = null;
      });
    }
  }

  Future<void> _scanQR() async {
    final result = await Get.to<String?>(() => const _QRScanPage());
    if (result != null && result.isNotEmpty) {
      setState(() {
        _addrCtrl.text = result;
        _error = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.c_F8F9FA,
      appBar: AppBar(
        backgroundColor: Styles.c_F8F9FA,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Styles.c_0C1C33, size: 18.w),
          onPressed: () => Get.back(),
        ),
        title: Text(
          '发送',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Styles.c_0C1C33),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('收款地址'),
            SizedBox(height: 8.h),
            _buildAddressField(),
            SizedBox(height: 20.h),
            _buildLabel('选择资产'),
            SizedBox(height: 8.h),
            _buildAssetSelector(),
            SizedBox(height: 20.h),
            _buildLabel('金额'),
            SizedBox(height: 8.h),
            _buildAmountField(),
            if (_estimatedGas > BigInt.zero) ...[
              SizedBox(height: 12.h),
              Text(
                '预估手续费: ≈ ${_gasCostEth.toStringAsFixed(8)} ETH',
                style: TextStyle(fontSize: 13.sp, color: Styles.c_8E9AB0),
              ),
            ],
            if (_error != null) ...[
              SizedBox(height: 12.h),
              Text(_error!, style: TextStyle(fontSize: 13.sp, color: Colors.red)),
            ],
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: _showConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Styles.c_0089FF,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '下一步',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500, color: Styles.c_0C1C33),
    );
  }

  Widget _buildAddressField() {
    return Container(
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Styles.c_E8EAEF),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _addrCtrl,
              style: TextStyle(fontSize: 14.sp, color: Styles.c_0C1C33),
              decoration: InputDecoration(
                hintText: '粘贴或扫描地址',
                hintStyle: TextStyle(color: Styles.c_8E9AB0, fontSize: 13.sp),
                contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                border: InputBorder.none,
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
          ),
          IconButton(
            icon: Icon(Icons.content_paste_rounded, color: Styles.c_0089FF, size: 22.w),
            onPressed: _pasteAddress,
            tooltip: '粘贴地址',
          ),
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: Styles.c_0089FF, size: 22.w),
            onPressed: _scanQR,
            tooltip: '扫描二维码',
          ),
        ],
      ),
    );
  }

  Widget _buildAssetSelector() {
    return Obx(() {
      final assets = logic.currentChainBalances;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Styles.c_FFFFFF,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Styles.c_E8EAEF),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<AssetBalance>(
            value: _selectedAsset,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down, color: Styles.c_8E9AB0),
            style: TextStyle(fontSize: 15.sp, color: Styles.c_0C1C33),
            onChanged: (v) => setState(() => _selectedAsset = v),
            items: assets.map((b) {
              return DropdownMenuItem(
                value: b,
                child: Row(
                  children: [
                    Text(
                      b.symbol,
                      style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      b.balance < 1
                          ? b.balance.toStringAsFixed(6)
                          : b.balance.toStringAsFixed(4),
                      style: TextStyle(fontSize: 13.sp, color: Styles.c_8E9AB0),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }

  Widget _buildAmountField() {
    return Container(
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Styles.c_E8EAEF),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                // Replace Chinese full-stop 。 with ASCII period (Chinese keyboard quirk)
                TextInputFormatter.withFunction((oldVal, newVal) {
                  final fixed = newVal.text.replaceAll('。', '.');
                  if (fixed == newVal.text) return newVal;
                  return newVal.copyWith(
                    text: fixed,
                    selection: TextSelection.collapsed(offset: fixed.length),
                  );
                }),
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              style: TextStyle(fontSize: 16.sp, color: Styles.c_0C1C33),
              decoration: InputDecoration(
                hintText: '0.0',
                hintStyle: TextStyle(color: Styles.c_8E9AB0, fontSize: 14.sp),
                contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                border: InputBorder.none,
              ),
              onChanged: (_) {
                setState(() => _error = null);
                _estimateGas();
              },
            ),
          ),
          TextButton(
            onPressed: () {
              final asset = _selectedAsset;
              if (asset != null) {
                _amtCtrl.text = asset.balance.toStringAsFixed(8);
              }
            },
            child: Text(
              '最大',
              style: TextStyle(color: Styles.c_0089FF, fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class _QRScanPage extends StatelessWidget {
  const _QRScanPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('扫描 QR 码'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: ReaderWidget(
        onScan: (code) {
          if (code.isValid && code.text != null) {
            Get.back(result: code.text);
          }
        },
      ),
    );
  }
}

