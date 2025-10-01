import 'dart:math';

import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/profile/profile_image.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget ParticipantsProfile(int membersCount, {double scale = 1.0, double fontSize = 10}) {
  if (membersCount <= 0) {
    return const SizedBox.shrink();
  }
  final profileImageNumberList = _getProfileImageList(membersCount);
  final profileCount = profileImageNumberList.length;
  final displayCount = min(profileCount, 2);  // 2개냐 3개냐
  final width = (displayCount * 17.w) + 26.w * scale;
  Log.i('width: $width membersCount: $membersCount');
  return Container(
    margin: EdgeInsets.only(left: 8.w),
    child: SizedBox(
      width: width,
      height: 26.w * scale,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 프로필 이미지들
          for (int index = 0; index < displayCount; index++)
            Positioned(
              left: index * 17.w * scale,
              child: CircleAvatar(
                radius: 13.w * scale,
                backgroundColor: grey100,
                child: Image.asset(
                  ProfileImage.makeImagePath(profileImageNumberList[index]),
                  width: 25.w * scale,
                  height: 25.w * scale,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Assets.images.profile.img01On.image(
                      width: 25.w * scale,
                      height: 25.w * scale,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),
          // +N 표시
          if (membersCount > 2)
            Positioned(
              left: 34.w * scale,
              child: CircleAvatar(
                radius: 13.w * scale,
                backgroundColor: grey100,
                child: Container(
                  width: 24 * scale,
                  height: 24 * scale,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: grey700,
                  ),
                  child: Center(
                    child: Text(
                      '+${membersCount - 2}',
                      style: TextStyle(
                        color: grey50,
                        fontSize: fontSize.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

List<String> _getProfileImageList(int membersCount) {
  final profileImageNumberList = <String>[];
  for (var attempts = 0; attempts < membersCount && profileImageNumberList.length < 2; attempts++) {
    final randomNumber = Random().nextInt(9) + 1;
    final formattedNumber = randomNumber.toString().padLeft(2, '0');
    if (!profileImageNumberList.contains(formattedNumber)) {
      profileImageNumberList.add(formattedNumber);
    }
  }
  return profileImageNumberList;
}
