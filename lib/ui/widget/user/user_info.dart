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

      if (profileInfoCubit.state is! ProfileLoadedState) {
        await profileInfoCubit.loadProfileData();
      }

      final isMine = (profileInfoCubit.state as ProfileLoadedState).profile.id == link.user!.id;

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
          height: 32.w,
          errorBuilder: (_, __, ___) {
            return Container(
              width: 32.w,
              height: 32.w,
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
            Text(
              link.user?.nickname ?? '',
              style: TextStyle(
                color: grey900,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
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
        ),
      ],
    ),
  );
}
