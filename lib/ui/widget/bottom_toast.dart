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
      margin: EdgeInsets.only(
        left: 21,
        right: 21,
        bottom: bottomPadding ?? 11,
        top: bottomPadding ?? 11,
      ),
      content: subMsg == null
          ? Row(
              mainAxisAlignment: callback == null
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Text(text),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 16 / 13,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subMsg,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
                    color: grey400,
                    fontSize: 13,
                    letterSpacing: -0.1,
                    height: 16 / 13,
                  ),
                ),
              ],
            ),
      backgroundColor: grey900,
      duration: const Duration(milliseconds: 2000),
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
