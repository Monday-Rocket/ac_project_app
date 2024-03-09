import 'package:flutter/material.dart';

void popIfCan(BuildContext? context) {
  if (context == null) return;
  final navigator = Navigator.maybeOf(context);
  final canPop = navigator != null && navigator.canPop();
  if (canPop) {
    navigator.pop();
  }
}
