import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/profile/profile_images_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_state.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/profile/profile.dart';
import 'package:ac_project_app/models/profile/profile_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChangeProfileView extends StatelessWidget {
  const ChangeProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => GetProfileImagesCubit(),
        ),
        BlocProvider(
          create: (_) => GetProfileInfoCubit(),
        ),
      ],
      child: BlocBuilder<GetProfileInfoCubit, ProfileState>(
        builder: (context, state) {
          Profile? profile;
          if (state is ProfileLoadedState) {
            profile = state.profile;
          } else {
            profile = null;
          }
          return TotalSelectView(profile);
        },
      ),
    );
  }
}


Widget TotalSelectView(Profile? profile) {
  return BlocBuilder<GetProfileImagesCubit, List<ProfileImage>>(
    builder: (context, imageList) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context),
        body: SafeArea(
          child: profile != null ? ProfileSelectView(
            profile: profile,
            imageList: imageList,
            onSelectCallback: (index) {
              context.read<GetProfileImagesCubit>().select(index);
              context.read<GetProfileInfoCubit>().selectImage(index);
            },
            onChangeProfile: _onChangeProfile(context),
          ) : const SizedBox.shrink(),
        ),
      );
    },
  );
}



AppBar _buildAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0.5,
    shadowColor: grey100,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    leading: IconButton(
      icon: SvgPicture.asset(Assets.images.icBack),
      onPressed: () => Navigator.pop(context),
      padding: EdgeInsets.only(left: 20.w, right: 8.w),
    ),
    title: Text(
      '프로필 변경',
      style: TextStyle(
        color: grey900,
        fontWeight: FontWeight.bold,
        fontSize: 19.sp,
      ),
    ),
    actions: [
      TextButton(
        onPressed: context.watch<GetProfileImagesCubit>().selected
            ? () =>
            context.read<GetProfileInfoCubit>().updateProfileImage().then(
                  (value) => Navigator.pop(context, value),
            )
            : null,
        style: TextButton.styleFrom(
          disabledForegroundColor: grey400,
          foregroundColor: grey800,
        ),
        child: Text(
          '완료',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16.sp),
        ),
      )
    ],
  );
}


void Function()? _onChangeProfile(BuildContext context) {
  return context.read<GetProfileImagesCubit>().selected == true
      ? () => context.read<GetProfileInfoCubit>().updateProfileImage().then(
        (value) => Navigator.pop(context, value),
  )
      : null;
}

Column ProfileSelectView({
  required Profile profile,
  required List<ProfileImage> imageList,
  void Function(int)? onSelectCallback,
  void Function()? onChangeProfile,
}) {
  return Column(
    children: [
      Center(
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 30.h),
          child: Builder(
            builder: (_) {
              if (profile.nickname.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  Image.asset(
                    key: Key('selected:${profile.profileImage}'),
                    profile.profileImage,
                    width: 99.w,
                    height: 99.h,
                  ),
                  SizedBox(
                    height: 11.h,
                  ),
                  Text(
                    profile.nickname,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28.sp,
                      color: black1000,
                    ),
                  ),
                  SizedBox(
                    height: 8.h,
                  ),
                  Text(
                    '변경할 프로필 이미지를 선택해 주세요',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: grey500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      Expanded(
        child: ColoredBox(
          color: grey100,
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                  ),
                  itemCount: imageList.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      key: Key('select:$index'),
                      onTap: () {
                        onSelectCallback?.call(index);
                      },
                      child: Builder(
                        builder: (context) {
                          final profile = imageList[index];
                          if (profile.visible ?? false) {
                            return Image.asset(
                              key: Key('select:${profile.filePath}'),
                              profile.filePath,
                            );
                          }
                          return ColorFiltered(
                            colorFilter: const ColorFilter.mode(
                              Color(0x60FFFFFF),
                              BlendMode.modulate,
                            ),
                            child: Image.asset(
                              profile.filePath,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.only(
                  left: 24.w,
                  right: 24.w,
                  bottom: 8.h,
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.fromHeight(55.h),
                    backgroundColor: primary600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    disabledBackgroundColor: secondary,
                    disabledForegroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: onChangeProfile,
                  child: Text(
                    '변경하기',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textWidthBasis: TextWidthBasis.parent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
