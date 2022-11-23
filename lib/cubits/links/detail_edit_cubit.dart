import 'package:ac_project_app/cubits/links/edit_state.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DetailEditCubit extends Cubit<EditState> {
  DetailEditCubit(Link link) : super(EditState.view) {
    textController.text = link.describe ?? '';
  }

  final linkApi = LinkApi();
  final textController = TextEditingController();

  void toggle() {
    if (state == EditState.view) {
      emit(EditState.edit);
    } else {
      emit(EditState.view);
    }
  }

  Future<bool> saveComment(Link link) async {
    link.describe = textController.text;
    return linkApi.patchLink(link);
  }
}
