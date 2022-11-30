import 'package:flutter_bloc/flutter_bloc.dart';

class HomeViewCubit extends Cubit<int> {
  HomeViewCubit(super.initialState);

  void moveTo(int i) {
    emit(i);
  }
}
