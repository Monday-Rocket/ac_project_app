import 'package:ac_project_app/cubits/folders/get_user_folders_cubit.dart';
import 'package:ac_project_app/cubits/linkpool_pick/linkpool_pick_cubit.dart';
import 'package:ac_project_app/cubits/login/auto_login_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:ac_project_app/provider/api/linkpool_pick/linkpool_pick_api.dart';
import 'package:ac_project_app/provider/api/report/report_api.dart';
import 'package:ac_project_app/provider/api/user/profile_api.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:ac_project_app/provider/manager/app_pause_manager.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void locator() {
  final httpClient = CustomClient();

  getIt
    ..registerLazySingleton(() => httpClient)

    // APIs
    ..registerLazySingleton(() => FolderApi(httpClient))
    ..registerLazySingleton(() => LinkApi(httpClient))
    ..registerLazySingleton(() => ReportApi(httpClient))
    ..registerLazySingleton(() => ProfileApi(httpClient))
    ..registerLazySingleton(() => UserApi(httpClient))
    ..registerLazySingleton(() => LinkpoolPickApi(httpClient))

    // Cubits
    ..registerLazySingleton(GetUserFoldersCubit.new)
    ..registerLazySingleton(GetProfileInfoCubit.new)
    ..registerLazySingleton(AutoLoginCubit.new)
    ..registerLazySingleton(LinkpoolPickCubit.new)
    ..registerLazySingleton(AppPauseManager.new);
}
