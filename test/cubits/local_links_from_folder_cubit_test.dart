import 'package:ac_project_app/cubits/links/link_list_state.dart';
import 'package:ac_project_app/cubits/links/local_links_from_folder_cubit.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/provider/local/database_helper.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseHelper databaseHelper;
  late LocalFolderRepository folderRepo;
  late LocalLinkRepository linkRepo;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseHelper = DatabaseHelper.createForTest();
    folderRepo = LocalFolderRepository(databaseHelper: databaseHelper);
    linkRepo = LocalLinkRepository(databaseHelper: databaseHelper);

    if (getIt.isRegistered<LocalFolderRepository>()) {
      getIt.unregister<LocalFolderRepository>();
    }
    if (getIt.isRegistered<LocalLinkRepository>()) {
      getIt.unregister<LocalLinkRepository>();
    }
    getIt.registerSingleton<LocalFolderRepository>(folderRepo);
    getIt.registerSingleton<LocalLinkRepository>(linkRepo);
  });

  tearDown(() async {
    await databaseHelper.deleteDatabase();
    await databaseHelper.close();
    if (getIt.isRegistered<LocalFolderRepository>()) {
      getIt.unregister<LocalFolderRepository>();
    }
    if (getIt.isRegistered<LocalLinkRepository>()) {
      getIt.unregister<LocalLinkRepository>();
    }
  });

  Future<int> makeFolder(String name, {int? parentId}) async {
    final now = DateTime.now().toIso8601String();
    return folderRepo.createFolder(
      LocalFolder(
        name: name,
        parentId: parentId,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> makeLink(int folderId, String url) async {
    final now = DateTime.now().toIso8601String();
    await linkRepo.createLink(
      LocalLink(
        folderId: folderId,
        url: url,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> pumpUntilLoaded(LocalLinksFromFolderCubit cubit) async {
    for (var i = 0; i < 50; i++) {
      if (cubit.state is LinkListLoadedState ||
          cubit.state is LinkListErrorState) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  group('LocalLinksFromFolderCubit — drill-down 확장', () {
    test('일반 폴더 load 시 breadcrumb 과 childFolders 가 state 에 실린다',
        () async {
      final workId = await makeFolder('일');
      final devId = await makeFolder('개발', parentId: workId);
      await makeFolder('React', parentId: devId);
      await makeFolder('Vue', parentId: devId);
      await makeLink(devId, 'https://a');
      await makeLink(devId, 'https://b');

      final folder = Folder(id: devId, name: '개발', isClassified: true);
      final cubit = LocalLinksFromFolderCubit(folder, 0);
      await pumpUntilLoaded(cubit);

      expect(cubit.state, isA<LinkListLoadedState>());
      final state = cubit.state as LinkListLoadedState;
      expect(state.links.length, 2);
      expect(state.breadcrumb.map((f) => f.name).toList(), ['일', '개발']);
      expect(state.childFolders.map((f) => f.name).toSet(), {'React', 'Vue'});

      await cubit.close();
    });

    test('최상위 폴더의 breadcrumb 는 자기 자신만 포함', () async {
      final rootId = await makeFolder('루트');
      await makeLink(rootId, 'https://a');

      final folder = Folder(id: rootId, name: '루트', isClassified: true);
      final cubit = LocalLinksFromFolderCubit(folder, 0);
      await pumpUntilLoaded(cubit);

      final state = cubit.state as LinkListLoadedState;
      expect(state.breadcrumb.map((f) => f.name).toList(), ['루트']);
      expect(state.childFolders, isEmpty);

      await cubit.close();
    });

    test('미분류 폴더는 breadcrumb/childFolders 가 빈 리스트', () async {
      final unclassified = await folderRepo.getUnclassifiedFolder();
      expect(unclassified, isNotNull);
      await makeLink(unclassified!.id!, 'https://u1');

      final folder = Folder(
        id: unclassified.id,
        name: unclassified.name,
        isClassified: false,
      );
      final cubit = LocalLinksFromFolderCubit(folder, 0);
      await pumpUntilLoaded(cubit);

      final state = cubit.state as LinkListLoadedState;
      expect(state.links, hasLength(1));
      expect(state.breadcrumb, isEmpty);
      expect(state.childFolders, isEmpty);

      await cubit.close();
    });

    test('하위 폴더가 없으면 childFolders 빈 리스트', () async {
      final id = await makeFolder('혼자');
      await makeLink(id, 'https://x');

      final folder = Folder(id: id, name: '혼자', isClassified: true);
      final cubit = LocalLinksFromFolderCubit(folder, 0);
      await pumpUntilLoaded(cubit);

      final state = cubit.state as LinkListLoadedState;
      expect(state.childFolders, isEmpty);
      expect(state.breadcrumb.map((f) => f.name).toList(), ['혼자']);

      await cubit.close();
    });

    test('하위 폴더는 재귀 링크 카운트를 포함', () async {
      final rootId = await makeFolder('부모');
      final childId = await makeFolder('자식', parentId: rootId);
      final grandId = await makeFolder('손자', parentId: childId);
      await makeLink(childId, 'https://c1');
      await makeLink(grandId, 'https://g1');
      await makeLink(grandId, 'https://g2');

      final folder = Folder(id: rootId, name: '부모', isClassified: true);
      final cubit = LocalLinksFromFolderCubit(folder, 0);
      await pumpUntilLoaded(cubit);

      final state = cubit.state as LinkListLoadedState;
      expect(state.childFolders, hasLength(1));
      final child = state.childFolders.first;
      expect(child.name, '자식');
      // 자식 아래 링크 1개 + 손자 링크 2개 = 3개
      expect(child.linksTotal, 3);

      await cubit.close();
    });
  });
}
