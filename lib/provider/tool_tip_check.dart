import 'package:shared_preferences/shared_preferences.dart';

class ToolTipCheck {

  static Future<bool> hasNotBottomUploaded() async {
    final prefs = await SharedPreferences.getInstance();
    final check = prefs.getBool('BottomUploadToolTip') ?? false;
    if (!check) {
      await prefs.setBool('BottomUploadToolTip', true);
      return true;
    }
    return false;
  }

  static Future<bool> setBottomUploaded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('BottomUploadToolTip') ?? false) return true;
    final result = await prefs.setBool('BottomUploadToolTip', true);
    return result;
  }

  static Future<bool> hasNotUploadLinkInMyFolder() async {

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('UploadLinkInMyFolder', false);
    final check = prefs.getBool('UploadLinkInMyFolder') ?? false;
    if (!check) {
      await prefs.setBool('UploadLinkInMyFolder', true);
      return true;
    }
    return false;
  }
}
