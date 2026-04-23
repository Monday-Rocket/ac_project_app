import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/provider/sync/pro_mutate.dart';
import 'package:ac_project_app/util/logger.dart';

/// Pro CRUD 원격 전파 훅.
///
/// v2 (SYNC_MODEL_V2 §2.2):
/// - Local*Repository 가 로컬 쓰기 직후 이 훅을 **await** 한다.
/// - 훅 내부는 [proMutate] 로 원격 호출을 감싸 오프라인 예외를 분리.
/// - 실패 시 오프라인 예외는 삼키고(다음 lifecycle 의 full-pull 이 정정), 그 외는 상향.
/// - dirty flag 는 v2 에서 폐기됨.
class ProRemoteHooks {
  ProRemoteHooks._();

  static bool Function() _isProGetter = () => false;
  static Future<void> Function(LocalFolder)? _upsertFolder;
  static Future<void> Function(LocalLink)? _upsertLink;
  static Future<void> Function(int)? _deleteFolder;
  static Future<void> Function(int)? _deleteLink;

  static void configure({
    required bool Function() isPro,
    required Future<void> Function(LocalFolder) upsertFolder,
    required Future<void> Function(LocalLink) upsertLink,
    required Future<void> Function(int) deleteFolder,
    required Future<void> Function(int) deleteLink,
  }) {
    _isProGetter = isPro;
    _upsertFolder = upsertFolder;
    _upsertLink = upsertLink;
    _deleteFolder = deleteFolder;
    _deleteLink = deleteLink;
  }

  /// 테스트/로그아웃 시 초기화.
  static void reset() {
    _isProGetter = () => false;
    _upsertFolder = null;
    _upsertLink = null;
    _deleteFolder = null;
    _deleteLink = null;
  }

  static Future<void> onFolderUpserted(LocalFolder folder) async {
    final hook = _upsertFolder;
    if (hook == null || !_isProGetter()) return;
    await _run(() => hook(folder));
  }

  static Future<void> onLinkUpserted(LocalLink link) async {
    final hook = _upsertLink;
    if (hook == null || !_isProGetter()) return;
    await _run(() => hook(link));
  }

  static Future<void> onFolderDeleted(int folderId) async {
    final hook = _deleteFolder;
    if (hook == null || !_isProGetter()) return;
    await _run(() => hook(folderId));
  }

  static Future<void> onLinkDeleted(int linkId) async {
    final hook = _deleteLink;
    if (hook == null || !_isProGetter()) return;
    await _run(() => hook(linkId));
  }

  /// 훅 호출 공통 처리.
  /// - [ProMutateOfflineException] 은 조용히 로그만 남기고 삼킨다 (다음 full-pull 이 정정).
  /// - 그 외 예외는 상향 (호출부가 트랜잭션 결정).
  static Future<void> _run(Future<void> Function() op) async {
    try {
      await op();
    } on ProMutateOfflineException catch (e) {
      Log.e('ProRemoteHooks offline (swallowed, pull will reconcile): $e');
    }
  }
}
