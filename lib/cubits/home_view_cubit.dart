import 'package:flutter_bloc/flutter_bloc.dart';

class HomeViewCubit extends Cubit<int> {
  HomeViewCubit(): super(2);

  void moveTo(int i) {
    emit(i);
  }
}
