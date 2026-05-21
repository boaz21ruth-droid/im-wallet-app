import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';

class ChatToolBox extends StatelessWidget {
  const ChatToolBox({
    super.key,
    this.onTapAlbum,
    this.onTapCall,
    this.onTapGif,
    this.onTapSticker,
  });
  final Function()? onTapAlbum;
  final Function()? onTapCall;
  final Function()? onTapGif;
  final Function()? onTapSticker;

  @override
  Widget build(BuildContext context) {
    final items = [
      ToolboxItemInfo(
        text: StrRes.toolboxAlbum,
        icon: ImageRes.toolboxAlbum,
        onTap: () => Permissions.photos(onTapAlbum),
      ),
      if (onTapCall != null)
        ToolboxItemInfo(
          text: StrRes.toolboxCall,
          icon: ImageRes.toolboxCall,
          onTap: () => Permissions.cameraAndMicrophone(onTapCall),
        ),
      if (onTapGif != null)
        ToolboxItemInfo(
          text: 'GIF',
          icon: ImageRes.toolboxAlbum,
          onTap: onTapGif,
          isGif: true,
        ),
      if (onTapSticker != null)
        ToolboxItemInfo(
          text: StrRes.toolboxSticker,
          icon: ImageRes.toolboxAlbum,
          onTap: onTapSticker,
          isSticker: true,
        ),
    ];

    return Container(
      color: Styles.c_F0F2F6,
      height: 224.h,
      child: GridView.builder(
        itemCount: items.length,
        padding: EdgeInsets.only(
          left: 16.w,
          right: 16.w,
          top: 6.h,
          bottom: 6.h,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 78.w / 105.h,
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 2.h,
        ),
        itemBuilder: (_, index) {
          final item = items.elementAt(index);
          if (item.isGif) {
            return _buildTextItemView(text: 'GIF', label: 'GIF', onTap: item.onTap);
          }
          if (item.isSticker) {
            return _buildTextItemView(text: '😊', label: item.text, onTap: item.onTap);
          }
          return _buildItemView(
            icon: item.icon,
            text: item.text,
            onTap: item.onTap,
          );
        },
      ),
    );
  }

  Widget _buildItemView({
    required String text,
    required String icon,
    Function()? onTap,
  }) =>
      Column(
        children: [
          icon.toImage
            ..width = 58.w
            ..height = 58.h
            ..onTap = onTap,
          10.verticalSpace,
          text.toText..style = Styles.ts_0C1C33_12sp,
        ],
      );

  Widget _buildTextItemView({
    required String text,
    required String label,
    Function()? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 58.w,
              height: 58.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              alignment: Alignment.center,
              child: Text(text, style: TextStyle(fontSize: text.length == 1 ? 28.sp : 18.sp, fontWeight: FontWeight.bold)),
            ),
            10.verticalSpace,
            label.toText..style = Styles.ts_0C1C33_12sp,
          ],
        ),
      );
}

class ToolboxItemInfo {
  String text;
  String icon;
  Function()? onTap;
  bool isGif;
  bool isSticker;

  ToolboxItemInfo({
    required this.text,
    required this.icon,
    this.onTap,
    this.isGif = false,
    this.isSticker = false,
  });
}
