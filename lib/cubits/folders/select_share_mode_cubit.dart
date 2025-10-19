import 'package:flutter_bloc/flutter_bloc.dart';

class SelectShareModeCubit extends Cubit<bool> {
  SelectShareModeCubit(): super(false);

  void selectPrivateMode() {
    emit(false);
  }

  void selectShareMode() {
    emit(true);
  }
}
