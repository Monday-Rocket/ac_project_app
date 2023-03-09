import 'package:ac_project_app/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Text buildSubTitle(String text) {
  return Text(
    text,
    style: TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 16.sp,
      height: (19 / 16).h,
      letterSpacing: -0.3.w,
      color: grey800,
    ),
  );
}
