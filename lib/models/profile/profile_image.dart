class ProfileImage {
  ProfileImage(this.filePath, {this.visible = false});

  String filePath;
  bool? visible;

  static String makeImagePath(String image) =>
      'assets/images/profile/img_${image}_on.png';
}
