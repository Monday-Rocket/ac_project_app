// ignore_for_file: avoid_positional_boolean_parameters

import 'package:flutter/material.dart';

class WidgetOffset {
  WidgetOffset(
    this.leftTop,
    this.rightTop,
    this.leftBottom,
    this.rightBottom,
    this.visible,
  );

  final Offset leftTop;
  final Offset rightTop;
  final Offset leftBottom;
  final Offset rightBottom;
  bool visible;

  Offset getTopMid() {
    return Offset((leftTop.dx + rightTop.dx) / 2, leftTop.dy);
  }
}
