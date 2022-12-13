import 'dart:io';

import 'package:logger/logger.dart';

class Log {
  static final prettyPrinter = PrettyPrinter(
    printTime: true,
    methodCount: 0,
    colors: Platform.isAndroid,
  );

  static void d(dynamic msg) {
    Logger(printer: prettyPrinter).d(msg);
  }

  static void i(dynamic msg) {
    Logger(printer: prettyPrinter).i(msg);
  }

  static void e(dynamic msg) {
    Logger(printer: prettyPrinter).e(msg);
  }

  static void longPrint(String text) {
    final pattern = RegExp('.{1,600}');
    pattern.allMatches(text).forEach((match) => i(match.group(0)));
  }
}
