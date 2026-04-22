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
}
