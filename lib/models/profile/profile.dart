import 'package:ac_project_app/models/user/detail_user.dart';

class Profile {

  Profile({
    required this.nickname,
    required this.profileImage,
    required this.jobGroup,
    this.id,
  });

  int? id;
  String nickname;
  String profileImage;
  JobGroup? jobGroup;
}
