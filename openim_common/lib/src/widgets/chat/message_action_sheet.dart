import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';

class MessageActionSheet extends StatelessWidget {
  const MessageActionSheet({
    Key? key,
    this.onReply,
    this.onForward,
    this.onCopy,
    this.onDelete,
    this.onReact,
  }) : super(key: key);

  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final VoidCallback? onCopy;
  final VoidCallback? onDelete;
  final ValueChanged<String>? onReact;

  static const _quickEmojis = ['❤️', '😂', '😮', '😢', '😡', '👍'];

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
            if (onReact != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _quickEmojis.map((emoji) => GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onReact!(emoji);
                    },
                    child: Text(emoji, style: TextStyle(fontSize: 28.sp)),
                  )).toList(),
                ),
              ),
            if (onReact != null) Divider(height: 0.5.h, color: Styles.c_E8EAEF),
            if (onReply != null) _ActionTile(icon: Icons.reply, label: StrRes.menuReply, onTap: onReply!),
            if (onForward != null) _ActionTile(icon: Icons.forward, label: StrRes.menuForward, onTap: onForward!),
            if (onCopy != null) _ActionTile(icon: Icons.copy, label: StrRes.menuCopy, onTap: onCopy!),
            if (onDelete != null)
              _ActionTile(icon: Icons.delete_outline, label: StrRes.delete, onTap: onDelete!, isDestructive: true),
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
