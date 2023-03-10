import 'package:ac_project_app/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showBottomToast(
  String text, {
  double? bottomPadding,
  BuildContext? context,
  void Function()? callback,
  String? subMsg,
  String actionTitle = '확인하기',
}) {
  ScaffoldMessenger.of(context!).showSnackBar(
    SnackBar(
      margin: EdgeInsets.only(
        left: 21.w,
        right: 21.w,
        bottom: bottomPadding?.h ?? 11.h,
        top: bottomPadding?.h ?? 11.h,
      ),
      content: subMsg == null
          ? Row(
              mainAxisAlignment: callback == null
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Text(text),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 13.sp,
                    height: (16 / 13).h,
                    letterSpacing: -0.1.w,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  subMsg,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: grey400,
                    fontSize: 13.sp,
                    letterSpacing: -0.1.w,
                    height: (16 / 13).h,
                  ),
                ),
              ],
            ),
      backgroundColor: grey900,
      duration: const Duration(milliseconds: 2000),
      behavior: SnackBarBehavior.floating,
      action: (callback == null)
          ? null
          : SnackBarAction(
              label: actionTitle,
              textColor: Colors.white,
              onPressed: callback,
            ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.r),
      ),
    ),
  );
}
