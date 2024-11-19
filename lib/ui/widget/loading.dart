// ignore_for_file: non_constant_identifier_names

import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

Widget LoadingWidget({double width = 60, double height = 60}) {
  return SizedBox(
    width: width.w,
    height: height.w,
    child: Lottie.asset(
      Assets.animations.loading,
      frameRate: const FrameRate(60),
    ),
  );
}

Widget BottomLoadingWidget({double width = 30, double height = 30}) {
  return SizedBox(
    height: 110.w,
    child: Padding(
      padding: EdgeInsets.only(top: 30.w),
      child: LoadingWidget(
        width: width.w,
        height: height.w,
      ),
    ),
  );
}
