import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScrollCubit extends Cubit<bool> {
  ScrollCubit(ScrollController controller) : super(false) {
    scrollController = controller;
    emit(false);

    scrollController.addListener(scrollListener);
  }

  late ScrollController scrollController;

  void scrollListener() {
    if (scrollController.offset > 5) {
      emit(true);
    } else {
      emit(false);
    }
  }
}
