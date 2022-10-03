import 'package:ac_project_app/provider/api/login/login_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';

void main() {

  final logger = Logger(printer: PrettyPrinter());

  test('create user test', () async {
    final result = await LoginApi().postUsers();
    logger.i(result.toJson());
  });
}
