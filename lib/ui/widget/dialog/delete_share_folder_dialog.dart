import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/provider/share_db.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/text/custom_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

void deleteShareFolderDialog(
  BuildContext context,
  Folder folder, {
  void Function()? callback,
}) {
  showDialog<bool?>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(
              Radius.circular(16.w),
            ),
          ),
          width: 285.w,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close_rounded,
                      size: 24.w,
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 2.w, bottom: 10.w),
                  child: Text(
                    '공유폴더를 나가시겠어요?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20.sp,
                      color: grey900,
                      letterSpacing: -0.2.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  '내 폴더에 있는 공유폴더와\n저장한 링크가 사라져요',
                  style: TextStyle(
                    color: grey500,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    height: 19 / 14,
                    letterSpacing: -0.1.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                Container(
                  margin: EdgeInsets.only(
                    top: 33.w,
                    bottom: 6.w,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 120.w,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            decoration: BoxDecoration(
                              color: grey100,
                              borderRadius: BorderRadius.circular(8.w),
                            ),
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 14.w),
                            child: Center(
                              child: Text(
                                '취소',
                                style: TextStyle(color: grey500, fontWeight: FontWeight.bold, fontSize: 16.sp, height: 19 / 16),
                              ).bold(),
                            ),
                          ),
                        ),
                      ),
                      7.horizontalSpace,
                      SizedBox(
                        width: 120.w,
                        child: GestureDetector(
                          onTap: () => getIt<FolderApi>().deleteFolder(folder).then((result) {
                            Navigator.pop(context, true);
                            if (result) {
                              showBottomToast(context: context, '폴더 나가기를 완료했어요');
                            }
                            callback?.call();
                          }),
                          child: Container(
                            decoration: BoxDecoration(
                              color: primary600,
                              borderRadius: BorderRadius.circular(8.w),
                            ),
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 14.w),
                            child: Center(
                              child: Text(
                                '나가기',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp, height: 19 / 16),
                              ).bold(),
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
        ),
      );
    },
  );
}

void deleteSharedFolderAdminDialog(BuildContext context, Folder folder, {void Function()? callback}) {
  showDialog<bool?>(
    context: context,
    builder: (ctx) {
      var isChecked = false;
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.only(
                top: 40,
                left: 20.w,
                right: 20.w,
                bottom: 31.w,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(
                  Radius.circular(16.w),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 2.w, bottom: 10.w),
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
                    '삭제 시 함께 공유하던 멤버들이\n폴더 내 링크를 볼 수 없어요',
                    style: TextStyle(
                      color: grey500,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  28.verticalSpace,
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, Routes.delegateAdmin, arguments: folder.id);
                    },
                    child: Container(
                      height: 19,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '다른 멤버에게 방장 권한을 위임할 수도 있어요',
                            style: TextStyle(
                              color: grey400,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2.sp,
                            ),
                          ),
                          3.horizontalSpace,
                          SvgPicture.asset(Assets.images.smallRightArrow)
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(
                      top: 16.w,
                      left: 6.w,
                      right: 6.w,
                      bottom: 14.w,
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          minimumSize: Size.fromHeight(48.w),
                          backgroundColor: primary600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.w),
                          ),
                          disabledBackgroundColor: secondary),
                      onPressed: isChecked
                          ? () async {
                              final result = await getIt<FolderApi>().deleteFolder(folder);
                              await ShareDB.deleteFolder(folder);
                              Navigator.pop(context, true);
                              if (result) {
                                showBottomToast(context: context, '폴더 삭제를 완료했어요');
                              }
                              callback?.call();
                            }
                          : null,
                      child: Text(
                        '삭제하기',
                        style: TextStyle(color: Colors.white, fontSize: 16.sp),
                      ).bold(),
                    ),
                  ),
                  14.verticalSpace,
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isChecked = !isChecked;
                      });
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isChecked ? primary800 : grey100,
                              borderRadius: BorderRadius.all(
                                Radius.circular(6.w),
                              ),
                              border: Border.all(
                                width: 0,
                                color: Colors.transparent,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(2.w),
                              child: isChecked
                                  ? Icon(
                                      Icons.check,
                                      size: 18.w,
                                      color: Colors.white,
                                    )
                                  : Icon(
                                      Icons.check,
                                      size: 18.w,
                                      color: grey300,
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          '위 내용을 모두 확인했습니다.',
                          style: TextStyle(
                            color: grey500,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.1.sp,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void delegateFolder(BuildContext context, String nickname, {required void Function() callback}) {
  showDialog<bool?>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.only(
            top: 14,
            left: 20.w,
            right: 14.w,
            bottom: 20.w,
          ),
          width: 285.w,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(
              Radius.circular(16.w),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.close_rounded,
                    size: 24.w,
                  ),
                ),
              ),
              2.verticalSpace,
              Container(
                margin: EdgeInsets.only(top: 2.w),
                child: Text(
                  '`${nickname}`님에게 방장\n권한을 위임하시겠어요?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20.sp,
                    color: grey900,
                    letterSpacing: -0.2.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              33.verticalSpace,
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: Size.fromHeight(48.w),
                    backgroundColor: primary600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.w),
                    ),
                    disabledBackgroundColor: secondary),
                onPressed: callback,
                child: Text(
                  '위임하기',
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                ).bold(),
              ),
            ],
          ),
        ),
      );
    },
  );
}
