import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/models/profile/profile.dart';
import 'package:ac_project_app/provider/api/user/profile_api.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetProfileInfoCubit extends Cubit<ProfileState> {
  GetProfileInfoCubit() : super(ProfileInitialState()) {
    loadProfileData();
  }

  String? imageNumber;

  final userApi = UserApi();
  final profileApi = ProfileApi();

  Future<void> loadProfileData() async {
    emit(ProfileLoadingState());

    final result = await userApi.getUsers();
    result.when(
      success: (user) {
        imageNumber = user.profileImg;
        emit(
          ProfileLoadedState(
            Profile(
              id: user.id,
              nickname: user.nickname,
              profileImage: makeImagePath(user.profileImg),
            ),
          ),
        );
      },
      error: (msg) {
        emit(ProfileErrorState(msg));
      },
    );
  }

  void selectImage(int index) {
    final nickname = (state as ProfileLoadedState).profile.nickname;
    emit(ProfileLoadingState());

    imageNumber = '0${index + 1}';
    emit(
      ProfileLoadedState(
        Profile(
          nickname: nickname,
          profileImage: makeImagePath(imageNumber!),
        ),
      ),
    );
  }

  Future<bool> updateProfileImage() async {
    final result = await profileApi.changeImage(profileImg: imageNumber);
    return result.when(
      success: (data) {
        Log.i(data);
        return true;
      },
      error: (msg) {
        return false;
      },
    );
  }
}
