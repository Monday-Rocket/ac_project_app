import 'package:ac_project_app/ui/widget/widget_offset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WidgetOffset getTopMid() success test', () {
    final offset = WidgetOffset(
      Offset.zero,
      const Offset(10, 0),
      const Offset(0, 10),
      const Offset(10, 10),
      true,
    );

    final actual = offset.getTopMid();

    expect(actual, const Offset(5, 0));
  });
}
