import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/get_user_folders_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/profile/profile_image.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget UserInfoWidget({
  required BuildContext context,
  required Link link,
  bool? jobVisible = true,
}) {
  return GestureDetector(
    onTap: () async {
      final profileInfoCubit = getIt<GetProfileInfoCubit>();
      final userFoldersCubit = getIt<GetUserFoldersCubit>();

      final isMine =
          (profileInfoCubit.state as ProfileLoadedState).profile.id ==
              link.user!.id;

      await userFoldersCubit.getFolders(link.user!.id!).then((_) {
        Navigator.of(context).pushNamed(
          Routes.userFeed,
          arguments: {
            'user': link.user,
            'folders': userFoldersCubit.state.folderList,
            'isMine': isMine,
          },
        );
      });
    },
    child: Row(
      children: [
        Image.asset(
          ProfileImage.makeImagePath(link.user?.profile_img ?? '01'),
          width: 32.w,
          height: 32.h,
          errorBuilder: (_, __, ___) {
            return Container(
              width: 32.w,
              height: 32.h,
              decoration: const BoxDecoration(
                color: grey300,
                shape: BoxShape.circle,
              ),
            );
          },
        ),
        SizedBox(
          width: 8.w,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  link.user?.nickname ?? '',
                  style: const TextStyle(
                    color: grey900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (jobVisible ?? true) _UserJobView(link),
              ],
            ),
            Container(
              margin: EdgeInsets.only(top: 4.h),
              child: Text(
                makeLinkTimeString(link.time ?? ''),
                style: TextStyle(
                  color: grey400,
                  fontSize: 12.sp,
                  letterSpacing: -0.2.w,
                ),
              ),
            ),
          ],
        )
      ],
    ),
  );
}

Container _UserJobView(Link link) {
  return Container(
    margin: EdgeInsets.only(
      left: 4.w,
    ),
    decoration: BoxDecoration(
      color: primary66_200,
      borderRadius: BorderRadius.all(
        Radius.circular(4.r),
      ),
    ),
    child: Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: 3.h,
          horizontal: 4.w,
        ),
        child: Text(
          link.user?.jobGroup?.name ?? '',
          style: TextStyle(
            color: primary600,
            fontSize: 10.sp,
            letterSpacing: -0.2.w,
          ),
        ),
      ),
    ),
  );
}
