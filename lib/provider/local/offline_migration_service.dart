import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:ac_project_app/provider/api/save_offline/save_offline_api.dart';
import 'package:ac_project_app/provider/local/local_bulk_repository.dart';
import 'package:ac_project_app/provider/offline_mode_provider.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/migration_logger.dart';

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

  static const bool _forceMigration = false;

  /// 서버에서 로컬로 데이터 마이그레이션 실행
  Future<MigrationResult> migrateToLocal() async {
    final logger = MigrationLogger.instance;

    try {
      // 로그 세션 시작
      await logger.start();

      // 1. 마이그레이션 이미 완료되었는지 확인
      logger.separator();
      logger.info('[API] GET /save-offline 호출 중...');

      final historyResult = await _saveOfflineApi.getSaveOfflineHistory();
      final alreadyCompleted = historyResult.when(
        success: (completed) {
          logger.info('[API] GET /save-offline 응답: $completed');
          return completed;
        },
        error: (msg) {
          logger.error('[API] GET /save-offline 실패: $msg');
          return false;
        },
      );

      if (alreadyCompleted && !_forceMigration) {
        Log.i('Migration already completed');
        logger.info('마이그레이션 이미 완료됨 - 스킵');
        await logger.finish();
        return MigrationResult.alreadyCompleted();
      }

      if (_forceMigration) {
        logger.info('강제 마이그레이션 모드 - 기존 완료 상태 무시');
      }
      logger.info('마이그레이션 시작');

      // 2. 서버에서 모든 폴더 가져오기
      logger.separator();
      logger.info('[API] GET /folders 호출 중...');

      final foldersResult = await _folderApi.getMyFolders();
      final folders = foldersResult.when(
        success: (list) {
          logger.info('[API] GET /folders 응답: ${list.length}개 폴더');
          return list;
        },
        error: (msg) {
          logger.error('[API] GET /folders 실패: $msg');
          return <Folder>[];
        },
      );

      logger.folder('총 ${folders.length}개 폴더 조회됨');
      for (final folder in folders) {
        logger.folder('  - [${folder.id}] ${folder.name} (visible: ${folder.visible})');
      }

      // 3. 각 폴더별로 링크 가져오기 (페이지네이션 처리)
      logger.separator();
      logger.info('각 폴더별 링크 조회 중...');

      final allLinks = <Link>[];
      final excludedFolderIds = <int>{};  // 접근 권한 없는 폴더 제외

      for (final folder in folders) {
        var page = 0;
        var hasMore = true;
        var folderLinkCount = 0;
        var hasAccessError = false;

        logger.folder('폴더 [${folder.id}] ${folder.name} 링크 조회 시작');

        while (hasMore) {
          logger.link('[API] GET /folders/${folder.id}/links?page_no=$page 호출 중...');
          final linksResult = await _linkApi.getLinksFromSelectedFolder(
            folder,
            page,
          );
          hasMore = linksResult.when(
            success: (data) {
              final links = data.contents ?? [];
              allLinks.addAll(links);
              folderLinkCount += links.length;
              logger.link('[API] 응답: 페이지 ${page + 1}, ${links.length}개 (총 ${data.totalCount}개 중)');
              page++;
              return data.hasMorePage();
            },
            error: (msg) {
              logger.error('[API] GET /folders/${folder.id}/links 실패: $msg');
              // "폴더 멤버가 아닙니다" 에러 시 해당 폴더 제외
              if (msg.contains('폴더 멤버가 아닙니다') || msg.contains('통신 에러')) {
                hasAccessError = true;
              }
              return false;
            },
          );
        }

        if (hasAccessError && folder.id != null) {
          excludedFolderIds.add(folder.id!);
          logger.folder('폴더 [${folder.id}] 제외됨 (접근 권한 없음)');
        } else {
          logger.folder('폴더 [${folder.id}] 완료: $folderLinkCount개 링크');
        }
      }

      // 제외된 폴더 목록에서 제거
      folders.removeWhere((f) => f.id != null && excludedFolderIds.contains(f.id));
      logger.info('저장 대상 폴더: ${folders.length}개 (${excludedFolderIds.length}개 제외됨)');

      // 4. 미분류 링크 가져오기
      logger.separator();
      logger.info('미분류 링크 조회 중...');

      var unclassifiedPage = 0;
      var hasMoreUnclassified = true;
      var unclassifiedCount = 0;

      while (hasMoreUnclassified) {
        logger.link('[API] GET /links/unclassified?page_no=$unclassifiedPage 호출 중...');
        final linksResult = await _linkApi.getUnClassifiedLinks(
          unclassifiedPage,
        );
        hasMoreUnclassified = linksResult.when(
          success: (data) {
            final links = data.contents ?? [];
            allLinks.addAll(links);
            unclassifiedCount += links.length;
            logger.link('[API] 응답: 페이지 ${unclassifiedPage + 1}, ${links.length}개 (총 ${data.totalCount}개 중)');
            unclassifiedPage++;
            return data.hasMorePage();
          },
          error: (msg) {
            logger.error('[API] GET /links/unclassified 실패: $msg');
            return false;
          },
        );
      }

      logger.info('미분류 링크 완료: $unclassifiedCount개');
      logger.separator();
      logger.info('총 수집된 링크: ${allLinks.length}개');

      // 5. 로컬 DB에 저장
      logger.separator();
      logger.info('로컬 DB에 저장 중...');

      final serverFolders = folders.map((f) => f.toJson()).toList();
      final serverLinks = allLinks.map((l) => l.toJson()).toList();
      final bulkResult = await _bulkRepository.migrateFromServer(
        serverFolders: serverFolders,
        serverLinks: serverLinks,
      );

      logger.info('DB 저장 완료: ${bulkResult.insertedFolders}개 폴더, ${bulkResult.insertedLinks}개 링크');

      // 6. 마이그레이션 완료 표시
      logger.separator();
      logger.info('[API] POST /save-offline 호출 중...');
      final success = await _saveOfflineApi.completeSaveOffline();
      logger.info('[API] POST /save-offline 응답: ${success ? "성공" : "실패"}');

      if (success) {
        Log.i('Migration completed successfully: '
            '${bulkResult.insertedFolders} folders, '
            '${bulkResult.insertedLinks} links');

        // 로컬에 오프라인 모드 완료 상태 저장
        await OfflineModeProvider.setOfflineModeCompleted();
        logger.info('오프라인 모드 완료 상태 로컬 저장 완료');

        final logPath = await logger.finish(
          foldersCount: bulkResult.insertedFolders,
          linksCount: bulkResult.insertedLinks,
        );
        Log.i('Migration log saved to: $logPath');

        return MigrationResult.success(
          foldersCount: bulkResult.insertedFolders,
          linksCount: bulkResult.insertedLinks,
          logFilePath: logPath,
        );
      } else {
        Log.e('Failed to mark migration as complete');
        logger.error('서버에 마이그레이션 완료 표시 실패');
        await logger.finish(errorMessage: '마이그레이션 완료 표시 실패');
        return MigrationResult.error('마이그레이션 완료 표시 실패');
      }
    } catch (e) {
      Log.e('OfflineMigrationService.migrateToLocal error: $e');
      logger.error('예외 발생: $e');
      await logger.finish(errorMessage: e.toString());
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
    this.logFilePath,
  });

  factory MigrationResult.success({
    required int foldersCount,
    required int linksCount,
    String? logFilePath,
  }) {
    return MigrationResult._(
      status: MigrationStatus.success,
      foldersCount: foldersCount,
      linksCount: linksCount,
      logFilePath: logFilePath,
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
  final String? logFilePath;

  bool get isSuccess => status == MigrationStatus.success;
  bool get isAlreadyCompleted => status == MigrationStatus.alreadyCompleted;
  bool get isError => status == MigrationStatus.error;
}

enum MigrationStatus {
  success,
  alreadyCompleted,
  error,
}
