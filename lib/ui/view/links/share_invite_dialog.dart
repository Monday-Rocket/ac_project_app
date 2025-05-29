import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/provider/api/folders/share_folder_api.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/text/custom_font.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showInviteDialog(BuildContext context, int? folderId) {
  showDialog<bool?>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(
              Radius.circular(16.w),
            ),
          ),
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
                    '멤버를 초대하시겠어요?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20.sp,
                      color: grey900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  '초대에 수락한 멤버와 함께\n링크를 모을 수 있어요',
                  style: TextStyle(
                    color: grey500,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    height: 19 / 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                9.verticalSpace,
                Assets.images.paperPlane.image(),
                20.verticalSpace,
                Container(
                  margin: EdgeInsets.only(
                    left: 6.w,
                    right: 6.w,
                    bottom: 6.w,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size.fromHeight(48.w),
                      backgroundColor: primary600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.w),
                      ),
                    ),
                    onPressed: () {
                      getIt<ShareFolderApi>().generateInviteToken(folderId).then((result) {
                        result.when(
                          success: (inviteLink) {
                            final profileInfoCubit = getIt<GetProfileInfoCubit>();
                            final state = profileInfoCubit.state;
                            var nickname = '링크풀';
                            if (state is ProfileLoadedState) {
                              nickname = state.profile.nickname;
                            }

                            Clipboard.setData(ClipboardData(text: 'https://monday-rocket.github.io/linkpool-invite-page?nickname=$nickname&id=$folderId&token=${inviteLink.invite_token}'));
                            showBottomToast(
                              context: context,
                              '링크 복사완료! 링크로 멤버를 초대해보세요',
                            );
                            Navigator.pop(context);
                          },
                          error: (msg) {
                            showBottomToast(
                              context: context,
                              '링크 생성에 실패했습니다. 다시 시도해주세요.',
                            );
                            Navigator.pop(context);
                          },
                        );
                      });
                    },
                    child: Text(
                      '링크 복사하기',
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
  ).then((bool? value) {});
}
