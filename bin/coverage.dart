// ignore_for_file: avoid_print
import 'dart:io';

void main(List<String> arguments) async {
  // brew install lcov
  await execute('brew install lcov', skipError: true);
  await execute('flutter test --coverage');
  await execute('lcov --remove coverage/lcov.info '
      'lib/models/result.freezed.dart '
      'lib/models/*/*.freezed.dart '
      'lib/models/*/*.g.dart '
      'lib/gen/*.gen.dart '
      'lib/firebase_options.dart '
      '-o coverage/lcov.info');
  await execute('genhtml coverage/lcov.info -o coverage/html');
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
