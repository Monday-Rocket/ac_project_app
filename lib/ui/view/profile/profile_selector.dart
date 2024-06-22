import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/profile/profile.dart';
import 'package:ac_project_app/models/profile/profile_image.dart';
import 'package:ac_project_app/provider/profile_images.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileSelector extends StatefulWidget {
  const ProfileSelector({
    required this.profile,
    this.onChangeProfile,
    super.key,
  });

  final Profile profile;
  final void Function(String)? onChangeProfile;

  @override
  State<ProfileSelector> createState() => _ProfileSelectorState();
}

class _ProfileSelectorState extends State<ProfileSelector> {
  late Profile profile;
  late final List<ProfileImage> imageList;
  late int selectedImageIndex;

  @override
  void initState() {
    profile = widget.profile;
    imageList = getProfileImages();
    selectedImageIndex = int.parse(profile.profileImage) - 1;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          children: [
            SelectedProfileImage(),
            SelectableProfileImages(),
          ],
        ),
      ),
    );
  }

  Expanded SelectableProfileImages() {
    return Expanded(
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
                      setState(() {
                        imageList[selectedImageIndex].visible = false;
                        imageList[index].visible = true;
                        selectedImageIndex = index;
                      });
                    },
                    child: Builder(
                      builder: (context) {
                        final profile = imageList[index];
                        if (profile.visible ?? false) {
                          return _SelectableProfileImage(profile);
                        }
                        return ColorFiltered(
                          colorFilter: const ColorFilter.mode(
                            Color(0x60FFFFFF),
                            BlendMode.modulate,
                          ),
                          child: _SelectableProfileImage(profile),
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
                onPressed: () =>
                    widget.onChangeProfile?.call(_getImageNumberString()),
                child: Text(
                  '변경하기',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textWidthBasis: TextWidthBasis.parent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Center SelectedProfileImage() {
    return Center(
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
                  key: const Key('selectedImage'),
                  ProfileImage.makeImagePath(_getImageNumberString()),
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
          onPressed: () => context
              .read<GetProfileInfoCubit>()
              .updateProfileImage(_getImageNumberString())
              .then(
                (value) => Navigator.pop(context, value),
              ),
          style: TextButton.styleFrom(
            disabledForegroundColor: grey400,
            foregroundColor: grey800,
          ),
          child: Text(
            '완료',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16.sp),
          ),
        ),
      ],
    );
  }

  String _getImageNumberString() => '${selectedImageIndex + 1}'.padLeft(2, '0');

  Image _SelectableProfileImage(ProfileImage profile) {
    return Image.asset(
      key: Key('select:${profile.filePath}'),
      profile.filePath,
    );
  }
}
