import 'package:logger/logger.dart';

class Log {
  static void d(dynamic msg) {
    Logger(
      printer: PrettyPrinter(
        colors: false,
        printTime: true,
        methodCount: 0,
      ),
    ).d(msg);
  }

  static void i(dynamic msg) {
    Logger(
      printer: PrettyPrinter(
        colors: false,
        printTime: true,
        methodCount: 0,
      ),
    ).i(msg);
  }

  static void e(dynamic msg) {
    Logger(
      printer: PrettyPrinter(
        colors: false,
        printTime: true,
        methodCount: 0,
      ),
    ).e(msg);
  }
}
