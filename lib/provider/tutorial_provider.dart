import 'package:shared_preferences/shared_preferences.dart';

void checkTutorial2({
  required void Function() onMoveToTutorialView,
  required void Function() onMoveToNextView,
}) {
  SharedPreferences.getInstance().then((SharedPreferences prefs) {
    final tutorial = prefs.getBool('tutorial2') ?? false;
    if (tutorial) {
      prefs.setBool('tutorial2', false);
      onMoveToTutorialView();
    } else {
      onMoveToNextView();
    }
  });
}
