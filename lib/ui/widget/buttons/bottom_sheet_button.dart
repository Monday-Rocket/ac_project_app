// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:io';

import 'package:ac_project_app/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget buildBottomSheetButton({
  required BuildContext context,
  required String text,
  bool? keyboardVisible,
  void Function()? onPressed,
  bool? buttonShadow = true,
  Color? backgroundColor,
}) {
  return SafeArea(
    child: Padding(
      padding: EdgeInsets.only(
        bottom: getBottomPadding(context, keyboardVisible),
        left: 24.w,
        right: 24.w,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: Size.fromHeight(55.h),
          backgroundColor: backgroundColor ?? primary800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          disabledBackgroundColor: secondary,
          disabledForegroundColor: Colors.white,
          shadowColor: buttonShadow! ? primary600 : Colors.transparent,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          textWidthBasis: TextWidthBasis.parent,
        ),
      ),
    ),
  );
}

double getBottomPadding(BuildContext context, bool? keyboardVisible) {
  final defaultValue = Platform.isAndroid ? 16.h : 8.h;
  final keyboardPadding = (keyboardVisible ?? false) ? 16.h : defaultValue;

  return MediaQuery.of(context).viewInsets.bottom + keyboardPadding;
}
