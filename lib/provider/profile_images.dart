import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/profile/profile_image.dart';

List<ProfileImage> getProfileImages() {
  return [
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
}
