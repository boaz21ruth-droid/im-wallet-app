import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:openim_common/openim_common.dart';

class GifPicker extends StatefulWidget {
  const GifPicker({Key? key, required this.onSend}) : super(key: key);
  final void Function(String url, int width, int height) onSend;

  @override
  State<GifPicker> createState() => _GifPickerState();
}

class _GifPickerState extends State<GifPicker> {
  static const _tenorKey = 'LIVDSRZULELA';
  final _searchCtrl = TextEditingController();
  List<_GifItem> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _search('hello');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final uri = Uri.parse(
        'https://g.tenor.com/v1/search?q=${Uri.encodeComponent(q)}&key=$_tenorKey&limit=20&media_filter=minimal',
      );
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final body = json.decode(resp.body) as Map<String, dynamic>;
        final results = (body['results'] as List? ?? []);
        setState(() {
          _items = results.map((r) {
            final gif = (r['media'] as List?)?.first?['gif'] as Map? ?? {};
            final dims = (gif['dims'] as List?) ?? [200, 200];
            return _GifItem(
              url: gif['url'] as String? ?? '',
              width: (dims[0] as num).toInt(),
              height: (dims[1] as num).toInt(),
            );
          }).where((i) => i.url.isNotEmpty).toList();
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400.h,
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search GIF...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                contentPadding: EdgeInsets.symmetric(vertical: 8.h),
              ),
              onSubmitted: _search,
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: EdgeInsets.all(8.w),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                    ),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onSend(item.url, item.width, item.height);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6.r),
                          child: ImageUtil.networkImage(url: item.url, fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _GifItem {
  final String url;
  final int width;
  final int height;
  _GifItem({required this.url, required this.width, required this.height});
}
