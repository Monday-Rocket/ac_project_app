import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/provider/local/database_helper.dart';
import 'package:ac_project_app/provider/local/local_bulk_repository.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late LocalBulkRepository bulkRepository;
  late LocalFolderRepository folderRepository;
  late LocalLinkRepository linkRepository;
  late DatabaseHelper databaseHelper;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    databaseHelper = DatabaseHelper.createForTest();
    bulkRepository = LocalBulkRepository(databaseHelper: databaseHelper);
    folderRepository = LocalFolderRepository(databaseHelper: databaseHelper);
    linkRepository = LocalLinkRepository(databaseHelper: databaseHelper);
  });

  tearDown(() async {
    await databaseHelper.deleteDatabase();
    await databaseHelper.close();
  });

  group('LocalBulkRepository', () {
    group('bulkInsertFromNative', () {
      test('inserts folders and links from native share panel', () async {
        final folders = [
          {'id': '1', 'name': '개발'},
          {'id': '2', 'name': '디자인'},
        ];
        final links = [
          {
            'url': 'https://flutter.dev',
            'title': 'Flutter',
            'folder_id': '1',
          },
          {
            'url': 'https://figma.com',
            'title': 'Figma',
            'folder_id': '2',
          },
        ];

        final result = await bulkRepository.bulkInsertFromNative(
          links: links,
          folders: folders,
        );

        expect(result.insertedFolders, 2);
        expect(result.insertedLinks, 2);

        final allFolders = await folderRepository.getAllFolders();
        final allLinks = await linkRepository.getAllLinks();

        // 미분류 + 2개 = 3개 폴더
        expect(allFolders.length, 3);
        expect(allLinks.length, 2);
      });

      test('handles duplicate folders by using existing', () async {
        final folders = [
          {'name': '개발'},
        ];
        final links = <Map<String, dynamic>>[];

        // 첫 번째 삽입
        await bulkRepository.bulkInsertFromNative(
          links: links,
          folders: folders,
        );

        // 같은 폴더 다시 삽입 시도
        final result = await bulkRepository.bulkInsertFromNative(
          links: links,
          folders: folders,
        );

        expect(result.insertedFolders, 0); // 중복이므로 0

        final allFolders = await folderRepository.getClassifiedFolders();
        expect(allFolders.length, 1);
      });

      test('handles duplicate links by skipping', () async {
        final folders = <Map<String, dynamic>>[];
        final links = [
          {'url': 'https://duplicate.com', 'title': 'Link 1'},
        ];

        await bulkRepository.bulkInsertFromNative(links: links, folders: folders);

        // 같은 URL 다시 삽입 시도
        final result = await bulkRepository.bulkInsertFromNative(
          links: links,
          folders: folders,
        );

        expect(result.insertedLinks, 0); // 중복이므로 0

        final allLinks = await linkRepository.getAllLinks();
        expect(allLinks.length, 1);
      });

      test('links without folder go to unclassified', () async {
        final links = [
          {'url': 'https://nofolder.com', 'title': 'No Folder'},
        ];

        await bulkRepository.bulkInsertFromNative(
          links: links,
          folders: [],
        );

        final unclassified = await folderRepository.getUnclassifiedFolder();
        final unclassifiedLinks = await linkRepository.getLinksByFolderId(
          unclassified!.id!,
        );

        expect(unclassifiedLinks.length, 1);
        expect(unclassifiedLinks.first.url, 'https://nofolder.com');
      });
    });

    group('migrateFromServer', () {
      test('migrates server folders and links', () async {
        final serverFolders = [
          {
            'id': 100,
            'name': '서버 폴더 1',
            'visible': true,
            'created_at': '2024-01-01T00:00:00Z',
          },
          {
            'id': 101,
            'name': '서버 폴더 2',
            'visible': true,
          },
        ];
        final serverLinks = [
          {
            'url': 'https://server1.com',
            'title': '서버 링크 1',
            'folder_id': 100,
            'created_at': '2024-01-01T00:00:00Z',
          },
          {
            'url': 'https://server2.com',
            'title': '서버 링크 2',
            'folder_id': 101,
          },
        ];

        final result = await bulkRepository.migrateFromServer(
          serverFolders: serverFolders,
          serverLinks: serverLinks,
        );

        expect(result.insertedFolders, 2);
        expect(result.insertedLinks, 2);

        final folders = await folderRepository.getClassifiedFolders();
        final links = await linkRepository.getAllLinks();

        expect(folders.length, 2);
        expect(links.length, 2);
      });

      test('invisible server folders map to unclassified', () async {
        final serverFolders = [
          {
            'id': 100,
            'name': '미분류',
            'visible': false,
          },
        ];
        final serverLinks = [
          {
            'url': 'https://unclassified.com',
            'folder_id': 100,
          },
        ];

        await bulkRepository.migrateFromServer(
          serverFolders: serverFolders,
          serverLinks: serverLinks,
        );

        final unclassified = await folderRepository.getUnclassifiedFolder();
        final unclassifiedLinks = await linkRepository.getLinksByFolderId(
          unclassified!.id!,
        );

        expect(unclassifiedLinks.length, 1);
      });

      test('handles empty url links', () async {
        final serverLinks = [
          {'url': '', 'title': 'Empty URL'},
          {'url': 'https://valid.com', 'title': 'Valid'},
        ];

        final result = await bulkRepository.migrateFromServer(
          serverFolders: [],
          serverLinks: serverLinks,
        );

        expect(result.insertedLinks, 1); // 빈 URL은 스킵
      });
    });

    group('quickSaveLink', () {
      test('saves a single link quickly', () async {
        final id = await bulkRepository.quickSaveLink(
          url: 'https://quick.com',
          title: '빠른 저장',
        );

        expect(id, greaterThan(0));

        final link = await linkRepository.getLinkById(id);
        expect(link, isNotNull);
        expect(link!.url, 'https://quick.com');
        expect(link.inflowType, 'share');
      });

      test('returns existing link id for duplicate URL', () async {
        final id1 = await bulkRepository.quickSaveLink(
          url: 'https://duplicate.com',
        );
        final id2 = await bulkRepository.quickSaveLink(
          url: 'https://duplicate.com',
        );

        expect(id1, id2); // 같은 ID 반환
      });

      test('saves to specified folder', () async {
        final folderId = await folderRepository.createFolder(
          LocalFolder(
            name: '지정 폴더',
            createdAt: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now().toIso8601String(),
          ),
        );

        await bulkRepository.quickSaveLink(
          url: 'https://specified.com',
          folderId: folderId,
        );

        final links = await linkRepository.getLinksByFolderId(folderId);
        expect(links.length, 1);
      });

      test('saves to unclassified when no folder specified', () async {
        await bulkRepository.quickSaveLink(url: 'https://nofolder.com');

        final unclassified = await folderRepository.getUnclassifiedFolder();
        final links = await linkRepository.getLinksByFolderId(
          unclassified!.id!,
        );

        expect(links.length, 1);
      });
    });
  });
}
