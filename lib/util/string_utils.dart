import 'dart:convert';

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
