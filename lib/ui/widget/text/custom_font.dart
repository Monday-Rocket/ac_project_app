import 'package:flutter/widgets.dart';

extension FontSize on Text {

  Text fontSize(double fontSize) {
    final curStyle = style == null ? const TextStyle() : style!;
    return Text(
      data ?? '',
      style: curStyle.copyWith(
        fontSize: fontSize,
      ),
    );
  }
}

extension Weight on Text {
  Text weight(FontWeight fontWeight) {
    final curStyle = style == null ? const TextStyle() : style!;
    return Text(
      data ?? '',
      style: curStyle.copyWith(
        fontWeight: fontWeight,
      ),
    );
  }
}

extension Bold on Text {
  Text bold() {
    final curStyle = style == null ? const TextStyle() : style!;
    return Text(
      data ?? '',
      style: curStyle.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

extension Roboto on Text {
  Text roboto() {
    final curStyle = style == null ? const TextStyle() : style!;
    return Text(
      data ?? '',
      style: curStyle.copyWith(
        fontFamily: 'Roboto',
      ),
    );
  }
}
