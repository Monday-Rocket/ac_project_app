import 'package:ac_project_app/provider/shared_pref_provider.dart';

void checkTutorial2({
  required void Function() onMoveToTutorialView,
  required void Function() onMoveToNextView,
}) {
  SharedPrefHelper.getValueFromKey<bool>('tutorial2', defaultValue: false).then((value) {
    if (value) {
      SharedPrefHelper.saveKeyValue('tutorial2', false);
      onMoveToTutorialView();
    } else {
      onMoveToNextView();
    }
  });
}
