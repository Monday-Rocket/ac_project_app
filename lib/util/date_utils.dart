String getMonthDayYear(String time) {
  final dateTime = time.split('T');
  if (dateTime.length == 2) {
    final yearMonthDay = dateTime[0].split('-');
    if (yearMonthDay.length == 3) {
      final year = int.parse(yearMonthDay[0]);
      final m = int.parse(yearMonthDay[1]);
      final day = int.parse(yearMonthDay[2]);

      var month = '';

      switch (m) {
        case 1:
          month = 'Jan';
          break;
        case 2:
          month = 'Feb';
          break;
        case 3:
          month = 'Mar';
          break;
        case 4:
          month = 'Apr';
          break;
        case 5:
          month = 'May';
          break;
        case 6:
          month = 'Jun';
          break;
        case 7:
          month = 'Jul';
          break;
        case 8:
          month = 'Aug';
          break;
        case 9:
          month = 'Sep';
          break;
        case 10:
          month = 'Oct';
          break;
        case 11:
          month = 'Nov';
          break;
        case 12:
          month = 'Dec';
          break;
        default:
          break;
      }

      return '$month $day, $year';
    }
  }

  return '';
}
