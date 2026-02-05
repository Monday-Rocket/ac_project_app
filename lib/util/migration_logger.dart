import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 마이그레이션 과정을 파일로 기록하는 로거
class MigrationLogger {
  MigrationLogger._();

  static MigrationLogger? _instance;
  static MigrationLogger get instance => _instance ??= MigrationLogger._();

  File? _logFile;
  final StringBuffer _buffer = StringBuffer();
  DateTime? _startTime;

  /// 로그 세션 시작
  Future<void> start() async {
    _startTime = DateTime.now();
    _buffer.clear();

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = _startTime!.toIso8601String().replaceAll(':', '-');
    _logFile = File('${dir.path}/migration_$timestamp.log');

    _log('='.padRight(60, '='));
    _log('마이그레이션 로그 시작');
    _log('시작 시간: $_startTime');
    _log('='.padRight(60, '='));
  }

  /// 일반 정보 로그
  void info(String message) {
    _log('[INFO] $message');
  }

  /// 폴더 관련 로그
  void folder(String message) {
    _log('[FOLDER] $message');
  }

  /// 링크 관련 로그
  void link(String message) {
    _log('[LINK] $message');
  }

  /// 에러 로그
  void error(String message) {
    _log('[ERROR] $message');
  }

  /// 구분선
  void separator() {
    _log('-'.padRight(40, '-'));
  }

  void _log(String message) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
    final line = '[$timeStr] $message';

    _buffer.writeln(line);
    // ignore: avoid_print
    print(line); // 콘솔에도 출력
  }

  /// 로그 세션 종료 및 파일 저장
  Future<String?> finish({
    int? foldersCount,
    int? linksCount,
    String? errorMessage,
  }) async {
    final endTime = DateTime.now();
    final duration = endTime.difference(_startTime ?? endTime);

    _log('='.padRight(60, '='));
    _log('마이그레이션 완료');
    _log('종료 시간: $endTime');
    _log('소요 시간: ${duration.inSeconds}초');
    if (foldersCount != null) _log('저장된 폴더: $foldersCount개');
    if (linksCount != null) _log('저장된 링크: $linksCount개');
    if (errorMessage != null) _log('에러: $errorMessage');
    _log('='.padRight(60, '='));

    // 파일 저장
    if (_logFile != null) {
      await _logFile!.writeAsString(_buffer.toString());
      return _logFile!.path;
    }
    return null;
  }

  /// 로그 파일 경로 반환
  String? get logFilePath => _logFile?.path;

  /// 로그 파일 공유
  Future<void> shareLogFile() async {
    if (_logFile != null && await _logFile!.exists()) {
      await Share.shareXFiles(
        [XFile(_logFile!.path)],
        subject: '마이그레이션 로그',
      );
    }
  }

  /// 최근 로그 파일 목록 가져오기
  static Future<List<File>> getRecentLogFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.contains('migration_') && f.path.endsWith('.log'))
        .toList();

    // 최신순 정렬
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  /// 로그 파일 내용 읽기
  static Future<String?> readLogFile(File file) async {
    if (await file.exists()) {
      return file.readAsString();
    }
    return null;
  }
}
