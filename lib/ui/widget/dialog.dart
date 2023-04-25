import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/gen/fonts.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showPopUp({
  required String title,
  required String content,
  required BuildContext parentContext,
  required void Function()? callback,
  bool icon = false,
  String buttonText = '확인',
  Widget iconImage = const Icon(
    Icons.error,
    color: primary800,
    size: 27,
  ),
  bool hasClose = false,
}) {
  final width = MediaQuery.of(parentContext).size.width;
  showDialog<dynamic>(
    context: parentContext,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: width - (45.w * 2),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: icon ? 26.h : 16.h,
                    ),
                    if (icon) iconImage,
                    Container(
                      margin: EdgeInsets.only(top: icon ? 14.h : 0, bottom: 10.h.h),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: FontFamily.pretendard,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2.w,
                          height: (23.8 / 20).h,
                        ),
                      ),
                    ),
                    Text(
                      content,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: grey500,
                        fontSize: 14.sp,
                        letterSpacing: -0.1.w,
                        fontWeight: FontWeight.w500,
                        height: (18.9 / 14).h,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(
                        left: 4.w,
                        right: 4.w,
                        bottom: 4.h,
                        top: 32.h,
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton(
                          onPressed: callback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            shadowColor: Colors.transparent,
                          ),
                          child: Text(
                            buttonText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasClose)
                Positioned(
                  right: 5.w,
                  top: 5.h,
                  child: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close,
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
        ),
      );
    },
  );
}

void showMyPageDialog({
  required String title,
  required String content,
  required BuildContext parentContext,
  required String leftText,
  required String rightText,
  required void Function()? leftCallback,
  required void Function()? rightCallback,
  bool icon = false,
}) {
  final width = MediaQuery.of(parentContext).size.width;
  showDialog<dynamic>(
    context: parentContext,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.zero,
        alignment: Alignment.center,
        child: SizedBox(
          width: width - (45.w * 2),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: icon ? 14 : 16,
                    ),
                    if (icon)
                      const Icon(
                        Icons.error,
                        color: grey800,
                        size: 27,
                      ),
                    Container(
                      margin: EdgeInsets.only(top: icon ? 7 : 0, bottom: 10.h),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: FontFamily.pretendard,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      content,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: grey500,
                        fontSize: 14.sp,
                        letterSpacing: -0.1.w,
                        fontWeight: FontWeight.w500,
                        height: (16.7 / 14).h,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(
                        left: 4.w,
                        right: 4.w,
                        bottom: 4.h,
                        top: 32.h,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 48.h,
                              child: ElevatedButton(
                                onPressed: leftCallback,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: grey200,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  shadowColor: Colors.transparent,
                                ),
                                child: Text(
                                  leftText,
                                  style: TextStyle(
                                    color: grey800,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 7.w),
                          Expanded(
                            child: SizedBox(
                              height: 48.h,
                              child: ElevatedButton(
                                onPressed: rightCallback,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: grey800,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  shadowColor: Colors.transparent,
                                ),
                                child: Text(
                                  rightText,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 5.w,
                top: 5.h,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.close,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showError(BuildContext context) {
  showPopUp(
    title: '서버 에러',
    content: '서버 통신 오류',
    parentContext: context,
    callback: () => Navigator.pop(context),
    icon: true,
  );
}
