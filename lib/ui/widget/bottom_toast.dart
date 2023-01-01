import 'package:ac_project_app/const/colors.dart';
import 'package:flutter/material.dart';

void showBottomToast(
  String text, {
  double? bottomPadding,
  BuildContext? context,
  Function? callback,
  String actionTitle = '확인하기',
}) {
  ScaffoldMessenger.of(context!).showSnackBar(
    SnackBar(
      margin: EdgeInsets.only(left: 24, right: 24, bottom: bottomPadding ?? 10),
      content: Row(
        mainAxisAlignment: callback == null
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        children: [
          Text(text),
        ],
      ),
      backgroundColor: grey900,
      duration: const Duration(milliseconds: 1000),
      behavior: SnackBarBehavior.floating,
      action: (callback == null)
          ? null
          : SnackBarAction(
              label: actionTitle,
              textColor: Colors.white,
              onPressed: (){
                callback();
              },
            ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
    ),
  );
}
