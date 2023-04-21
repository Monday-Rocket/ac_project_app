import 'package:ac_project_app/cubits/profile/profile_images_cubit.dart';
import 'package:ac_project_app/models/profile/profile.dart';
import 'package:ac_project_app/ui/view/user/change_profile_view.dart';
import 'package:ac_project_app/util/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cubit = GetProfileImagesCubit();

  final testWidget = MaterialApp(
    home: ScreenUtilInit(
      designSize: const Size(393, 852),
      builder: (BuildContext context, Widget? child) {
        return ProfileSelectView(
          profile: Profile(nickname: '오키', profileImage: makeImagePath('02')),
          imageList: cubit.initList,
        );
      },
    ),
  );

  testWidgets('프로필 이미지가 불러와지는 지 테스트', (tester) async {
    await tester.pumpWidget(testWidget);

    // key를 통해 이미지를 찾아서
    const imagePath = 'assets/images/profile/img_02_on.png';

    final actual = find.image(Image.asset(imagePath).image);
    expect(actual, findsWidgets);
  });

  // TODO 프로필 바꾸는 테스트 추가
}
