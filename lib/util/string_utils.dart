import 'dart:convert';

import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:intl/intl.dart';

String stringifyMessage(List<dynamic> listData) {
  final encoder = JsonEncoder.withIndent('  ', (o) => o.toString());
  return encoder.convert(listData);
}

bool hasHttpImageUrl(Link link) =>
    link.image != null &&
    link.image!.isNotEmpty &&
    link.image!.startsWith('http');

String makeLinkTimeString(String timeString, [DateTime? inputTime]) {
  final formattedString = '${timeString}Z';

  final time = DateTime.tryParse(formattedString);
  if (time == null) {
    return '알 수 없음';
  } else {
    final now = inputTime ?? DateTime.now().toUtc();
    final duration = now.difference(time);

    if (duration.compareTo(const Duration(hours: 1)) < 0) {
      if (duration.inMinutes < 0) {
        return '';
      } else if (duration.inMinutes == 0) {
        return '방금 전';
      } else {
        return '${duration.inMinutes}분 전';
      }
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

/// Time Format: yyyy-MM-ddTHH:mm:ssZ
String getCurrentTime([DateTime? inputTime]) {
  final dateFormatter = DateFormat('yyyy-MM-dd');
  final timeFormatter = DateFormat('HH:mm:ss');

  final now = inputTime ?? DateTime.now().toUtc();
  return '${dateFormatter.format(now)}T${timeFormatter.format(now)}Z';
}

String getShortTitle(String title) {
  if (title.length > 30) {
    return title.substring(0, 30);
  }
  return title;
}

String decodeBase64Text(String text) {
  try {
    final encoder = utf8.fuse(base64);
    return encoder.decode(text);
  } on FormatException catch (e) {
    Log.e(e.message);
    return '';
  }
}