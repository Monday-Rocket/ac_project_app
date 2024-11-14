import 'package:ac_project_app/const/colors.dart';
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

AppBar buildBackAppBar(BuildContext context, {void Function()? callback}) {
  return AppBar(
    leading: IconButton(
      onPressed: () {
        if (callback != null) {
          callback.call();
        } else {
          Navigator.pop(context);
        }
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
    backgroundColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  );
}
