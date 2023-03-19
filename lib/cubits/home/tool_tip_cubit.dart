import 'package:ac_project_app/provider/tool_tip_check.dart';
import 'package:ac_project_app/ui/widget/widget_offset.dart';
import 'package:ac_project_app/util/offset_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ToolTipCubit extends Cubit<WidgetOffset?> {
  ToolTipCubit(GlobalKey<State<StatefulWidget>> uploadToolTipKey)
      : super(null) {
    ToolTipCheck.hasNotBottomUploaded().then((result) {
      if (result) {
        final buttonWidgetOffset = getOffsetFromGlobalKey(uploadToolTipKey);
        if (buttonWidgetOffset != null) {
          emit(buttonWidgetOffset);
        }
      }
    });
  }

  void invisible() {
    if (state != null) {
      emit(
        WidgetOffset(
          state!.leftTop,
          state!.rightTop,
          state!.leftBottom,
          state!.rightBottom,
          false,
        ),
      );
    }
  }
}
