import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/stringfy.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {

  test(
    'list to string test',
    () {
      final msg = ['123', '456'];
      Log.i(msg);
      Log.i(msg.toString());
      Log.i(stringifyMessage(msg));
    },
  );

}
