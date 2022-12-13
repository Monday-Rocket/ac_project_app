import 'package:ac_project_app/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      icon: SvgPicture.asset('assets/images/ic_back.svg'),
      color: grey900,
      padding: const EdgeInsets.only(left: 20, right: 8),
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  );
}
