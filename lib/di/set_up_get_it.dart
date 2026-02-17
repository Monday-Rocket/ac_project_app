import 'package:ac_project_app/provider/local/database_helper.dart';
import 'package:ac_project_app/provider/local/local_bulk_repository.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/provider/manager/app_pause_manager.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void locator() {
  final databaseHelper = DatabaseHelper.instance;

  getIt
    // Local Repositories (오프라인 모드 핵심)
    ..registerLazySingleton(() => databaseHelper)
    ..registerLazySingleton(
      () => LocalFolderRepository(databaseHelper: databaseHelper),
    )
    ..registerLazySingleton(
      () => LocalLinkRepository(databaseHelper: databaseHelper),
    )
    ..registerLazySingleton(
      () => LocalBulkRepository(databaseHelper: databaseHelper),
    )

    // Manager
    ..registerLazySingleton(AppPauseManager.new);
}
