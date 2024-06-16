import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/get_my_folders_cubit.dart';
import 'package:ac_project_app/gen/fonts.gen.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/text/custom_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  bool hasClose = true,
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
                      height: icon ? 10.h : 16.h,
                    ),
                    if (icon) iconImage,
                    Container(
                      margin: EdgeInsets.only(top: icon ? 14.h : 0, bottom: 10.h),
                      child: Text(
                        title,
                        style: TextStyle(
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
                              fontFamily: FontFamily.pretendard,
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

void showEmailPopUp({
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


void deleteFolderDialog(BuildContext context, Folder folder) {
  final width = MediaQuery.of(context).size.width;
  showDialog<bool?>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: Colors.transparent,
        content: Container(
          width: width - 45 * 2,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(
              Radius.circular(16.r),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close_rounded,
                      size: 24.r,
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 2.h, bottom: 10.h),
                  child: Text(
                    '폴더를 삭제하시겠어요?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20.sp,
                      color: grey900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  '폴더를 삭제하면, 폴더 안에 있는\n콘텐츠도 사라져요',
                  style: TextStyle(
                    color: grey500,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                Container(
                  margin: EdgeInsets.only(
                    top: 33.h,
                    left: 6.w,
                    right: 6.w,
                    bottom: 6.h,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.fromHeight(48.h),
                      backgroundColor: primary600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      final cubit = context.read<GetFoldersCubit>();
                      cubit.delete(folder).then((result) {
                        Navigator.pop(context, true);
                        cubit.getFolders();
                        if (result) {
                          showBottomToast(context: context, '폴더가 삭제되었어요!');
                        }
                      });
                    },
                    child: Text(
                      '삭제하기',
                      style: TextStyle(color: Colors.white, fontSize: 16.sp),
                    ).bold(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  ).then((bool? value) {
    Navigator.pop(context);
    if (value ?? false) {
      // 삭제 토스트가 두번뜨는 이슈 수정
      //showBottomToast(context:context,'폴더가 삭제되었어요!');
    }
  });
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
                                key: const Key('MyPageDialogLeftButtonKey'),
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
                                key: const Key('MyPageDialogRightButtonKey'),
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

void showPausePopup({
  required String title,
  required String description,
  required String timeText,
  required BuildContext parentContext,
  required void Function()? callback,
  bool icon = false,
  String buttonText = '확인',
  bool hasClose = true,
}) {
  final width = MediaQuery.of(parentContext).size.width;
  showDialog<dynamic>(
    context: parentContext,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: EdgeInsets.zero,
        child: SizedBox(
          width: width - (45.w * 2),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: icon ? 10.h : 16.h,
                    ),
                    Container(
                      margin: EdgeInsets.only(top: icon ? 14.h : 0, bottom: 10.h),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2.w,
                          height: (23.8 / 20).h,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: grey500,
                          fontSize: 14.sp,
                          letterSpacing: -0.1.w,
                          fontWeight: FontWeight.w500,
                          height: (18.9 / 14).h,
                        ),
                      ),
                    ),
                    12.verticalSpace,
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: grey200_9a,
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            '링크풀 서비스 점검시간\n$timeText',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: grey600,
                              fontSize: 14.sp,
                              letterSpacing: -0.1.w,
                              fontWeight: FontWeight.w600,
                              height: (20 / 14).h,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(
                        left: 4.w,
                        right: 4.w,
                        bottom: 4.h,
                        top: 24.h,
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
                              fontFamily: FontFamily.pretendard,
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
              Positioned(
                right: 0,
                top: 0,
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
