// ignore_for_file: avoid_positional_boolean_parameters

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
  Key? key,
}) {
  return Padding(
    padding: EdgeInsets.only(
      bottom: getBottomPadding(context, keyboardVisible),
      left: 24.w,
      right: 24.w,
    ),
    child: ElevatedButton(
      key: key,
      style: ElevatedButton.styleFrom(
        minimumSize: Size.fromHeight(55.h),
        backgroundColor: backgroundColor ?? primary800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        foregroundColor: Colors.white,
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
          color: Colors.white,
        ),
        textWidthBasis: TextWidthBasis.parent,
      ),
    ),
  );
}

double getBottomPadding(BuildContext context, bool? keyboardVisible) {
  final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
  final keyboardPadding = keyboardHeight + 8.h;

  return MediaQuery.of(context).padding.bottom + keyboardPadding;
}
