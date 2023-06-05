import 'package:ac_project_app/util/url_valid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('url valid success test', () async {
    const validUrl = 'https://github.com/boring-km';
    final isValid = await isValidUrl(validUrl);
    expect(isValid, true);
  });

  test('url valid fail test', () async {
    const invalidUrl = 'https://github.com/boring-km/invalid';
    final isValid = await isValidUrl(invalidUrl);
    expect(isValid, false);
  });
}
