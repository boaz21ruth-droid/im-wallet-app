import 'package:get/get.dart';
import 'package:openim_common/openim_common.dart';

class FavoritesLogic extends GetxController {
  final items = <Map<String, dynamic>>[].obs;

  @override
  void onReady() {
    _loadFavorites();
    super.onReady();
  }

  void _loadFavorites() {
    final list = DataSp.getFavoriteMessages();
    items.assignAll(list.reversed.toList());
  }

  void removeItem(String clientMsgID) {
    DataSp.removeFavoriteMessage(clientMsgID);
    items.removeWhere((m) => m['clientMsgID'] == clientMsgID);
  }
}
