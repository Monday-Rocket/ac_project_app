import 'package:ac_project_app/provider/recent_folders_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const repo = RecentFoldersRepository();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('empty initially', () async {
    expect(await repo.getRecentIds(), isEmpty);
  });

  test('records folder id and keeps order (most recent first)', () async {
    await repo.record(1);
    await repo.record(2);
    await repo.record(3);

    expect(await repo.getRecentIds(), [3, 2, 1]);
  });

  test('record existing id moves it to front', () async {
    await repo.record(1);
    await repo.record(2);
    await repo.record(3);
    await repo.record(1);

    expect(await repo.getRecentIds(), [1, 3, 2]);
  });

  test('keeps only last 5 items', () async {
    for (int i = 1; i <= 7; i++) {
      await repo.record(i);
    }

    expect(await repo.getRecentIds(), [7, 6, 5, 4, 3]);
  });

  test('remove drops the given id', () async {
    await repo.record(1);
    await repo.record(2);
    await repo.record(3);

    await repo.remove(2);

    expect(await repo.getRecentIds(), [3, 1]);
  });

  test('clear empties the list', () async {
    await repo.record(1);
    await repo.record(2);
    await repo.clear();
    expect(await repo.getRecentIds(), isEmpty);
  });
}
