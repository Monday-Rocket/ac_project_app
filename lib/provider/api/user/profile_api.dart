import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';

class ProfileApi {
  final client = CustomClient();

  Future<Result<DetailUser>> changeImage({
    required String? profileImg,
  }) async {
    final result = await client.patchUri(
      '/users',
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
