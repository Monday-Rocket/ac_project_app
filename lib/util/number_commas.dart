import 'package:intl/intl.dart';

String addCommasFrom(int? number) {
  if (number == null) return '';
  return NumberFormat('###,###').format(number);
}
