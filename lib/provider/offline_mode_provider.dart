import 'package:ac_project_app/provider/shared_pref_provider.dart';

/// 오프라인 모드 완료 상태를 관리하는 Provider
class OfflineModeProvider {
  static const String _key = 'offlineModeCompleted';

  /// 오프라인 모드가 완료되었는지 확인
  static Future<bool> isOfflineModeCompleted() async {
    try {
      return await SharedPrefHelper.getValueFromKey<bool>(
        _key,
        defaultValue: false,
      );
    } catch (e) {
      return false;
    }
  }

  /// 오프라인 모드 완료 상태 저장
  static Future<bool> setOfflineModeCompleted({bool completed = true}) async {
    return SharedPrefHelper.saveKeyValue(_key, completed);
  }

  /// 오프라인 모드 상태 초기화 (로그아웃 시 사용)
  static Future<bool> clearOfflineMode() async {
    return SharedPrefHelper.saveKeyValue(_key, false);
  }
}
