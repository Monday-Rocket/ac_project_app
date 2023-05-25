import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/profile/profile.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/provider/api/user/profile_api.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetProfileInfoCubit extends Cubit<ProfileState> {
  GetProfileInfoCubit() : super(ProfileInitialState()) {
    loadProfileData();
  }

  final UserApi userApi = getIt();
  final ProfileApi profileApi = getIt();

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
              profileImage: user.profile_img,
            ),
          ),
        );
      },
      error: (msg) {
        emit(ProfileErrorState(msg));
      },
    );
  }

  Future<DetailUser> updateProfileImage(String profileImage) async {
    final result = await profileApi.changeImage(profileImg: profileImage);
    return result.when(
      success: (data) {
        Log.i(data.toJson());
        return data;
      },
      error: (msg) {
        return DetailUser();
      },
    );
  }

  void updateFromProfile(DetailUser user) {
    emit(
      ProfileLoadedState(
        Profile(
          id: user.id,
          nickname: user.nickname,
          jobGroup: user.jobGroup,
          profileImage: user.profile_img,
        ),
      ),
    );
  }
}
