import 'package:ac_project_app/provider/shared_pref_provider.dart';

/// 폴더 선택 모달의 "최근 사용" 섹션에 노출할 폴더 ID를 관리.
/// 저장은 SharedPreferences의 단일 키에 쉼표 구분 문자열로. 최대 N개 유지.
class RecentFoldersRepository {
  const RecentFoldersRepository();

  static const String _key = 'lp_recent_folder_ids';
  static const int _maxItems = 5;

  Future<List<int>> getRecentIds() async {
    final raw = await SharedPrefHelper.getValueFromKey<String>(
      _key,
      defaultValue: '',
    );
    if (raw.isEmpty) return const [];
    return raw
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();
  }

  /// 해당 folderId를 "가장 최근"으로 기록. 이미 있으면 앞으로 이동.
  Future<void> record(int folderId) async {
    final current = await getRecentIds();
    final updated = <int>[folderId, ...current.where((id) => id != folderId)];
    if (updated.length > _maxItems) {
      updated.removeRange(_maxItems, updated.length);
    }
    await SharedPrefHelper.saveKeyValue(_key, updated.join(','));
  }

  /// 삭제된 폴더 ID가 recent에 남지 않도록 정리.
  Future<void> remove(int folderId) async {
    final current = await getRecentIds();
    final updated = current.where((id) => id != folderId).toList();
    await SharedPrefHelper.saveKeyValue(_key, updated.join(','));
  }

  Future<void> clear() async {
    await SharedPrefHelper.saveKeyValue(_key, '');
  }
}
