import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/profile/profile_image.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 오프라인 모드: 다른 사용자 피드 이동 기능 비활성화
/// 단순히 사용자 정보만 표시
Widget UserInfoWidget({
  required BuildContext context,
  required Link link,
  bool? jobVisible = true,
}) {
  return Row(
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
            margin: EdgeInsets.only(top: 4.w),
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
  );
}
