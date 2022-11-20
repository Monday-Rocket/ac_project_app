import 'package:flutter_bloc/flutter_bloc.dart';

class HomeSecondViewCubit extends Cubit<int> {
  HomeSecondViewCubit() : super(0);

  void addSecondView() {
    emit(state + 1);
  }

  void goBack() {
    emit(0);
  }
}
