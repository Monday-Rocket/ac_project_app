import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/provider/local/database_helper.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late LocalLinkRepository linkRepository;
  late LocalFolderRepository folderRepository;
  late DatabaseHelper databaseHelper;
  late int testFolderId;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseHelper = DatabaseHelper.createForTest();
    linkRepository = LocalLinkRepository(databaseHelper: databaseHelper);
    folderRepository = LocalFolderRepository(databaseHelper: databaseHelper);

    // 테스트용 폴더 생성
    testFolderId = await folderRepository.createFolder(
      LocalFolder(
        name: '테스트 폴더',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      ),
    );
  });

  tearDown(() async {
    await databaseHelper.deleteDatabase();
    await databaseHelper.close();
  });

  group('LocalLinkRepository', () {
    test('createLink creates a new link', () async {
      final link = LocalLink(
        folderId: testFolderId,
        url: 'https://example.com',
        title: '예시 링크',
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      final id = await linkRepository.createLink(link);

      expect(id, greaterThan(0));

      final retrieved = await linkRepository.getLinkById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.url, 'https://example.com');
      expect(retrieved.title, '예시 링크');
    });

    test('getAllLinks returns all links in order', () async {
      await linkRepository.createLink(
        LocalLink(
          folderId: testFolderId,
          url: 'https://example1.com',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
      await linkRepository.createLink(
        LocalLink(
          folderId: testFolderId,
          url: 'https://example2.com',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      final links = await linkRepository.getAllLinks();

      expect(links.length, 2);
    });

    test('getLinksByFolderId returns folder specific links', () async {
      final folder2Id = await folderRepository.createFolder(
        LocalFolder(
          name: '폴더 2',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      await linkRepository.createLink(
        LocalLink(
          folderId: testFolderId,
          url: 'https://folder1.com',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
      await linkRepository.createLink(
        LocalLink(
          folderId: folder2Id,
          url: 'https://folder2.com',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      final folder1Links = await linkRepository.getLinksByFolderId(testFolderId);
      final folder2Links = await linkRepository.getLinksByFolderId(folder2Id);

      expect(folder1Links.length, 1);
      expect(folder2Links.length, 1);
      expect(folder1Links.first.url, 'https://folder1.com');
      expect(folder2Links.first.url, 'https://folder2.com');
    });

    test('updateLink updates link properties', () async {
      final id = await linkRepository.createLink(
        LocalLink(
          folderId: testFolderId,
          url: 'https://original.com',
          title: '원래 제목',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      final link = await linkRepository.getLinkById(id);
      final updated = link!.copyWith(title: '변경된 제목');

      await linkRepository.updateLink(updated);

      final retrieved = await linkRepository.getLinkById(id);
      expect(retrieved!.title, '변경된 제목');
    });

    test('deleteLink removes link', () async {
      final id = await linkRepository.createLink(
        LocalLink(
          folderId: testFolderId,
          url: 'https://delete.com',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      await linkRepository.deleteLink(id);

      final retrieved = await linkRepository.getLinkById(id);
      expect(retrieved, isNull);
    });

    test('moveLink moves link to another folder', () async {
      final folder2Id = await folderRepository.createFolder(
        LocalFolder(
          name: '이동할 폴더',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      final id = await linkRepository.createLink(
        LocalLink(
          folderId: testFolderId,
          url: 'https://move.com',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      await linkRepository.moveLink(id, folder2Id);

      final link = await linkRepository.getLinkById(id);
      expect(link!.folderId, folder2Id);
    });

    test('moveLinks moves multiple links', () async {
      final folder2Id = await folderRepository.createFolder(
        LocalFolder(
          name: '이동 대상 폴더',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      final id1 = await linkRepository.createLink(
        LocalLink(
          folderId: testFolderId,
          url: 'https://move1.com',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
      final id2 = await linkRepository.createLink(
        LocalLink(
          folderId: testFolderId,
          url: 'https://move2.com',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      await linkRepository.moveLinks([id1, id2], folder2Id);

      final link1 = await linkRepository.getLinkById(id1);
      final link2 = await linkRepository.getLinkById(id2);
      expect(link1!.folderId, folder2Id);
      expect(link2!.folderId, folder2Id);
    });

    test('searchLinks finds links by title, url, or description', () async {
      await linkRepository.createLink(
        LocalLink(
          folderId: testFolderId,
          url: 'https://flutter.dev',
          title: 'Flutter 공식 사이트',
          describe: 'Flutter 개발 문서',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
      await linkRepository.createLink(
        LocalLink(
          folderId: testFolderId,
          url: 'https://dart.dev',
          title: 'Dart 언어',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      final byTitle = await linkRepository.searchLinks('Flutter');
      final byUrl = await linkRepository.searchLinks('dart.dev');
      final byDesc = await linkRepository.searchLinks('문서');

      expect(byTitle.length, 1);
      expect(byUrl.length, 1);
      expect(byDesc.length, 1);
    });

    test('isUrlExists checks for duplicate URLs', () async {
      await linkRepository.createLink(
        LocalLink(
          folderId: testFolderId,
          url: 'https://unique.com',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      final exists = await linkRepository.isUrlExists('https://unique.com');
      final notExists = await linkRepository.isUrlExists('https://other.com');

      expect(exists, true);
      expect(notExists, false);
    });

    test('getLinkByUrl retrieves link by URL', () async {
      await linkRepository.createLink(
        LocalLink(
          folderId: testFolderId,
          url: 'https://findme.com',
          title: '찾을 링크',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      final link = await linkRepository.getLinkByUrl('https://findme.com');

      expect(link, isNotNull);
      expect(link!.title, '찾을 링크');
    });

    test('getLinkCountByFolderId returns correct count', () async {
      await linkRepository.createLink(
        LocalLink(
          folderId: testFolderId,
          url: 'https://count1.com',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );
      await linkRepository.createLink(
        LocalLink(
          folderId: testFolderId,
          url: 'https://count2.com',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      final count = await linkRepository.getLinkCountByFolderId(testFolderId);

      expect(count, 2);
    });

    test('getTotalLinkCount returns total count', () async {
      await linkRepository.createLink(
        LocalLink(
          folderId: testFolderId,
          url: 'https://total1.com',
          createdAt: DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        ),
      );

      final count = await linkRepository.getTotalLinkCount();

      expect(count, greaterThan(0));
    });

    test('pagination works with limit and offset', () async {
      for (var i = 0; i < 10; i++) {
        await linkRepository.createLink(
          LocalLink(
            folderId: testFolderId,
            url: 'https://page$i.com',
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
          ),
        );
      }

      final page1 = await linkRepository.getAllLinks(limit: 3, offset: 0);
      final page2 = await linkRepository.getAllLinks(limit: 3, offset: 3);

      expect(page1.length, 3);
      expect(page2.length, 3);
      expect(page1.first.url, isNot(page2.first.url));
    });
  });
}
