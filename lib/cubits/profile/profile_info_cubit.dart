import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/models/profile/profile.dart';
import 'package:ac_project_app/provider/api/user/profile_api.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetProfileInfoCubit extends Cubit<ProfileState> {
  GetProfileInfoCubit() : super(ProfileInitialState()) {
    loadProfileData();
  }

  final userApi = UserApi();
  final profileApi = ProfileApi();

  Future<void> loadProfileData() async {
    if (state == ProfileLoadingState()) return;
    emit(ProfileLoadingState());

    final result = await userApi.getUsers();
    result.when(
      success: (user) {
        emit(
          ProfileLoadedState(
            Profile(
              id: user.id,
              nickname: user.nickname,
              jobGroup: user.jobGroup,
              profileImage: user.profileImg,
            ),
          ),
        );
      },
      error: (msg) {
        emit(ProfileErrorState(msg));
      },
    );
  }

  Future<bool> updateProfileImage(String profileImage) async {
    final result = await profileApi.changeImage(profileImg: profileImage);
    return result.when(
      success: (data) {
        Log.i(data.toJson());
        return true;
      },
      error: (msg) {
        return false;
      },
    );
  }
}
