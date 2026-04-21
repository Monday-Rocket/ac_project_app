import 'dart:async';

import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/models/local/local_link.dart';
import 'package:ac_project_app/util/logger.dart';

/// Pro 유저의 로컬 CRUD를 원격에 fire-and-forget 전파하기 위한 전역 훅.
///
/// 앱 시작 시 `ProRemoteHooks.configure(...)` 한 번으로 AuthCubit + SyncRepository 를 연결해두면,
/// Local*Repository 들은 이 훅만 호출하면 된다 (Cubit/SyncRepository 직접 의존 제거).
///
/// Pro 가 아니거나 훅이 설정돼 있지 않으면 no-op.
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

  static void onFolderUpserted(LocalFolder folder) {
    final hook = _upsertFolder;
    if (hook == null || !_isProGetter()) return;
    unawaited(_safe(() => hook(folder)));
  }

  static void onLinkUpserted(LocalLink link) {
    final hook = _upsertLink;
    if (hook == null || !_isProGetter()) return;
    unawaited(_safe(() => hook(link)));
  }

  static void onFolderDeleted(int folderId) {
    final hook = _deleteFolder;
    if (hook == null || !_isProGetter()) return;
    unawaited(_safe(() => hook(folderId)));
  }

  static void onLinkDeleted(int linkId) {
    final hook = _deleteLink;
    if (hook == null || !_isProGetter()) return;
    unawaited(_safe(() => hook(linkId)));
  }

  static Future<void> _safe(Future<void> Function() op) async {
    try {
      await op();
    } catch (e) {
      Log.e('ProRemoteHooks error (swallowed): $e');
    }
  }
}
