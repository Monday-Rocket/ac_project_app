import 'dart:async';
import 'dart:io';

import 'package:ac_project_app/util/logger.dart';
import 'package:path_provider/path_provider.dart';

class ShareDataProvider {
  static Future<String> get() async {
    final dir = await getApplicationDocumentsDirectory();
    final basePath = '${dir.path}/share.txt';
    Log.i('basePath: $basePath');
    if (File(basePath).existsSync()) {
      return File(basePath).readAsStringSync();
    }
    return '';
  }
}
