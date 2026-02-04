import 'package:ac_project_app/cubits/login/auto_login_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';
import 'package:ac_project_app/provider/api/save_offline/save_offline_api.dart';
import 'package:ac_project_app/provider/api/user/profile_api.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/local/database_helper.dart';
import 'package:ac_project_app/provider/local/local_bulk_repository.dart';
import 'package:ac_project_app/provider/local/local_folder_repository.dart';
import 'package:ac_project_app/provider/local/local_link_repository.dart';
import 'package:ac_project_app/provider/local/offline_migration_service.dart';
import 'package:ac_project_app/provider/manager/app_pause_manager.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void locator() {
  final httpClient = CustomClient();
  final databaseHelper = DatabaseHelper.instance;

  getIt
    ..registerLazySingleton(() => httpClient)

    // APIs (로그인, 마이그레이션, 프로필용)
    ..registerLazySingleton(() => UserApi(httpClient))
    ..registerLazySingleton(() => ProfileApi(httpClient))
    ..registerLazySingleton(() => SaveOfflineApi(httpClient))

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

    // Services
    ..registerLazySingleton(OfflineMigrationService.new)

    // Cubits
    ..registerLazySingleton(GetProfileInfoCubit.new)
    ..registerLazySingleton(AutoLoginCubit.new)
    ..registerLazySingleton(AppPauseManager.new);
}
