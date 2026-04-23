import 'package:ac_project_app/cubits/folders/create_folder_result.dart';
import 'package:ac_project_app/cubits/folders/folders_state.dart';
import 'package:ac_project_app/cubits/folders/local_folders_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/ui/widget/folder/show_create_folder_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([LocalFolderRepository, LocalFoldersCubit])
import 'show_create_folder_sheet_test.mocks.dart';

/// Sets the test view to a phone-sized surface (375×812 @1x) and registers a
/// teardown to restore the original size so subsequent tests are not affected.
void _usePhoneViewport(WidgetTester tester) {
  final originalSize = tester.view.physicalSize;
  final originalDpr = tester.view.devicePixelRatio;
  tester.view.physicalSize = const Size(375, 812);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.physicalSize = originalSize;
    tester.view.devicePixelRatio = originalDpr;
  });
}

Widget _wrapWithButton({
  required LocalFoldersCubit cubit,
  int? Function()? onOpenResult,
  int? initialParentId,
  bool allowParentPick = true,
}) {
  return MaterialApp(
    home: ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => Scaffold(
        body: BlocProvider<LocalFoldersCubit>.value(
          value: cubit,
          child: Builder(
            builder: (ctx) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  final id = await showCreateFolderSheet(
                    ctx,
                    initialParentId: initialParentId,
                    allowParentPick: allowParentPick,
                  );
                  onOpenResult?.call();
                  // swallow id intentionally; tests verify state directly
                  id?.toString();
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late MockLocalFolderRepository mockRepo;
  late MockLocalFoldersCubit mockCubit;

  setUp(() async {
    await getIt.reset();
    mockRepo = MockLocalFolderRepository();
    getIt.registerSingleton<LocalFolderRepository>(mockRepo);

    mockCubit = MockLocalFoldersCubit();
    when(mockCubit.state).thenReturn(FolderInitialState());
    when(mockCubit.stream).thenAnswer((_) => const Stream.empty());
    when(mockCubit.close()).thenAnswer((_) async {});

    // Sealed class — mockito cannot auto-generate a dummy; provide one explicitly.
    provideDummy<CreateFolderResult>(const DuplicateSibling());
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets('열면 제목 + 입력 필드 + 제출 버튼 disabled', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(_wrapWithButton(cubit: mockCubit));
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    expect(find.text('새로운 폴더'), findsOneWidget);
    expect(find.byKey(const Key('create_folder_name_field')), findsOneWidget);
    expect(find.text('폴더 생성하기'), findsOneWidget);

    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('create_folder_submit')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('이름 입력 시 제출 버튼 활성화', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(_wrapWithButton(cubit: mockCubit));
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('create_folder_name_field')),
      'MyFolder',
    );
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('create_folder_submit')),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('allowParentPick=false면 ParentRow 미렌더', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(
      _wrapWithButton(cubit: mockCubit, allowParentPick: false),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('create_folder_parent_row')), findsNothing);
  });

  testWidgets('initialParentId 주면 브레드크럼 경로 표시', (tester) async {
    _usePhoneViewport(tester);
    when(mockRepo.getBreadcrumb(42)).thenAnswer((_) async => const [
          LocalFolder(
            id: 1,
            name: '개발',
            createdAt: '2024-01-01',
            updatedAt: '2024-01-01',
          ),
          LocalFolder(
            id: 42,
            parentId: 1,
            name: 'React',
            createdAt: '2024-01-01',
            updatedAt: '2024-01-01',
          ),
        ]);

    await tester.pumpWidget(
      _wrapWithButton(cubit: mockCubit, initialParentId: 42),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    expect(find.text('개발 > React'), findsOneWidget);
  });

  testWidgets('중복 이름 submit → 에러 메시지 표시 + 시트 유지', (tester) async {
    _usePhoneViewport(tester);
    when(mockCubit.createFolder('Dup', parentId: null))
        .thenAnswer((_) async => const DuplicateSibling());

    await tester.pumpWidget(_wrapWithButton(cubit: mockCubit));
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('create_folder_name_field')),
      'Dup',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_folder_submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('같은 위치에 이미 같은 이름의 폴더가 있어요. 다른 이름을 입력해주세요.'),
      findsOneWidget,
    );
    expect(find.text('새로운 폴더'), findsOneWidget);
  });

  testWidgets('ParentMissing 결과 → 에러 메시지 표시', (tester) async {
    _usePhoneViewport(tester);
    when(mockCubit.createFolder('X', parentId: 5))
        .thenAnswer((_) async => const ParentMissing());
    when(mockRepo.getBreadcrumb(5)).thenAnswer((_) async => const [
          LocalFolder(
            id: 5,
            name: 'GoneParent',
            createdAt: '2024-01-01',
            updatedAt: '2024-01-01',
          ),
        ]);

    await tester.pumpWidget(
      _wrapWithButton(cubit: mockCubit, initialParentId: 5),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('create_folder_name_field')),
      'X',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_folder_submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('상위 폴더를 찾을 수 없어요. 다시 선택해주세요.'),
      findsOneWidget,
    );
  });

  testWidgets('CreateFolderFailed 결과 → 일반 실패 메시지', (tester) async {
    _usePhoneViewport(tester);
    when(mockCubit.createFolder('Bad', parentId: null))
        .thenAnswer((_) async => CreateFolderFailed(Exception('disk')));

    await tester.pumpWidget(_wrapWithButton(cubit: mockCubit));
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('create_folder_name_field')),
      'Bad',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('create_folder_submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('폴더를 만들지 못했어요. 잠시 후 다시 시도해주세요.'),
      findsOneWidget,
    );
  });

  testWidgets('공백만 입력 후 submit → 버튼 disabled', (tester) async {
    _usePhoneViewport(tester);
    await tester.pumpWidget(_wrapWithButton(cubit: mockCubit));
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('create_folder_name_field')),
      '   ',
    );
    await tester.pump();

    // 공백만 있으면 trim 후 empty → 버튼 disabled (trim().isNotEmpty 체크)
    final button = tester.widget<ElevatedButton>(
      find.byKey(const Key('create_folder_submit')),
    );
    expect(button.onPressed, isNull);
  });
}
