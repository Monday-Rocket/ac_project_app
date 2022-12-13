import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class NicknameCubit extends Cubit<String?>{
  NicknameCubit(): super('');

  void updateName(String? state) => emit(state);

  final formKey = GlobalKey<FormState>();
}
