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
}
