import 'package:ac_project_app/util/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> saveKeyValue(String key, String value) async {
  Log.i('save key: $key, value: $value');
  final shared = await SharedPreferences.getInstance();
  return shared.setString(key, value);
}

Future<String> getValueFromKey(String key) async {
  final shared = await SharedPreferences.getInstance();
  final result = shared.getString(key) ?? '';
  await shared.remove(key);
  Log.i('get key: $key, value: $result');
  return result;
}
