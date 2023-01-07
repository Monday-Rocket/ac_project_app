import 'package:ac_project_app/const/colors.dart';
import 'package:flutter/material.dart';

void showBottomToast(
  String text, {
  double? bottomPadding,
  BuildContext? context,
  Function? callback,
  String? subMsg,
  String actionTitle = '확인하기',
}) {
  ScaffoldMessenger.of(context!).showSnackBar(
    SnackBar(
      margin: EdgeInsets.only(left: 24, right: 24, bottom: bottomPadding ?? 10),
      content: subMsg == null
          ? Row(
              mainAxisAlignment: callback == null
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Text(text),
              ],
            )
          : SizedBox(
              height: 36,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    textAlign: TextAlign.start,
                  ),
                  Text(
                    subMsg,
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: grey400,
                      fontSize: 14,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
      backgroundColor: grey900,
      duration: const Duration(milliseconds: 5000),
      behavior: SnackBarBehavior.floating,
      action: (callback == null)
          ? null
          : SnackBarAction(
              label: actionTitle,
              textColor: Colors.white,
              onPressed: () {
                callback();
              },
            ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
    ),
  );
}
