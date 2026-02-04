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
}
