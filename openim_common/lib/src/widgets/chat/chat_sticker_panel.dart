import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:openim_common/openim_common.dart';

class ChatStickerPanel extends StatelessWidget {
  const ChatStickerPanel({Key? key, required this.onSend}) : super(key: key);
  final void Function(String url, String emoji) onSend;

  static const _stickers = [
    ('😀', '1f600'), ('😂', '1f602'), ('😍', '1f60d'), ('🥹', '1f979'),
    ('😎', '1f60e'), ('😭', '1f62d'), ('😡', '1f621'), ('🥺', '1f97a'),
    ('😘', '1f618'), ('🤩', '1f929'), ('🥳', '1f973'), ('😴', '1f634'),
    ('🤔', '1f914'), ('💪', '1f4aa'), ('👏', '1f44f'), ('🙏', '1f64f'),
    ('❤️', '2764'), ('🔥', '1f525'), ('💯', '1f4af'), ('✨', '2728'),
    ('🎉', '1f389'), ('🍕', '1f355'), ('🎮', '1f3ae'), ('👋', '1f44b'),
  ];

  static String _url(String codepoint) =>
      'https://cdn.jsdelivr.net/gh/twitter/twemoji@14.0.2/assets/72x72/$codepoint.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      child: Column(
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
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(12.w),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _stickers.length,
              itemBuilder: (_, i) {
                final (emoji, codepoint) = _stickers[i];
                final url = _url(codepoint);
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    onSend(url, emoji);
                  },
                  child: ImageUtil.networkImage(url: url, width: 48.w, height: 48.h, fit: BoxFit.contain),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
