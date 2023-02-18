import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NicknameCheckCubit extends Cubit<bool?> {
  NicknameCheckCubit() : super(null);

  final userApi = UserApi();

  Future<bool> isDuplicated(String nickname) async {
    final result = await userApi.checkDuplicatedNickname(nickname);
    emit(result);
    return result;
  }

  void reset() {
    emit(null);
  }
}