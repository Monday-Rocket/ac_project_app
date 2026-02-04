import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:ac_project_app/provider/api/save_offline/save_offline_api.dart';
import 'package:ac_project_app/provider/local/local_bulk_repository.dart';
import 'package:ac_project_app/util/logger.dart';

/// 서버 데이터를 로컬 DB로 마이그레이션하는 서비스
class OfflineMigrationService {
  OfflineMigrationService({
    SaveOfflineApi? saveOfflineApi,
    FolderApi? folderApi,
    LinkApi? linkApi,
    LocalBulkRepository? bulkRepository,
  })  : _saveOfflineApi = saveOfflineApi ?? getIt(),
        _folderApi = folderApi ?? getIt(),
        _linkApi = linkApi ?? getIt(),
        _bulkRepository = bulkRepository ?? getIt();

  final SaveOfflineApi _saveOfflineApi;
  final FolderApi _folderApi;
  final LinkApi _linkApi;
  final LocalBulkRepository _bulkRepository;

  /// 마이그레이션이 이미 완료되었는지 확인
  Future<bool> isMigrationCompleted() async {
    try {
      final result = await _saveOfflineApi.getSaveOfflineHistory();
      return result.when(
        success: (completed) => completed,
        error: (_) => false,
      );
    } catch (e) {
      Log.e('OfflineMigrationService.isMigrationCompleted error: $e');
      return false;
    }
  }

  /// 서버에서 로컬로 데이터 마이그레이션 실행
  Future<MigrationResult> migrateToLocal() async {
    try {
      // 1. 마이그레이션 이미 완료되었는지 확인
      if (await isMigrationCompleted()) {
        Log.i('Migration already completed');
        return MigrationResult.alreadyCompleted();
      }

      // 2. 서버에서 모든 폴더 가져오기
      final foldersResult = await _folderApi.getMyFolders();
      final folders = foldersResult.when(
        success: (list) => list,
        error: (_) => <Folder>[],
      );

      // 3. 서버에서 모든 링크 가져오기 (페이지네이션 처리)
      final allLinks = <Link>[];
      var page = 0;
      var hasMore = true;

      while (hasMore) {
        final linksResult = await _linkApi.getLinks(page);
        hasMore = linksResult.when(
          success: (data) {
            final links = data.contents ?? [];
            allLinks.addAll(links);
            page++;
            return data.hasMorePage();
          },
          error: (_) => false,
        );
      }

      // 4. 로컬 DB에 저장
      final serverFolders = folders.map((f) => f.toJson()).toList();
      final serverLinks = allLinks.map((l) => l.toJson()).toList();
      final bulkResult = await _bulkRepository.migrateFromServer(
        serverFolders: serverFolders,
        serverLinks: serverLinks,
      );

      // 5. 마이그레이션 완료 표시
      final success = await _saveOfflineApi.completeSaveOffline();

      if (success) {
        Log.i('Migration completed successfully: '
            '${bulkResult.insertedFolders} folders, '
            '${bulkResult.insertedLinks} links');
        return MigrationResult.success(
          foldersCount: bulkResult.insertedFolders,
          linksCount: bulkResult.insertedLinks,
        );
      } else {
        Log.e('Failed to mark migration as complete');
        return MigrationResult.error('마이그레이션 완료 표시 실패');
      }
    } catch (e) {
      Log.e('OfflineMigrationService.migrateToLocal error: $e');
      return MigrationResult.error(e.toString());
    }
  }
}

/// 마이그레이션 결과
class MigrationResult {
  MigrationResult._({
    required this.status,
    this.foldersCount,
    this.linksCount,
    this.errorMessage,
  });

  factory MigrationResult.success({
    required int foldersCount,
    required int linksCount,
  }) {
    return MigrationResult._(
      status: MigrationStatus.success,
      foldersCount: foldersCount,
      linksCount: linksCount,
    );
  }

  factory MigrationResult.alreadyCompleted() {
    return MigrationResult._(status: MigrationStatus.alreadyCompleted);
  }

  factory MigrationResult.error(String message) {
    return MigrationResult._(
      status: MigrationStatus.error,
      errorMessage: message,
    );
  }

  final MigrationStatus status;
  final int? foldersCount;
  final int? linksCount;
  final String? errorMessage;

  bool get isSuccess => status == MigrationStatus.success;
  bool get isAlreadyCompleted => status == MigrationStatus.alreadyCompleted;
  bool get isError => status == MigrationStatus.error;
}

enum MigrationStatus {
  success,
  alreadyCompleted,
  error,
}
