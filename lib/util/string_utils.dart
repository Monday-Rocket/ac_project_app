import 'dart:convert';

import 'package:ac_project_app/models/link/link.dart';

Object toEncodableFallback(dynamic object) {
  return object.toString();
}

String stringifyMessage(List<dynamic> listData) {
  const encoder = JsonEncoder.withIndent('  ', toEncodableFallback);
  return encoder.convert(listData);
}

String getSafeTitleText(String? text) {
  if (text == null || text.isEmpty) {
    return '제목 없음';
  }
  return text;
}

String makeImagePath(String image) =>
    'assets/images/profile/img_${image}_on.png';

bool isLinkVerified(Link link) =>
    link.image != null &&
        link.image!.isNotEmpty &&
        link.image!.contains('http');