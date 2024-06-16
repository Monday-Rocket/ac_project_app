import 'package:ac_project_app/util/logger.dart';
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
    Log.i('offset: ${scrollController.offset}');
    if (scrollController.offset > 10) {
      emit(true);
    } else {
      emit(false);
    }
  }
}
