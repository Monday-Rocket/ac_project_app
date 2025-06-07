import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/folders/delegate_admin_cubit.dart';
import 'package:ac_project_app/cubits/folders/folder_users_state.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/profile/profile_image.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/ui/widget/bottom_toast.dart';
import 'package:ac_project_app/ui/widget/dialog/delete_share_folder_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class DelegateAdminView extends StatelessWidget {
  const DelegateAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    var args = ModalRoute.of(context)?.settings.arguments;
    final folderId = args is int ? args : null;

    return BlocProvider(
      create: (context) => DelegateAdminCubit(folderId),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: CustomScrollView(
          slivers: [
            buildTopAppBar(context),
            SliverToBoxAdapter(
              child: BlocBuilder<DelegateAdminCubit, FolderUsersState>(
                builder: (cubitContext, state) {
                  switch (state.runtimeType) {
                    case FolderUsersLoadingState:
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    case FolderUsersLoadedState:
                      final loadedState = state as FolderUsersLoadedState;
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${loadedState.totalUsersCount}명의 멤버',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                height: 14 / 12,
                                color: grey500,
                                letterSpacing: -0.1.sp,
                              ),
                            ),
                            16.verticalSpace,
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: loadedState.normalUsers.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return AdminListItem(loadedState);
                                }
                                final user = loadedState.normalUsers[index-1];

                                return Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            profileImage(user),
                                            16.horizontalSpace,
                                            Text(
                                              user.nickname,
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w500,
                                                height: 17 / 16,
                                                color: grey800,
                                                letterSpacing: -0.2.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                        GestureDetector(
                                          onTap: () async {
                                            delegateFolder(context, user.nickname, callback: () async {
                                              final result = await context.read<DelegateAdminCubit>().delegateAdmin(folderId, user.id);
                                              if (result) {
                                                Navigator.pop(context);
                                                Navigator.pop(context);
                                                Navigator.pop(context);
                                                showBottomToast('방장 권한을 위임했어요', context: context);
                                              } else {
                                                showBottomToast('위임에 실패했습니다. 다시 시도해주세요.', context: context);
                                              }
                                            });
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: grey100,
                                              borderRadius: BorderRadius.circular(6.w),
                                            ),
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 14.w,
                                              vertical: 7.w,
                                            ),
                                            child: Text(
                                              '위임하기',
                                              style: TextStyle(
                                                color: grey600,
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w600,
                                                height: 17 / 14,
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                    if (index < loadedState.normalUsers.length)
                                      horizontalDivider()
                                    else
                                      const SafeArea(
                                        top: false,
                                        child: SizedBox.shrink(),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    case FolderUsersErrorState:
                      final errorState = state as FolderUsersErrorState;
                      return Center(
                        child: Text(errorState.message ?? '오류가 발생했습니다.'),
                      );
                    default:
                      return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget AdminListItem(FolderUsersLoadedState loadedState) {
    return Column(
      children: [
        Row(
          children: [
            profileImage(loadedState.admin),
            16.horizontalSpace,
            Assets.images.lavelCrown.image(),
            6.horizontalSpace,
            Text(
              loadedState.admin.nickname,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                height: 17 / 16,
                color: grey800,
                letterSpacing: -0.2.sp,
              ),
            ),
            Container(
              color: grey200,
              width: 1,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 6),
            ),
            Text(
              '폴더 관리자',
              style: TextStyle(
                color: grey400,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                height: 17 / 14,
                letterSpacing: -0.2.sp,
              ),
            ),
          ],
        ),
        horizontalDivider(),
      ],
    );
  }

  // horizontal divider
  Widget horizontalDivider() {
    return Container(
      height: 1,
      color: grey100,
      margin: EdgeInsets.symmetric(vertical: 16.w),
    );
  }

  Image profileImage(DetailUser user) {
    return Image.asset(
      ProfileImage.makeImagePath(user.profile_img),
      width: 48.w,
      height: 48.w,
      errorBuilder: (_, __, ___) {
        return Container(
          width: 48.w,
          height: 48.w,
          decoration: const BoxDecoration(
            color: grey300,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget buildTopAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: SvgPicture.asset(
          Assets.images.icBack,
          width: 24.w,
          height: 24.w,
          fit: BoxFit.cover,
        ),
        color: grey900,
        padding: EdgeInsets.only(left: 20.w, right: 8.w),
      ),
      leadingWidth: 44.w,
      toolbarHeight: 48.w,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: Colors.transparent,
        ),
      ),
      centerTitle: true,
      title: Text(
        '위임하기',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 19.sp,
          letterSpacing: -0.3.sp,
        ),
      ),
      elevation: 0,
      backgroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    );
  }
}
