import 'package:firebase_storage/firebase_storage.dart';

class ProfileImage {
  ProfileImage(this.filePath, {this.visible = false});

  String filePath;
  bool? visible;

  static String makeImagePath(String image) =>
      'assets/images/profile/img_${image}_on.webp';

  Future<String> makeImageUrl() async =>
      FirebaseStorage.instance
          .refFromURL('gs://ac-project-d04ee.appspot.com/img_${filePath}_on.png')
          .getDownloadURL();
}
