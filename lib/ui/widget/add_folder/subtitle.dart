import 'package:ac_project_app/const/colors.dart';
import 'package:flutter/material.dart';

Text buildSubTitle(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 16,
      height: 19 / 16,
      letterSpacing: -0.3,
      color: grey800,
    ),
  );
}
