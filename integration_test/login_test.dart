import 'package:ac_project_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/ui/widget_tap_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // email: signed@test.com
  // pw: 123456
  testWidgets('이미 가입된 유저 계정의 로그인/로그아웃 테스트', (WidgetTester tester) async {
    // 1. 앱 실행
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 2. 튜토리얼 시작 버튼 tap
    final startButton = find.byKey(const Key('StartAppButton'));
    if (startButton.evaluate().isNotEmpty) {
      await tester.tap(startButton);
      await tester.pump(const Duration(milliseconds: 500));
    }

    // 3. 테스트 로그인 버튼 tap
    const testLoginButtonKey = Key('SignedUserLoginButton');
    if (find.byKey(testLoginButtonKey).evaluate().isNotEmpty) {
      InkWellButton(testLoginButtonKey).onTap!.call();
      await tester.pump(const Duration(seconds: 1));
    }

    // 4. 홈화면 BottomNavigation에서 마이페이지로 이동
    await tester.pumpAndSettle();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final navigation = find.byKey(const Key('MainBottomNavigationBar'));
    final navigationBar = navigation
        .evaluate()
        .first
        .widget as BottomNavigationBar;
    navigationBar.onTap!.call(3);
    await tester.pump(const Duration(seconds: 1));

    // 5. 로그아웃 버튼 클릭
    const logoutKey = Key('menu:로그아웃');
    InkWellButton(logoutKey).onTap!.call();
    await tester.pump(const Duration(seconds: 1));

    // 6. 로그아웃 다이얼로그에서 로그아웃 수행
    const logoutButtonKey = Key('MyPageDialogRightButtonKey');
    await tester.tap(find.byKey(logoutButtonKey));
    await tester.pump(const Duration(seconds: 1));

    // 7. 다시 로그인 화면으로 돌아왔는지 확인
    final actual = find.byKey(testLoginButtonKey);
    expect(actual, findsWidgets);
  });
}
