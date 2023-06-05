import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';

class ProfileApi {

  ProfileApi(this._client);

  final CustomClient _client;

  Future<Result<DetailUser>> changeImage({
    required String? profileImg,
  }) async {
    final result = await _client.patchUri(
      '/users/me',
      body: {
        'profile_img': profileImg
      },
    );
    return result.when(
      success: (data) => Result.success(DetailUser.fromJson(data)),
      error: Result.error,
    );
  }
}
