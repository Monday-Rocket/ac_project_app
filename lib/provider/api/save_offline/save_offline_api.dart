import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';

class SaveOfflineApi {
  SaveOfflineApi(this._client);

  final CustomClient _client;

  /// 링크 한번에 불러오기 이력 조회
  ///
  /// Returns:
  /// - `true`: 이미 불러오기 완료
  /// - `false`: 아직 불러오기 안함
  Future<Result<bool>> getSaveOfflineHistory() async {
    final result = await _client.getUri('/save-offline');
    return result.when(
      success: (data) => Result.success(data as bool),
      error: Result.error,
    );
  }

  /// 링크 한번에 불러오기 완료 처리
  Future<bool> completeSaveOffline() async {
    final result = await _client.postUri('/save-offline');
    return result.when(
      success: (_) => true,
      error: (_) => false,
    );
  }
}
