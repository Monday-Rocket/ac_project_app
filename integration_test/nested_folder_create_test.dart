import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/main.dart' as app;
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/ui/widget_tap_helper.dart';

/// 중첩 폴더 생성 E2E 골든 플로우.
///
/// 시나리오:
///   1) 로그인 → 내 폴더 탭
///   2) 루트에서 `E2E_개발_{suffix}` 생성 → 자동 진입 확인
///   3) 해당 폴더의 '하위 폴더 (N)' 헤더의 + 버튼 → `E2E_React_{suffix}` 생성
///   4) 부모(개발) 화면에 '하위 폴더 (1)' + 자식 'React' 노출 확인
///   5) 자식 탭 → 브레드크럼 '개발 > React' 확인
///
/// suffix로 각 실행을 격리해 이전 실행의 잔여 폴더로 인한 '형제 이름 중복'을 피한다.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('중첩 폴더 생성 골든 플로우 — 루트 "개발" → 자식 "React"',
      (tester) async {
    final suffix = DateTime.now().millisecondsSinceEpoch.toString();
    final parentName = 'E2E_개발_$suffix';
    final childName = 'E2E_React_$suffix';

    // 1) 앱 실행
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 2) 튜토리얼 시작 버튼 (처음 실행 시에만 존재)
    final startButton = find.byKey(const Key('StartAppButton'));
    if (startButton.evaluate().isNotEmpty) {
      await tester.tap(startButton);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    // 3) 테스트 로그인
    const testLoginButtonKey = Key('SignedUserLoginButton');
    if (find.byKey(testLoginButtonKey).evaluate().isNotEmpty) {
      InkWellButton(testLoginButtonKey).onTap!.call();
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    // 4) 홈 → 내 폴더 탭(index 0)
    await tester.pumpAndSettle();
    final navigation = find.byKey(const Key('MainBottomNavigationBar'));
    expect(navigation, findsOneWidget);
    final navigationBar =
        navigation.evaluate().first.widget as BottomNavigationBar;
    navigationBar.onTap!.call(0);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 5) 루트 "+ 새 폴더" 버튼
    final rootAddButton =
        find.byKey(const Key('my_folder_page_create_root_folder'));
    expect(rootAddButton, findsOneWidget);
    await tester.tap(rootAddButton);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // 6) 시트에 이름 입력 → 생성
    final rootNameField = find.byKey(const Key('create_folder_name_field'));
    expect(rootNameField, findsOneWidget,
        reason: '루트 생성 시트의 이름 입력 필드가 떠야 한다.');
    await tester.enterText(rootNameField, parentName);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create_folder_submit')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 7) 생성 직후 자동으로 새 폴더(개발) 상세 화면으로 이동됨.
    //    타이틀 바의 폴더명으로 진입 확인.
    expect(find.text(parentName), findsWidgets,
        reason: '루트 생성 직후 해당 폴더 상세로 자동 이동해야 한다.');

    // 8) "하위 폴더" 섹션 헤더와 빈 상태 문구 확인
    expect(find.text('하위 폴더 (0)'), findsOneWidget,
        reason: '자식이 없으면 "하위 폴더 (0)" 헤더가 노출되어야 한다.');
    expect(find.text('하위 폴더 없음'), findsOneWidget,
        reason: '자식이 없으면 "하위 폴더 없음" 문구가 노출되어야 한다.');

    // 9) 하위 폴더 생성 플로우: "+" 버튼 탭
    final addChildButton =
        find.byKey(const Key('my_link_view_add_child_folder'));
    expect(addChildButton, findsOneWidget);
    await tester.tap(addChildButton);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // 10) 시트에 자식 이름 입력 → 생성
    final childNameField = find.byKey(const Key('create_folder_name_field'));
    expect(childNameField, findsOneWidget,
        reason: '하위 폴더 생성 시트의 이름 입력 필드가 떠야 한다.');
    await tester.enterText(childNameField, childName);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('create_folder_submit')));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 11) 부모(개발)에 머무른 상태에서 "하위 폴더 (1)" + 자식 이름 확인
    expect(find.text('하위 폴더 (1)'), findsOneWidget,
        reason: '자식 생성 후 부모 화면에 "하위 폴더 (1)" 헤더가 노출되어야 한다.');
    expect(find.text(childName), findsWidgets,
        reason: '자식 폴더 이름이 부모 상세의 리스트에 노출되어야 한다.');
    expect(find.text(parentName), findsWidgets,
        reason: '부모(개발) 타이틀이 유지되어야 한다 (여전히 부모 화면).');

    // 12) 자식 폴더 탭 → 상세 진입
    await tester.tap(find.text(childName).last);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // 13) 브레드크럼 "개발 > React" 확인.
    //     breadcrumb은 length >= 2일 때만 렌더되고, 마지막 항목(= 현재 폴더)은
    //     blackBold 스타일. parent와 child 이름 둘 다 화면에 보여야 한다.
    expect(find.text(parentName), findsWidgets,
        reason: '자식 진입 후에도 브레드크럼에 부모 이름이 노출되어야 한다.');
    expect(find.text(childName), findsWidgets,
        reason: '자식 상세 타이틀(+ 브레드크럼 마지막 항목)이 노출되어야 한다.');

    // 14) 정리: 테스트 잔여물 제거 (로컬 DB에서 자식 → 부모 순으로 삭제).
    //     외래키 제약상 부모보다 자식을 먼저 삭제한다.
    final repo = getIt<LocalFolderRepository>();
    final all = await repo.getAllFolders();
    final childMatch = all.where((f) => f.name == childName && f.id != null);
    if (childMatch.isNotEmpty) {
      await repo.deleteFolder(childMatch.first.id!);
    }
    final parentMatch = all.where((f) => f.name == parentName && f.id != null);
    if (parentMatch.isNotEmpty) {
      await repo.deleteFolder(parentMatch.first.id!);
    }
  });
}
