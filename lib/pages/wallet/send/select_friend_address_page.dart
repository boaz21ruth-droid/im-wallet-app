import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_openim_sdk/flutter_openim_sdk.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import '../../../services/wallet/backend_wallet_service.dart';

/// Single-select friend list for filling in a wallet send-to address.
/// Returns the selected address via [Get.back(result: address)].
class SelectFriendAddressPage extends StatefulWidget {
  final String chainKey;

  const SelectFriendAddressPage({super.key, required this.chainKey});

  @override
  State<SelectFriendAddressPage> createState() =>
      _SelectFriendAddressPageState();
}

class _SelectFriendAddressPageState extends State<SelectFriendAddressPage> {
  final _searchCtrl = TextEditingController();
  List<FriendInfo> _allFriends = [];
  List<FriendInfo> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFriends() async {
    try {
      final friends =
          await OpenIM.iMManager.friendshipManager.getFriendList();
      if (!mounted) return;
      setState(() {
        _allFriends = friends;
        _filtered = friends;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = _allFriends;
      } else {
        _filtered = _allFriends.where((f) {
          final name = (f.remark?.isNotEmpty == true ? f.remark! : f.nickname ?? '').toLowerCase();
          return name.contains(q) || (f.userID ?? '').toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  Future<void> _selectFriend(FriendInfo friend) async {
    EasyLoading.show(status: '查询中...');
    final address = await BackendWalletService.getFriendAddress(
      friend.userID!,
      widget.chainKey,
    );
    EasyLoading.dismiss();

    if (!mounted) return;

    if (address == null || address.isEmpty) {
      EasyLoading.showError('对方尚未绑定 ${widget.chainKey} 地址');
      return;
    }
    Get.back(result: address);
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
          '选择联系人',
          style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Styles.c_0C1C33),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: '搜索好友',
                hintStyle: TextStyle(color: Styles.c_8E9AB0, fontSize: 13.sp),
                prefixIcon:
                    Icon(Icons.search, color: Styles.c_8E9AB0, size: 20.w),
                filled: true,
                fillColor: Styles.c_FFFFFF,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: Styles.c_E8EAEF),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: Styles.c_E8EAEF),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(color: Styles.c_0089FF),
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(
                        child: Text(
                          '暂无好友',
                          style: TextStyle(
                              fontSize: 14.sp, color: Styles.c_8E9AB0),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Styles.c_E8EAEF,
                          indent: 72.w,
                        ),
                        itemBuilder: (_, i) {
                          final f = _filtered[i];
                          final displayName = f.remark?.isNotEmpty == true
                              ? f.remark!
                              : f.nickname ?? '';
                          return ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 4.h),
                            leading: AvatarView(
                              width: 42.r,
                              height: 42.r,
                              url: f.faceURL,
                              text: displayName,
                            ),
                            title: Text(
                              displayName,
                              style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w500,
                                  color: Styles.c_0C1C33),
                            ),
                            onTap: () => _selectFriend(f),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
