import 'package:ac_project_app/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showBottomToast(
  String text, {
  double? bottomPadding,
  BuildContext? context,
  int duration = 4000,
  void Function()? callback,
  String? subMsg,
  String actionTitle = '확인하기',
}) {
  if (context == null) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      margin: EdgeInsets.only(
        left: 21.w,
        right: 21.w,
        bottom: bottomPadding?.h ?? 11.w,
        top: bottomPadding?.h ?? 11.w,
      ),
      content: subMsg == null
          ? Row(
              mainAxisAlignment: callback == null ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(fontSize: 13.sp, height: 16 / 13, letterSpacing: -0.1.w, fontWeight: FontWeight.w600),
                ),
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
                    height: 16 / 13,
                    letterSpacing: -0.1.w,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6.w),
                Text(
                  subMsg,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    color: grey400,
                    fontSize: 13.sp,
                    letterSpacing: -0.1.w,
                    height: 16 / 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
      backgroundColor: grey900,
      duration: Duration(milliseconds: duration),
      behavior: SnackBarBehavior.floating,
      action: (callback == null)
          ? null
          : SnackBarAction(
              label: actionTitle,
              textColor: Colors.white,
              onPressed: callback,
            ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.w),
      ),
    ),
  );
}
