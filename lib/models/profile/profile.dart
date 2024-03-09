class Profile {

  Profile({
    required this.nickname,
    required this.profileImage,
    this.id,
  });

  int? id;
  String nickname;
  String profileImage;
}
