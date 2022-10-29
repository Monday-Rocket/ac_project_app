import 'package:intl/intl.dart';

String addCommasFrom(int number) {
  return NumberFormat('###,###').format(number);
}
