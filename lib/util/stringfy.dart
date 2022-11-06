import 'dart:convert';

Object toEncodableFallback(dynamic object) {
  return object.toString();
}

String stringifyMessage(List<dynamic> listData) {
  const encoder = JsonEncoder.withIndent('  ', toEncodableFallback);
  return encoder.convert(listData);
}
