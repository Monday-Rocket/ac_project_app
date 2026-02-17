import 'package:flutter_bloc/flutter_bloc.dart';

class ButtonStateCubit extends Cubit<ButtonState> {
  ButtonStateCubit(): super(ButtonState.disabled);

  void disable() {
    emit(ButtonState.disabled);
  }

  void enable() {
    emit(ButtonState.enabled);
  }
}

enum ButtonState {
  enabled, disabled,
}
