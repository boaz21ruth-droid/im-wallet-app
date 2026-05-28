import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../wallet_logic.dart';

/// View the wallet's mnemonic, gated by warning + password.
///
/// Flow: warning → password → revealed (blurred → tap to show, auto-hide after 60s).
///
/// Security:
///   - Decryption uses [MnemonicVault.withMnemonic] (PBKDF2 + AES-GCM)
///   - Background → app lifecycle re-blurs immediately
///   - Auto re-blur after 60s of visible plaintext
///   - Clipboard copy requires a confirmation step
///
/// Known limitation: Dart strings are immutable so the decoded words sit in
/// memory until GC. Same as wallet creation flow.
class MnemonicRevealPage extends StatefulWidget {
  const MnemonicRevealPage({super.key});

  @override
  State<MnemonicRevealPage> createState() => _MnemonicRevealPageState();
}

enum _Phase { warning, password, revealed }

class _MnemonicRevealPageState extends State<MnemonicRevealPage>
    with WidgetsBindingObserver {
  final WalletLogic _logic = Get.find<WalletLogic>();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();

  _Phase _phase = _Phase.warning;
  List<String> _words = const [];
  bool _showing = false; // false = blurred overlay
  bool _verifying = false;
  String? _passwordError;
  Timer? _autoHide;
  int _secondsLeft = 0;

  static const _visibleSeconds = 60;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoHide?.cancel();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    // Best-effort: replace the words list with empties before release.
    _words = const [];
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-blur when the app goes to background. Prevents shoulder-surfing via
    // app switcher screenshots on iOS, and matches MetaMask/Trust Wallet
    // behavior.
    if (state != AppLifecycleState.resumed && _showing) {
      _reBlur();
    }
  }

  Future<void> _verifyPassword() async {
    final pwd = _passwordCtrl.text;
    if (pwd.isEmpty) {
      setState(() => _passwordError = '请输入密码');
      return;
    }
    setState(() {
      _verifying = true;
      _passwordError = null;
    });
    try {
      final words = await _logic.vault.withMnemonic(pwd, (mBytes) async {
        return utf8.decode(mBytes).split(' ');
      });
      if (!mounted) return;
      setState(() {
        _words = words;
        _phase = _Phase.revealed;
        _showing = false; // start blurred — user explicitly taps to reveal
        _verifying = false;
        _passwordCtrl.clear();
      });
      _passwordFocus.unfocus();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _passwordError = '密码错误';
        _passwordCtrl.clear();
      });
    }
  }

  void _reveal() {
    setState(() {
      _showing = true;
      _secondsLeft = _visibleSeconds;
    });
    _autoHide?.cancel();
    _autoHide = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        _reBlur();
      }
    });
  }

  void _reBlur() {
    _autoHide?.cancel();
    setState(() {
      _showing = false;
      _secondsLeft = 0;
    });
  }

  Future<void> _copyToClipboard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('复制助记词？'),
        content: const Text('剪贴板内容可能被其他 App 读取。仅在你了解风险时继续。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('复制',
                style: TextStyle(color: Color(0xFFB42318))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await Clipboard.setData(ClipboardData(text: _words.join(' ')));
    IMViews.showToast('已复制到剪贴板，请尽快粘贴并清除');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        appBar: TitleBar.back(title: '备份助记词'),
        backgroundColor: Styles.c_F8F9FA,
        body: SafeArea(child: _buildPhase()),
      ),
    );
  }

  Widget _buildPhase() {
    return switch (_phase) {
      _Phase.warning => _buildWarning(),
      _Phase.password => _buildPasswordPrompt(),
      _Phase.revealed => _buildReveal(),
    };
  }

  // ── Phase 1: warning ──────────────────────────────────────────────────────

  Widget _buildWarning() {
    final bullets = [
      '任何人拿到助记词都可以转走你的所有资产，包括我们也无法帮你找回。',
      '请确保身边无人、无摄像头、无屏幕共享。',
      '不要把助记词发送给任何人、不要输入到任何网站或 App。',
      '不要截屏、录屏或拍照，使用手抄保存最安全。',
    ];
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFEDD5), Color(0xFFFFE4E6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFB45309), size: 44),
                SizedBox(height: 8.h),
                Text(
                  '查看前请仔细阅读',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7C2D12),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          ...bullets.map((b) => Padding(
                padding: EdgeInsets.only(bottom: 14.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 6.h),
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB45309),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Styles.c_0C1C33,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          SizedBox(height: 24.h),
          SizedBox(
            height: 50.h,
            child: ElevatedButton(
              onPressed: () => setState(() {
                _phase = _Phase.password;
                _passwordFocus.requestFocus();
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.c_0089FF,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: Text('我已了解，继续',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Phase 2: password ─────────────────────────────────────────────────────

  Widget _buildPasswordPrompt() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '输入钱包密码',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Styles.c_0C1C33,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '请输入创建/导入钱包时设置的密码以解密助记词。',
            style: TextStyle(fontSize: 13.sp, color: Styles.c_8E9AB0),
          ),
          SizedBox(height: 20.h),
          TextField(
            controller: _passwordCtrl,
            focusNode: _passwordFocus,
            obscureText: true,
            enabled: !_verifying,
            onSubmitted: (_) => _verifyPassword(),
            decoration: InputDecoration(
              hintText: '钱包密码',
              hintStyle: TextStyle(color: Styles.c_8E9AB0, fontSize: 14.sp),
              filled: true,
              fillColor: Styles.c_FFFFFF,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            ),
            onChanged: (_) => setState(() => _passwordError = null),
          ),
          if (_passwordError != null) ...[
            SizedBox(height: 8.h),
            Text(_passwordError!,
                style: TextStyle(fontSize: 12.sp, color: Colors.red)),
          ],
          SizedBox(height: 24.h),
          SizedBox(
            height: 50.h,
            child: ElevatedButton(
              onPressed: _verifying ? null : _verifyPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.c_0089FF,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: _verifying
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text('确认',
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Phase 3: revealed (blurred → tap to show, auto-hide) ──────────────────

  Widget _buildReveal() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showing)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: const Color(0xFFFFD591)),
              ),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined,
                      size: 16.w, color: const Color(0xFFFA8C16)),
                  SizedBox(width: 6.w),
                  Text('将在 $_secondsLeft 秒后自动隐藏',
                      style: TextStyle(
                          fontSize: 12.sp, color: const Color(0xFF8C5A1A))),
                ],
              ),
            ),
          _buildMnemonicGrid(),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showing ? _reBlur : null,
                  icon: const Icon(Icons.visibility_off_outlined, size: 18),
                  label: Text('隐藏',
                      style: TextStyle(fontSize: 14.sp)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Styles.c_8E9AB0,
                    side: BorderSide(color: Styles.c_E8EAEF),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showing ? _copyToClipboard : null,
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text('复制', style: TextStyle(fontSize: 14.sp)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Styles.c_0089FF,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildHandwriteHint(),
        ],
      ),
    );
  }

  Widget _buildMnemonicGrid() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Styles.c_FFFFFF,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _words.length,
            itemBuilder: (_, i) => Container(
              decoration: BoxDecoration(
                color: Styles.c_0089FF.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: Row(
                children: [
                  Text(
                    '${i + 1}.',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Styles.c_8E9AB0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      _showing ? _words[i] : '••••',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Styles.c_0C1C33,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_showing)
            Positioned.fill(
              child: GestureDetector(
                onTap: _reveal,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.78),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.visibility,
                          color: Colors.white, size: 32),
                      SizedBox(height: 8.h),
                      Text(
                        '点击显示助记词',
                        style:
                            TextStyle(color: Colors.white, fontSize: 14.sp),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '确认周围无人后再点击',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHandwriteHint() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Styles.c_F8F9FA,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: Styles.c_E8EAEF),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, size: 18.w, color: Styles.c_8E9AB0),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              '建议手抄助记词到纸上，分散保存。截图、云相册、聊天记录都可能被窃取。',
              style: TextStyle(
                fontSize: 12.sp,
                color: Styles.c_8E9AB0,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
