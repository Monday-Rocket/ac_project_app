import 'package:ac_project_app/ui/widget/widget_offset.dart';
import 'package:flutter/material.dart';

WidgetOffset? getOffsetFromGlobalKey(GlobalKey key) {
  if (key.currentContext != null) {
    final box = key.currentContext!.findRenderObject() as RenderBox?;

    final offset = box?.localToGlobal(Offset.zero);
    final size = getSizeFromGlobalKey(key);

    if (offset != null && size != null) {
      final leftTop = Offset(offset.dx, offset.dy);
      final rightTop = Offset(offset.dx + size.width, offset.dy);
      final leftBottom = Offset(offset.dx, offset.dy + size.height);
      final rightBottom =
          Offset(offset.dx + size.width, offset.dy + size.height);

      return WidgetOffset(leftTop, rightTop, leftBottom, rightBottom, true);
    }
    return null;
  }
  return null;
}

Size? getSizeFromGlobalKey(GlobalKey key) {
  if (key.currentContext != null) {
    final box = key.currentContext!.findRenderObject() as RenderBox?;
    return box?.size;
  }
  return null;
}
