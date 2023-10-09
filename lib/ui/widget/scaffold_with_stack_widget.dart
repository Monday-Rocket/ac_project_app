import 'package:flutter/material.dart';

class ScaffoldWithStackWidget extends StatelessWidget {
  const ScaffoldWithStackWidget({
    required this.scaffold,
    required this.widget,
    super.key,
  });

  final Scaffold scaffold;
  final Widget widget;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [scaffold, widget],
    );
  }
}
