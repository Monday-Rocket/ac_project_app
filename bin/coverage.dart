// ignore_for_file: avoid_print
import 'dart:io';

void main(List<String> arguments) async {
  // brew install lcov
  // await execute('brew install lcov', skipError: true);
  await execute('flutter test --coverage');
  await execute('../../Downloads/lcov-1.16/bin/lcov --remove coverage/lcov.info '
      'lib/main.dart '
      'lib/initial_settings.dart '
      'lib/routes.dart '
      'lib/provider/login/*.dart '
      'lib/provider/global_providers.dart '
      'lib/provider/logout.dart '
      'lib/provider/profile_images.dart '
      'lib/provider/share_db.dart '
      'lib/provider/tool_tip_check.dart '
      'lib/*.freezed.dart '
      'lib/*.g.dart '
      'lib/gen/*.gen.dart '
      'lib/firebase_options.dart '
      'lib/util/logger.dart '
      'lib/di/set_up_get_it.dart '
      'lib/const/*.dart '
      '-o coverage/lcov.info');
  await execute('../../Downloads/lcov-1.16/bin/genhtml coverage/lcov.info -o coverage/html');
  await execute('open coverage/html/index.html');
}

Future<void> execute(String cmd, {String? dir, bool skipError = false}) async {
  print(cmd + (dir != null ? ' [on $dir]' : ''));

  final args = cmd.split(' ');
  final command = args.first;
  final List<String> options;
  if (args.length > 1) {
    options = args.getRange(1, args.length).toList();
  } else {
    options = [];
  }

  final result = await Process.run(
    command,
    options,
    workingDirectory: dir,
  );

  print(result.stdout);
  if (!skipError && result.stderr != '') {
    throw Exception(result.stderr);
  } else {
    print(result.stderr);
  }
}
