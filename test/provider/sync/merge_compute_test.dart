import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/provider/sync/merge_compute.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final mergeAt = DateTime.utc(2026, 4, 22, 12);

  group('computeMerge - 빈 케이스', () {
    test('로컬 empty + 원격 empty → 결과 모두 비어있음', () {
      final result = computeMerge(
        localFolders: const [],
        localLinks: const [],
        remoteFolders: const [],
        remoteLinks: const [],
        mergeAt: mergeAt,
      );

      expect(result.folders, isEmpty);
      expect(result.links, isEmpty);
      expect(result.stats.totalFolders, 0);
      expect(result.stats.totalLinks, 0);
    });
  });

  group('computeMerge - 로컬만 있음', () {
    test('로컬 폴더 1개 + 링크 1개 → 그대로 채택, client_id 재할당', () {
      final folder = LocalFolder(
        id: 5,
        name: 'Work',
        createdAt: '2026-04-01T00:00:00.000Z',
        updatedAt: '2026-04-01T00:00:00.000Z',
      );
      final link = LocalLink(
        id: 9,
        folderId: 5,
        url: 'https://a.com',
        title: 'A',
        createdAt: '2026-04-02T00:00:00.000Z',
        updatedAt: '2026-04-02T00:00:00.000Z',
      );

      final result = computeMerge(
        localFolders: [folder],
        localLinks: [link],
        remoteFolders: const [],
        remoteLinks: const [],
        mergeAt: mergeAt,
      );

      expect(result.folders, hasLength(1));
      expect(result.folders.first.id, 1); // 1부터 재할당
      expect(result.folders.first.name, 'Work');
      expect(result.folders.first.parentId, isNull);

      expect(result.links, hasLength(1));
      expect(result.links.first.id, 1);
      expect(result.links.first.folderId, 1); // 재매핑
      expect(result.links.first.url, 'https://a.com');

      expect(result.stats.foldersLocalOnly, 1);
      expect(result.stats.linksLocalOnly, 1);
      expect(result.stats.foldersMerged, 0);
    });
  });

  group('computeMerge - 원격만 있음', () {
    test('원격 폴더 1개 + 링크 1개 → 그대로 채택, client_id 재할당', () {
      final remoteFolders = [
        {
          'id': 'uuid-1',
          'client_id': 100,
          'name': 'Chrome',
          'thumbnail': null,
          'is_classified': true,
          'parent_id': null,
          'created_at': '2026-03-01T00:00:00.000Z',
          'updated_at': '2026-03-01T00:00:00.000Z',
        },
      ];
      final remoteLinks = [
        {
          'id': 'link-uuid-1',
          'client_id': 200,
          'folder_id': 'uuid-1',
          'url': 'https://chrome.com',
          'title': 'Chrome',
          'image': null,
          'describe': null,
          'inflow_type': null,
          'created_at': '2026-03-02T00:00:00.000Z',
          'updated_at': '2026-03-02T00:00:00.000Z',
        },
      ];

      final result = computeMerge(
        localFolders: const [],
        localLinks: const [],
        remoteFolders: remoteFolders,
        remoteLinks: remoteLinks,
        mergeAt: mergeAt,
      );

      expect(result.folders, hasLength(1));
      expect(result.folders.first.id, 1);
      expect(result.folders.first.name, 'Chrome');

      expect(result.links, hasLength(1));
      expect(result.links.first.id, 1);
      expect(result.links.first.folderId, 1);
      expect(result.links.first.url, 'https://chrome.com');

      expect(result.stats.foldersRemoteOnly, 1);
      expect(result.stats.linksRemoteOnly, 1);
    });
  });

  group('computeMerge - CRITICAL 회귀: 중첩 폴더 링크 매핑', () {
    test('중첩 폴더 안의 링크가 드롭되지 않음 (compound key 파싱 버그 회귀 방지)', () {
      final work = LocalFolder(
        id: 1,
        name: 'Work',
        createdAt: '2026-04-01T00:00:00.000Z',
        updatedAt: '2026-04-01T00:00:00.000Z',
      );
      final frontend = LocalFolder(
        id: 2,
        parentId: 1,
        name: 'Frontend',
        createdAt: '2026-04-02T00:00:00.000Z',
        updatedAt: '2026-04-02T00:00:00.000Z',
      );
      final link = LocalLink(
        id: 10,
        folderId: 2, // 중첩 폴더 안의 링크
        url: 'https://nested.com',
        createdAt: '2026-04-03T00:00:00.000Z',
        updatedAt: '2026-04-03T00:00:00.000Z',
      );

      final result = computeMerge(
        localFolders: [work, frontend],
        localLinks: [link],
        remoteFolders: const [],
        remoteLinks: const [],
        mergeAt: mergeAt,
      );

      expect(result.folders, hasLength(2));
      expect(result.links, hasLength(1), reason: '중첩 폴더 링크가 드롭되면 안 됨');
      // Frontend 폴더의 새 id를 찾아 링크의 folderId가 그것인지 확인
      final frontendNew = result.folders.firstWhere((f) => f.name == 'Frontend');
      expect(result.links.first.folderId, frontendNew.id);
      expect(result.stats.linksLocalOnly, 1);
    });
  });

  group('computeMerge - 양쪽 머지 & 필드 규칙', () {
    test('같은 URL + 같은 path_key → 하나로 머지 + 필드 규칙 적용', () {
      final localFolder = LocalFolder(
        id: 10,
        name: 'Work',
        thumbnail: null,
        createdAt: '2026-04-01T00:00:00.000Z',
        updatedAt: '2026-04-10T00:00:00.000Z',
      );
      final localLink = LocalLink(
        id: 50,
        folderId: 10,
        url: 'https://same.com',
        title: null,
        describe: '로컬 메모',
        createdAt: '2026-04-05T00:00:00.000Z',
        updatedAt: '2026-04-10T00:00:00.000Z',
      );
      final remoteFolder = {
        'id': 'uuid-work',
        'client_id': 99,
        'name': 'Work',
        'thumbnail': 'remote.png',
        'is_classified': true,
        'parent_id': null,
        'created_at': '2026-03-15T00:00:00.000Z',
        'updated_at': '2026-04-20T00:00:00.000Z',
      };
      final remoteLink = {
        'id': 'uuid-link',
        'client_id': 77,
        'folder_id': 'uuid-work',
        'url': 'https://same.com',
        'title': '원격 제목',
        'image': 'img.png',
        'describe': null,
        'inflow_type': null,
        'created_at': '2026-03-20T00:00:00.000Z',
        'updated_at': '2026-04-20T00:00:00.000Z',
      };

      final result = computeMerge(
        localFolders: [localFolder],
        localLinks: [localLink],
        remoteFolders: [remoteFolder],
        remoteLinks: [remoteLink],
        mergeAt: mergeAt,
      );

      // 폴더: 하나로 머지
      expect(result.folders, hasLength(1));
      expect(result.folders.first.name, 'Work');
      // thumbnail: 비어있지 않은 쪽 우선 → 원격
      expect(result.folders.first.thumbnail, 'remote.png');
      // created_at: 더 이른 쪽 → 원격(3/15)
      expect(result.folders.first.createdAt, '2026-03-15T00:00:00.000Z');
      // updated_at: 머지 시점
      expect(result.folders.first.updatedAt,
          mergeAt.toUtc().toIso8601String());

      // 링크: 하나로 머지
      expect(result.links, hasLength(1));
      // title: 로컬 null, 원격 있음 → 원격
      expect(result.links.first.title, '원격 제목');
      // image: 로컬 null, 원격 있음 → 원격
      expect(result.links.first.image, 'img.png');
      // describe: 로컬 있음, 원격 null → 로컬
      expect(result.links.first.describe, '로컬 메모');
      // url: 로컬 원본
      expect(result.links.first.url, 'https://same.com');
      // created_at: 이른 쪽 → 원격(3/20)
      expect(result.links.first.createdAt, '2026-03-20T00:00:00.000Z');
      // updated_at: 머지 시점
      expect(result.links.first.updatedAt,
          mergeAt.toUtc().toIso8601String());

      expect(result.stats.foldersMerged, 1);
      expect(result.stats.linksMerged, 1);
    });

    test('같은 URL + 다른 path_key → 두 개로 유지 (Q1=C)', () {
      final localFolder = LocalFolder(
        id: 1,
        name: 'Work',
        createdAt: '2026-04-01T00:00:00.000Z',
        updatedAt: '2026-04-01T00:00:00.000Z',
      );
      final localLink = LocalLink(
        id: 1,
        folderId: 1,
        url: 'https://same.com',
        createdAt: '2026-04-01T00:00:00.000Z',
        updatedAt: '2026-04-01T00:00:00.000Z',
      );
      final remoteFolder = {
        'id': 'uuid-dev',
        'client_id': 1,
        'name': 'Dev', // 다른 이름 → 다른 path_key
        'thumbnail': null,
        'is_classified': true,
        'parent_id': null,
        'created_at': '2026-03-01T00:00:00.000Z',
        'updated_at': '2026-03-01T00:00:00.000Z',
      };
      final remoteLink = {
        'id': 'uuid-link',
        'client_id': 1,
        'folder_id': 'uuid-dev',
        'url': 'https://same.com', // 같은 URL
        'title': null,
        'image': null,
        'describe': null,
        'inflow_type': null,
        'created_at': '2026-03-01T00:00:00.000Z',
        'updated_at': '2026-03-01T00:00:00.000Z',
      };

      final result = computeMerge(
        localFolders: [localFolder],
        localLinks: [localLink],
        remoteFolders: [remoteFolder],
        remoteLinks: [remoteLink],
        mergeAt: mergeAt,
      );

      expect(result.folders, hasLength(2));
      expect(result.links, hasLength(2));
      expect(result.stats.linksMerged, 0);
      expect(result.stats.linksLocalOnly, 1);
      expect(result.stats.linksRemoteOnly, 1);
    });

    test('대소문자 다른 폴더/URL → 두 개로 유지 (Q7=A)', () {
      final localFolder = LocalFolder(
        id: 1,
        name: 'Work',
        createdAt: '2026-04-01T00:00:00.000Z',
        updatedAt: '2026-04-01T00:00:00.000Z',
      );
      final remoteFolder = {
        'id': 'uuid',
        'client_id': 1,
        'name': 'work', // 대소문자 다름
        'thumbnail': null,
        'is_classified': true,
        'parent_id': null,
        'created_at': '2026-03-01T00:00:00.000Z',
        'updated_at': '2026-03-01T00:00:00.000Z',
      };

      final result = computeMerge(
        localFolders: [localFolder],
        localLinks: const [],
        remoteFolders: [remoteFolder],
        remoteLinks: const [],
        mergeAt: mergeAt,
      );

      expect(result.folders, hasLength(2));
      expect(result.stats.foldersMerged, 0);
    });

    test('양쪽 미분류 폴더 → 하나로 통합', () {
      final localFolder = LocalFolder(
        id: 1,
        name: '미분류',
        isClassified: false,
        createdAt: '2026-04-01T00:00:00.000Z',
        updatedAt: '2026-04-01T00:00:00.000Z',
      );
      final remoteFolder = {
        'id': 'uuid',
        'client_id': 1,
        'name': 'Unclassified', // 이름 달라도 is_classified=false면 같은 폴더
        'thumbnail': null,
        'is_classified': false,
        'parent_id': null,
        'created_at': '2026-03-01T00:00:00.000Z',
        'updated_at': '2026-03-01T00:00:00.000Z',
      };

      final result = computeMerge(
        localFolders: [localFolder],
        localLinks: const [],
        remoteFolders: [remoteFolder],
        remoteLinks: const [],
        mergeAt: mergeAt,
      );

      expect(result.folders, hasLength(1));
      expect(result.folders.first.isClassified, false);
      expect(result.folders.first.name, '미분류'); // 로컬 이름
      expect(result.stats.foldersMerged, 1);
    });
  });
}
