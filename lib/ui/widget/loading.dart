// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

Widget LoadingWidget({double width = 60, double height = 60}) {
  return SizedBox(
    width: width,
    height: height,
    child: Lottie.asset(
      'assets/animations/loading.json',
      frameRate: FrameRate(60),
    ),
  );
}

Widget BottomLoadingWidget({double width = 30, double height = 30}) {
  return SizedBox(
    height: 30 + 30 + 50,
    child: Padding(
      padding: const EdgeInsets.only(top: 30),
      child: LoadingWidget(
        width: 30,
        height: 30,
      ),
    ),
  );
}
