import 'package:ac_project_app/cubits/links/edit_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DetailEditCubit extends Cubit<EditState> {
  DetailEditCubit(Object? argument) : super(EditState.view) {
    if (argument is Map) {
      final link = (argument['link'] ?? const Link()) as Link;
      textController.text = link.describe ?? '';
    }
  }

  final LinkApi linkApi = getIt();
  final textController = TextEditingController();

  void toggle() {
    if (state == EditState.view) {
      emit(EditState.edit);
    } else {
      emit(EditState.view);
    }
  }

  Future<bool> saveComment(Link link) async {
    final newLink = link.copyWith(describe: textController.text);
    return linkApi.patchLink(newLink);
  }
}
