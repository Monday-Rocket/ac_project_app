import 'package:intl/intl.dart';

String addCommasFrom(int? number) {
  if (number == null) return '';
  if (number < 0) return '0';
  return NumberFormat('###,###').format(number);
}
