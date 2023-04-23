import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';

class ProfileApi {

  ProfileApi({
    CustomClient? client,
  }) {
    if (client == null) {
      this.client = CustomClient();
    } else {
      this.client = client;
    }
  }

  late final CustomClient client;

  Future<Result<DetailUser>> changeImage({
    required String? profileImg,
  }) async {
    final result = await client.patchUri(
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
