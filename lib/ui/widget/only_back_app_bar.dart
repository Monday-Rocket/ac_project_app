import 'package:ac_project_app/const/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

AppBar buildBackAppBar(BuildContext context) {
  return AppBar(
    leading: IconButton(
      onPressed: () {
        Navigator.pop(context);
      },
      icon: const Icon(Icons.arrow_back_ios_new),
      color: grey900,
      padding: const EdgeInsets.only(left: 24, right: 8),
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
  );
}
