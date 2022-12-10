import 'package:ac_project_app/const/colors.dart';
import 'package:flutter/material.dart';

Widget buildBottomSheetButton({
  required BuildContext context,
  required String text,
  bool? keyboardVisible,
  void Function()? onPressed,
}) {
  return SafeArea(
    child: Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + ((keyboardVisible ?? false) ? 16 : 0),
        left: 24,
        right: 24,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(55),
          backgroundColor: primary800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: secondary,
          disabledForegroundColor: Colors.white,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
          textWidthBasis: TextWidthBasis.parent,
        ),
      ),
    ),
  );
}
