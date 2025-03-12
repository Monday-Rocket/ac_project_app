import 'package:ac_project_app/provider/shared_pref_provider.dart';

class ToolTipCheck {
  static Future<bool> hasNotBottomUploaded() async {
    final hasChecked = await SharedPrefHelper.getValueFromKey<bool>('BottomUploadToolTip', defaultValue: false);

    if (!hasChecked) {
      await SharedPrefHelper.saveKeyValue<bool>('BottomUploadToolTip', true);
      return true;
    }
    return false;
  }

  static void setBottomUploaded() {
    SharedPrefHelper.saveKeyValue('BottomUploadToolTip', true);
  }

  static Future<bool> hasNotUploadLinkInMyFolder() async {
    final hasChecked = await SharedPrefHelper.getValueFromKey<bool>('UploadLinkInMyFolder', defaultValue: false);

    if (!hasChecked) {
      return SharedPrefHelper.saveKeyValue('UploadLinkInMyFolder', true);
    }
    return false;
  }

  static void setMyLinkUploaded() {
    SharedPrefHelper.saveKeyValue('UploadLinkInMyFolder', true);
  }
}
