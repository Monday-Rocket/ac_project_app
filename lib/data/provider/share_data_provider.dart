import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/services.dart';

class ShareDataProvider {
  static const _platform = MethodChannel('share_data_provider');

  static Future<List<String>> getShareDataList() async {
    try {
      final data =
          await _platform.invokeMethod('getShareData') as List<Object?>;

      final result = <String>[];

      for (final item in data) {
        result.add(item.toString());
      }

      return result;
    } on PlatformException catch (e) {
      Log.e(e.message);
      rethrow;
    }
  }
}
