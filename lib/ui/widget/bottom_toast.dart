import 'package:ac_project_app/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

void showBottomToast(String text, {double? bottomPadding}) {
  showToastWidget(
    Container(
      margin:
      EdgeInsets.only(left: 24, right: 24, bottom: bottomPadding ?? 100),
      width: double.infinity,
      height: 38,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(6)),
        color: grey900,
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
            height: 15.5 / 13,
            letterSpacing: -0.1,
          ),
        ),
      ),
    ),
    position: const ToastPosition(align: Alignment.bottomCenter),
    animationCurve: Curves.ease,
    animationDuration: Duration.zero,
  );
}
