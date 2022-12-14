import 'dart:convert';

import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:intl/intl.dart';

Object toEncodableFallback(dynamic object) {
  return object.toString();
}

String stringifyMessage(List<dynamic> listData) {
  const encoder = JsonEncoder.withIndent('  ', toEncodableFallback);
  return encoder.convert(listData);
}

String getSafeTitleText(String? text) {
  if (text == null || text.isEmpty) {
    return '';
  }
  return text;
}

String makeImagePath(String image) =>
    'assets/images/profile/img_${image}_on.png';

bool isLinkVerified(Link link) =>
    link.image != null &&
    link.image!.isNotEmpty &&
    link.image!.contains('http');

String makeLinkTimeString(String timeString) {
  final formattedString = '${timeString}Z';

  final time = DateTime.tryParse(formattedString);
  if (time == null) {
    return '알 수 없음'; /* TODO 예외 상황 */
  } else {
    final now = DateTime.now().toUtc();
    final duration = now.difference(time);

    if (duration.compareTo(const Duration(hours: 1)) < 0) {
      return '${duration.inMinutes}분 전';
    }
    if (duration.compareTo(const Duration(days: 1)) < 0) {
      return '${duration.inHours}시간 전';
    }
    if (duration.compareTo(const Duration(days: 7)) < 0) {
      return '${duration.inDays}일 전';
    }
    return DateFormat('yyyy/MM/dd').format(time);
  }
}

String getCurrentTime() {
  final dateFormatter = DateFormat('yyyy-MM-dd');
  final timeFormatter = DateFormat('hh:mm:ss');

  final now = DateTime.now().toUtc();
  return '${dateFormatter.format(now)}T${timeFormatter.format(now)}Z';
}

String getShortTitle(String title) {
  try {
    final encoded = utf8.fuse(base64);
    final decodedTitle = encoded.decode(title);

    if (decodedTitle.length > 30) {
      return decodedTitle.substring(0, 30);
    }
    return decodedTitle;
  } on FormatException catch (e) {
    Log.e(e);
    Log.e(e.message);
    return '';
  }
}
