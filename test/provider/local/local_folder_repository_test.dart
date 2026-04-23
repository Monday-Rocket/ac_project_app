import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/provider/local/database_helper.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late LocalFolderRepository repository;
  late DatabaseHelper databaseHelper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseHelper = DatabaseHelper.createForTest();
    repository = LocalFolderRepository(databaseHelper: databaseHelper);
  });

  tearDown(() async {
    await databaseHelper.deleteDatabase();
    await databaseHelper.close();
  });

  group('LocalFolderRepository', () {
    test('getAllFolders returns folders with links count', () async {
      final folders = await repository.getAllFolders();

      // 미분류 폴더가 기본으로 생성되어 있음
      expect(folders.isNotEmpty, true);
      expect(folders.first.name, '미분류');
      expect(folders.first.isClassified, false);
    });

    test('createFolder creates a new folder', () async {
      final folder = LocalFolder(
        name: '테스트 폴더',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      final id = await repository.createFolder(folder);

      expect(id, greaterThan(0));

      final retrieved = await repository.getFolderById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, '테스트 폴더');
      expect(retrieved.isClassified, true);
    });

    test('getClassifiedFolders excludes unclassified folder', () async {
      // 분류 폴더 생성
      await repository.createFolder(
        LocalFolder(
          name: '분류 폴더',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      final classifiedFolders = await repository.getClassifiedFolders();
      final allFolders = await repository.getAllFolders();

      expect(classifiedFolders.length, lessThan(allFolders.length));
      expect(
        classifiedFolders.every((f) => f.isClassified),
        true,
      );
    });

    test('getUnclassifiedFolder returns the unclassified folder', () async {
      final unclassified = await repository.getUnclassifiedFolder();

      expect(unclassified, isNotNull);
      expect(unclassified!.isClassified, false);
      expect(unclassified.name, '미분류');
    });

    test('updateFolder updates folder properties', () async {
      final id = await repository.createFolder(
        LocalFolder(
          name: '원래 이름',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      final folder = await repository.getFolderById(id);
      final updated = folder!.copyWith(name: '변경된 이름');

      await repository.updateFolder(updated);

      final retrieved = await repository.getFolderById(id);
      expect(retrieved!.name, '변경된 이름');
    });

    test('deleteFolder removes folder', () async {
      final id = await repository.createFolder(
        LocalFolder(
          name: '삭제할 폴더',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      await repository.deleteFolder(id);

      final retrieved = await repository.getFolderById(id);
      expect(retrieved, isNull);
    });

    test('searchFolders finds folders by name', () async {
      await repository.createFolder(
        LocalFolder(
          name: '검색 테스트 폴더',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
      await repository.createFolder(
        LocalFolder(
          name: '다른 폴더',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      final results = await repository.searchFolders('검색');

      expect(results.length, 1);
      expect(results.first.name, '검색 테스트 폴더');
    });

    test('updateThumbnail updates folder thumbnail', () async {
      final id = await repository.createFolder(
        LocalFolder(
          name: '썸네일 테스트',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      await repository.updateThumbnail(id, 'https://example.com/image.png');

      final folder = await repository.getFolderById(id);
      expect(folder!.thumbnail, 'https://example.com/image.png');
    });

    test('getFolderCount returns correct count', () async {
      final initialCount = await repository.getFolderCount();

      await repository.createFolder(
        LocalFolder(
          name: '새 폴더 1',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
      await repository.createFolder(
        LocalFolder(
          name: '새 폴더 2',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      final newCount = await repository.getFolderCount();
      expect(newCount, initialCount + 2);
    });
  });

  group('LocalFolderRepository — nested folders (v2)', () {
    Future<int> makeFolder(String name, {int? parentId}) async {
      final now = DateTime.now().toIso8601String();
      return repository.createFolder(
        LocalFolder(
          name: name,
          parentId: parentId,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    test('getRootFolders returns only top-level folders (parent_id IS NULL)',
        () async {
      final workId = await makeFolder('일');
      await makeFolder('개발', parentId: workId);
      await makeFolder('개인');

      final roots = await repository.getRootFolders();

      expect(roots.map((f) => f.name).toSet(), {'미분류', '일', '개인'});
      expect(roots.every((f) => f.parentId == null), isTrue);
    });

    test('getChildFolders returns direct children only', () async {
      final workId = await makeFolder('일');
      final devId = await makeFolder('개발', parentId: workId);
      await makeFolder('디자인', parentId: workId);
      await makeFolder('React', parentId: devId);

      final children = await repository.getChildFolders(workId);

      expect(children.map((f) => f.name).toSet(), {'개발', '디자인'});
    });

    test('getAllDescendants returns the folder itself plus all descendants',
        () async {
      final workId = await makeFolder('일');
      final devId = await makeFolder('개발', parentId: workId);
      final reactId = await makeFolder('React', parentId: devId);
      await makeFolder('Hooks', parentId: reactId);
      await makeFolder('개인'); // unrelated

      final descendants = await repository.getAllDescendants(workId);

      expect(
        descendants.map((f) => f.name).toSet(),
        {'일', '개발', 'React', 'Hooks'},
      );
    });

    test('getBreadcrumb returns path from root to target folder', () async {
      final workId = await makeFolder('일');
      final devId = await makeFolder('개발', parentId: workId);
      final reactId = await makeFolder('React', parentId: devId);

      final breadcrumb = await repository.getBreadcrumb(reactId);

      expect(breadcrumb.map((f) => f.name).toList(), ['일', '개발', 'React']);
    });

    test('getBreadcrumb for root folder returns only that folder', () async {
      final id = await makeFolder('일');

      final breadcrumb = await repository.getBreadcrumb(id);

      expect(breadcrumb.map((f) => f.name).toList(), ['일']);
    });

    test('getRecursiveLinkCounts includes descendants link count', () async {
      final db = await databaseHelper.database;
      Future<void> addLink(int folderId, String url) async {
        final now = DateTime.now().toIso8601String();
        await db.insert('link', {
          'folder_id': folderId,
          'url': url,
          'created_at': now,
          'updated_at': now,
        });
      }

      final workId = await makeFolder('일');
      final devId = await makeFolder('개발', parentId: workId);
      final reactId = await makeFolder('React', parentId: devId);
      final personalId = await makeFolder('개인');

      // 일: 1, 개발: 2, React: 3, 개인: 1
      await addLink(workId, 'https://a');
      await addLink(devId, 'https://b1');
      await addLink(devId, 'https://b2');
      await addLink(reactId, 'https://c1');
      await addLink(reactId, 'https://c2');
      await addLink(reactId, 'https://c3');
      await addLink(personalId, 'https://p');

      final counts = await repository.getRecursiveLinkCounts();

      expect(counts[workId], 6); // 자기(1) + 개발(2) + React(3)
      expect(counts[devId], 5); // 자기(2) + React(3)
      expect(counts[reactId], 3); // 자기(3)
      expect(counts[personalId], 1); // 자기(1)
    });

    test('moveFolder updates parent_id', () async {
      final workId = await makeFolder('일');
      final personalId = await makeFolder('개인');
      final devId = await makeFolder('개발', parentId: workId);

      final ok = await repository.moveFolder(devId, personalId);

      expect(ok, isTrue);
      final children = await repository.getChildFolders(personalId);
      expect(children.map((f) => f.name).toList(), ['개발']);
      final oldChildren = await repository.getChildFolders(workId);
      expect(oldChildren, isEmpty);
    });

    test('moveFolder to root sets parent_id to NULL', () async {
      final workId = await makeFolder('일');
      final devId = await makeFolder('개발', parentId: workId);

      final ok = await repository.moveFolder(devId, null);

      expect(ok, isTrue);
      final roots = await repository.getRootFolders();
      expect(roots.any((f) => f.id == devId), isTrue);
    });

    test('moveFolder rejects moving folder into itself', () async {
      final devId = await makeFolder('개발');

      final ok = await repository.moveFolder(devId, devId);

      expect(ok, isFalse);
    });

    test('moveFolder rejects moving folder into its descendant (cycle)',
        () async {
      final workId = await makeFolder('일');
      final devId = await makeFolder('개발', parentId: workId);
      final reactId = await makeFolder('React', parentId: devId);

      final ok = await repository.moveFolder(workId, reactId);

      expect(ok, isFalse);
      final reactChildren = await repository.getChildFolders(reactId);
      expect(reactChildren, isEmpty);
    });

    test('deleting parent cascades to children (FK)', () async {
      final workId = await makeFolder('일');
      final devId = await makeFolder('개발', parentId: workId);
      await makeFolder('React', parentId: devId);

      await repository.deleteFolder(workId);

      final all = await repository.getAllFolders();
      final names = all.map((f) => f.name).toSet();
      expect(names.contains('일'), isFalse);
      expect(names.contains('개발'), isFalse);
      expect(names.contains('React'), isFalse);
    });
  });

  group('LocalFolderRepository — unclassified folder is system-managed', () {
    test('createFolder with is_classified=false throws (only one allowed)',
        () async {
      final now = DateTime.now().toIso8601String();
      expect(
        () => repository.createFolder(
          LocalFolder(
            name: '또 다른 미분류',
            isClassified: false,
            createdAt: now,
            updatedAt: now,
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('createFolder with parent=unclassified is rejected', () async {
      final unclassified = await repository.getUnclassifiedFolder();
      final now = DateTime.now().toIso8601String();
      expect(
        () => repository.createFolder(
          LocalFolder(
            name: '하위',
            parentId: unclassified!.id,
            createdAt: now,
            updatedAt: now,
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('deleteFolder on unclassified is rejected', () async {
      final unclassified = await repository.getUnclassifiedFolder();
      expect(
        () => repository.deleteFolder(unclassified!.id!),
        throwsA(isA<StateError>()),
      );
    });

    test('moveFolder on unclassified is rejected', () async {
      final unclassified = await repository.getUnclassifiedFolder();
      final now = DateTime.now().toIso8601String();
      final otherId = await repository.createFolder(
        LocalFolder(name: '다른 폴더', createdAt: now, updatedAt: now),
      );

      final ok = await repository.moveFolder(unclassified!.id!, otherId);

      expect(ok, isFalse);
      // still at root
      final roots = await repository.getRootFolders();
      expect(roots.any((f) => f.id == unclassified.id), isTrue);
    });

    test('updateFolder rename on unclassified is rejected', () async {
      final unclassified = await repository.getUnclassifiedFolder();
      expect(
        () => repository.updateFolder(unclassified!.copyWith(name: '변경')),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('isSiblingNameTaken', () {
    test('루트 범위에 동명 폴더 있으면 true', () async {
      await repository.createFolder(LocalFolder(
        name: 'React',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));

      final taken = await repository.isSiblingNameTaken(null, 'React');
      expect(taken, isTrue);
    });

    test('루트 범위에 없으면 false', () async {
      final taken = await repository.isSiblingNameTaken(null, 'Nothing');
      expect(taken, isFalse);
    });

    test('자식 범위에서 동명 형제 있으면 true', () async {
      final parentId = await repository.createFolder(LocalFolder(
        name: 'Parent',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));
      await repository.createFolder(LocalFolder(
        name: 'Child',
        parentId: parentId,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));

      final taken = await repository.isSiblingNameTaken(parentId, 'Child');
      expect(taken, isTrue);
    });

    test('다른 부모 아래 같은 이름은 false (형제 아님)', () async {
      final parentA = await repository.createFolder(LocalFolder(
        name: 'A',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));
      final parentB = await repository.createFolder(LocalFolder(
        name: 'B',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));
      await repository.createFolder(LocalFolder(
        name: 'Shared',
        parentId: parentA,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));

      final takenUnderB = await repository.isSiblingNameTaken(parentB, 'Shared');
      expect(takenUnderB, isFalse);

      final takenUnderA = await repository.isSiblingNameTaken(parentA, 'Shared');
      expect(takenUnderA, isTrue);
    });

    test('루트 이름과 중첩 이름은 서로 독립적', () async {
      final parentId = await repository.createFolder(LocalFolder(
        name: 'Topic',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));

      // 루트에 Topic이 있지만, parentId 범위에는 Topic이 없으므로 false.
      final takenUnderParent =
          await repository.isSiblingNameTaken(parentId, 'Topic');
      expect(takenUnderParent, isFalse);
    });

    test('공백 포함 이름은 trim되지 않고 그대로 비교됨 (trim은 호출부 책임)', () async {
      await repository.createFolder(LocalFolder(
        name: 'Spaced',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));

      final takenExact = await repository.isSiblingNameTaken(null, 'Spaced');
      final takenWithSpace = await repository.isSiblingNameTaken(null, 'Spaced ');
      expect(takenExact, isTrue);
      expect(takenWithSpace, isFalse);
    });
  });

  group('createFolder with parent', () {
    test('자식 생성 성공 시 parent_id 저장됨', () async {
      final parentId = await repository.createFolder(LocalFolder(
        name: 'Parent',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));
      final childId = await repository.createFolder(LocalFolder(
        name: 'Child',
        parentId: parentId,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));

      final child = await repository.getFolderById(childId);
      expect(child, isNotNull);
      expect(child!.parentId, parentId);
    });

    test('존재하지 않는 부모 id 지정 시 StateError', () async {
      expect(
        () => repository.createFolder(LocalFolder(
          name: 'Orphan',
          parentId: 99999,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        )),
        throwsA(isA<StateError>()),
      );
    });

    test('미분류 폴더를 부모로 지정 시 StateError (기존 동작 유지)', () async {
      final unclassified = await repository.getUnclassifiedFolder();
      expect(
        () => repository.createFolder(LocalFolder(
          name: 'Forbidden',
          parentId: unclassified!.id,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        )),
        throwsA(isA<StateError>()),
      );
    });

    test('동일 부모 아래 동일 이름 거부 (Repository 방어선)', () async {
      final parentId = await repository.createFolder(LocalFolder(
        name: 'Parent',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));
      await repository.createFolder(LocalFolder(
        name: 'Dup',
        parentId: parentId,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ));

      expect(
        () => repository.createFolder(LocalFolder(
          name: 'Dup',
          parentId: parentId,
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        )),
        throwsA(isA<StateError>()),
      );
    });
  });
}
