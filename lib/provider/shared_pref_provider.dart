import 'dart:async';

import 'package:ac_project_app/util/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefHelper {
  static Future<bool> saveKeyValue<T>(String key, T value) async {
    Log.i('save key: $key, value: $value');
    final shared = await SharedPreferences.getInstance();
    if (value is bool) {
      return shared.setBool(key, value);
    } else if (value is int) {
      return shared.setInt(key, value);
    } else if (value is double) {
      return shared.setDouble(key, value);
    } else if (value is String) {
      return shared.setString(key, value);
    } else if (value is List<String>) {
      return shared.setStringList(key, value);
    } else {
      return false;
    }
  }

  static Future<T> getValueFromKey<T>(String key, {dynamic defaultValue, bool? removeKey}) async {
    final shared = await SharedPreferences.getInstance();
    final result = shared.get(key) ?? defaultValue;
    if (removeKey ?? false) {
      await shared.remove(key);
    }
    Log.i('get key: $key, value: $result');
    return result as T;
  }

}
