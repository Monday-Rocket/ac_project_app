import 'package:ac_project_app/models/profile/profile_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetProfileImagesCubit extends Cubit<List<ProfileImage>> {
  GetProfileImagesCubit()
      : super([
          ProfileImage('assets/images/profile/img_01_on.png'),
          ProfileImage('assets/images/profile/img_02_on.png'),
          ProfileImage('assets/images/profile/img_03_on.png'),
          ProfileImage('assets/images/profile/img_04_on.png'),
          ProfileImage('assets/images/profile/img_05_on.png'),
          ProfileImage('assets/images/profile/img_06_on.png'),
          ProfileImage('assets/images/profile/img_07_on.png'),
          ProfileImage('assets/images/profile/img_08_on.png'),
          ProfileImage('assets/images/profile/img_09_on.png'),
        ]);
  final initList = [
    ProfileImage('assets/images/profile/img_01_on.png'),
    ProfileImage('assets/images/profile/img_02_on.png'),
    ProfileImage('assets/images/profile/img_03_on.png'),
    ProfileImage('assets/images/profile/img_04_on.png'),
    ProfileImage('assets/images/profile/img_05_on.png'),
    ProfileImage('assets/images/profile/img_06_on.png'),
    ProfileImage('assets/images/profile/img_07_on.png'),
    ProfileImage('assets/images/profile/img_08_on.png'),
    ProfileImage('assets/images/profile/img_09_on.png'),
  ];

  bool selected = false;

  void select(int i) {
    final list = List<ProfileImage>.from(initList);
    list[i] = ProfileImage(
      'assets/images/profile/img_0${i + 1}_on.png',
      visible: true,
    );
    selected = true;
    emit(list);
  }
}
