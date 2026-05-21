import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

import 'calls_logic.dart';

class CallsPage extends StatelessWidget {
  final logic = Get.find<CallsLogic>();

  CallsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles.c_F8F9FA,
      appBar: AppBar(
        backgroundColor: Styles.c_FFFFFF,
        elevation: 0,
        title: '通话'.toText..style = Styles.ts_0C1C33_20sp_semibold,
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.call_outlined, size: 64.r, color: Styles.c_8E9AB0),
            16.verticalSpace,
            '暂无通话记录'.toText..style = Styles.ts_8E9AB0_14sp,
          ],
        ),
      ),
    );
  }
}
