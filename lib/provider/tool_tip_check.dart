import 'package:shared_preferences/shared_preferences.dart';

class ToolTipCheck {
  static Future<bool> hasNotBottomUploaded() async {
    final prefs = await SharedPreferences.getInstance();
    final hasChecked = prefs.getBool('BottomUploadToolTip') ?? false;
    if (!hasChecked) {
      await prefs.setBool('BottomUploadToolTip', true);
      return true;
    }
    return false;
  }

  static void setBottomUploaded() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('BottomUploadToolTip', true);
    });
  }

  static Future<bool> hasNotUploadLinkInMyFolder() async {
    final prefs = await SharedPreferences.getInstance();
    final hasChecked = prefs.getBool('UploadLinkInMyFolder') ?? false;
    if (!hasChecked) {
      return prefs.setBool('UploadLinkInMyFolder', true);
    }
    return false;
  }

  static void setMyLinkUploaded() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('UploadLinkInMyFolder', true);
    });
  }
}
