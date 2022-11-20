import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/profile/get_profile_images_cubit.dart';
import 'package:ac_project_app/cubits/profile/get_profile_info_cubit.dart';
import 'package:ac_project_app/models/profile/profile.dart';
import 'package:ac_project_app/models/profile/profile_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      child: BlocBuilder<GetProfileImagesCubit, List<ProfileImage>>(
        builder: (context, imageList) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              shadowColor: grey100,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: grey900,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                '프로필 변경',
                style: TextStyle(
                  color: grey900,
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: context.watch<GetProfileImagesCubit>().selected
                      ? () {}
                      : null,
                  style: TextButton.styleFrom(
                    disabledForegroundColor: grey400,
                    foregroundColor: grey800,
                  ),
                  child: const Text(
                    '완료',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                  ),
                )
              ],
            ),
            body: SafeArea(
              child: BlocBuilder<GetProfileInfoCubit, Profile>(
                builder: (context, profile) {
                  return Column(
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 30),
                          child: Builder(
                            builder: (_) {
                              if (profile.nickname.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                children: [
                                  Image.asset(
                                    profile.profileImage,
                                    width: 99,
                                    height: 99,
                                  ),
                                  const SizedBox(
                                    height: 11,
                                  ),
                                  Text(
                                    profile.nickname,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 28,
                                      color: black1000,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  const Text(
                                    '변경할 프로필 이미지를 선택해 주세요',
                                    style: TextStyle(
                                      fontSize: 14,
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
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                  ),
                                  itemCount: imageList.length,
                                  itemBuilder: (context, index) {
                                    return InkWell(
                                      onTap: () {
                                        context
                                            .read<GetProfileImagesCubit>()
                                            .select(index);
                                        context
                                            .read<GetProfileInfoCubit>()
                                            .selectImage(index);
                                      },
                                      child: Builder(
                                        builder: (context) {
                                          final profile = imageList[index];
                                          if (profile.visible ?? false) {
                                            return Image.asset(
                                              profile.filePath,
                                            );
                                          }
                                          return ColorFiltered(
                                            colorFilter: const ColorFilter.mode(
                                              Color(0x60FFFFFF),
                                              BlendMode.modulate,
                                            ),
                                            child:
                                                Image.asset(profile.filePath),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(55),
                                    backgroundColor: context
                                            .watch<GetProfileImagesCubit>()
                                            .selected
                                        ? primary600
                                        : secondary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    disabledBackgroundColor: secondary,
                                    disabledForegroundColor: Colors.white,
                                  ),
                                  onPressed: () {},
                                  child: const Text(
                                    '변경하기',
                                    style: TextStyle(
                                      fontSize: 16,
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
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
