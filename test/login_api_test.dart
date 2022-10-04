import 'package:ac_project_app/models/user.dart';
import 'package:ac_project_app/provider/api/login/user_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final userApi = UserApi();
  test('create user test', () async {
    final result = await userApi.postUsers();
    result.when(
      success: (data) {
        expect(data, User('1'));
      },
      error: fail,
    );
  });
}
