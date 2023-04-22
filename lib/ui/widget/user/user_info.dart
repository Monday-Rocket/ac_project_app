import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/get_user_folders_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/profile/profile_image.dart';
import 'package:ac_project_app/routes.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget buildUserInfo({
  required BuildContext context,
  required Link link,
  bool? jobVisible = true,
}) {
  return GestureDetector(
    onTap: () async {
      final profileState =
          context.read<GetProfileInfoCubit>().state as ProfileLoadedState;
      await Navigator.of(context).pushNamed(
        Routes.userFeed,
        arguments: {
          'user': link.user,
          'folders': await context
              .read<GetUserFoldersCubit>()
              .getFolders(link.user!.id!),
          'isMine': profileState.profile.id == link.user!.id,
        },
      );
    },
    child: Row(
      children: [
        Image.asset(
          ProfileImage.makeImagePath(link.user?.profileImg ?? '01'),
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
                if (jobVisible ?? true) _buildUserJobView(link),
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

Container _buildUserJobView(Link link) {
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
