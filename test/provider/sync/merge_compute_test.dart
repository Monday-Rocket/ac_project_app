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
}
