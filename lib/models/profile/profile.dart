import 'package:ac_project_app/models/user/detail_user.dart';

class Profile {
  Profile({
    this.id,
    required this.nickname,
    required this.profileImage,
    this.jobGroup,
  });

  int? id;
  String nickname;
  String profileImage;
  JobGroup? jobGroup;
}
