import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeViewCubit extends Cubit<int> {
  HomeViewCubit() : super(2);

  final myFolderKey = GlobalKey<NavigatorState>();

  void moveTo(int i) {
    emit(i);
  }
}
