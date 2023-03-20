import 'package:flutter/material.dart';

class ScaffoldWithToolTip extends StatelessWidget {

  const ScaffoldWithToolTip({super.key, required this.scaffold, required this.tooltip});

  final Scaffold scaffold;
  final Widget tooltip;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        scaffold,
        tooltip
      ],
    );
  }
}
