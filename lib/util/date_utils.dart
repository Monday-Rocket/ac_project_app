import 'package:ac_project_app/const/consts.dart';

String getMonthDayYear(String time) {
  final dateTime = time.split('T');
  if (dateTime.length == 2) {
    final yearMonthDay = dateTime[0].split('-');
    if (yearMonthDay.length == 3) {
      final year = int.parse(yearMonthDay[0]);
      final m = int.parse(yearMonthDay[1]);
      final day = int.parse(yearMonthDay[2]);

      var month = '';

      if (1 <= m && m <= 12) {
        month = monthNames[m-1];
      }

      return '$month $day, $year';
    }
  }

  return '';
}
