import 'package:ac_project_app/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

AppBar buildBackAppBar(BuildContext context) {
  return AppBar(
    leading: IconButton(
      onPressed: () {
        Navigator.pop(context);
      },
      icon: SvgPicture.asset('assets/images/ic_back.svg'),
      color: grey900,
      padding: const EdgeInsets.only(left: 24, right: 8),
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  );
}
