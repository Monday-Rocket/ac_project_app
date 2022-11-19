import 'package:ac_project_app/models/profile/profile.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GetProfileInfoCubit extends Cubit<Profile> {
  GetProfileInfoCubit(): super(Profile('', '')) {
    loadProfileData();
  }

  void loadProfileData() {
    /* TODO API 호출 */
    const image = '01';
    emit(Profile('숩숩', makeImagePath(image)));
  }

  void selectImage(int index) {
    final image = '0${index + 1}';
    emit(Profile(state.nickname, makeImagePath(image)));
  }

  String makeImagePath(String image) => 'assets/images/profile/img_${image}_on.png';

}
