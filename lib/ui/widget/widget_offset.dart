// ignore_for_file: avoid_positional_boolean_parameters

import 'package:flutter/material.dart';

class WidgetOffset {
  WidgetOffset(this.leftTop, this.rightTop, this.leftBottom, this.rightBottom,
      this.visible);

  final Offset leftTop;
  final Offset rightTop;
  final Offset leftBottom;
  final Offset rightBottom;
  bool visible;

  Offset getTopMid() {
    return Offset((leftTop.dx + rightTop.dx) / 2, leftTop.dy);
  }

  Offset getBottomMid() {
    return Offset((leftBottom.dx + rightBottom.dx) / 2, leftTop.dy);
  }

  Offset getLeftMid() {
    return Offset(leftTop.dx, (leftTop.dy + leftBottom.dy) / 2);
  }

  Offset getRightMid() {
    return Offset(rightTop.dx, (rightTop.dy + rightBottom.dy) / 2);
  }

  double getWidth() {
    return rightTop.dx - leftTop.dx;
  }

  double getHeight() {
    return rightBottom.dy - rightTop.dy;
  }

  void setInvisible() {
    visible = false;
  }
}
