import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/profile/profile_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetProfileImagesCubit extends Cubit<List<ProfileImage>> {
  GetProfileImagesCubit()
      : super([
          ProfileImage(Assets.images.profile.img01On.path),
          ProfileImage(Assets.images.profile.img02On.path),
          ProfileImage(Assets.images.profile.img03On.path),
          ProfileImage(Assets.images.profile.img04On.path),
          ProfileImage(Assets.images.profile.img05On.path),
          ProfileImage(Assets.images.profile.img06On.path),
          ProfileImage(Assets.images.profile.img07On.path),
          ProfileImage(Assets.images.profile.img08On.path),
          ProfileImage(Assets.images.profile.img09On.path),
        ]);
  final initList = [
    ProfileImage(Assets.images.profile.img01On.path),
    ProfileImage(Assets.images.profile.img02On.path),
    ProfileImage(Assets.images.profile.img03On.path),
    ProfileImage(Assets.images.profile.img04On.path),
    ProfileImage(Assets.images.profile.img05On.path),
    ProfileImage(Assets.images.profile.img06On.path),
    ProfileImage(Assets.images.profile.img07On.path),
    ProfileImage(Assets.images.profile.img08On.path),
    ProfileImage(Assets.images.profile.img09On.path),
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
