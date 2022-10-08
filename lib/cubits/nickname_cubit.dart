import 'package:flutter_bloc/flutter_bloc.dart';


class NicknameCubit extends Cubit<String?>{
  NicknameCubit(super.initialState);

  void updateName(String? state) => emit(state);

  String? getNickname() => state;
}