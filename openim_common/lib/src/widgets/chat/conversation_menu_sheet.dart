import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';

class ConversationMenuSheet extends StatelessWidget {
  const ConversationMenuSheet({
    Key? key,
    required this.isPinned,
    this.onPin,
    this.onHide,
  }) : super(key: key);

  final bool isPinned;
  final VoidCallback? onPin;
  final VoidCallback? onHide;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: Styles.c_FFFFFF,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: Styles.c_E8EAEF,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            _ActionTile(
              icon: isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              label: isPinned ? StrRes.unpinConversation : StrRes.pinConversation,
              onTap: onPin ?? () {},
            ),
            if (onHide != null)
              _ActionTile(
                icon: Icons.hide_source_outlined,
                label: StrRes.hideConversation,
                onTap: onHide!,
              ),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Styles.c_FF381F : Styles.c_0C1C33;
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      child: Container(
        height: 52.h,
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          children: [
            Icon(icon, size: 22.r, color: color),
            12.horizontalSpace,
            Text(label, style: TextStyle(fontSize: 16.sp, color: color)),
          ],
        ),
      ),
    );
  }
}
