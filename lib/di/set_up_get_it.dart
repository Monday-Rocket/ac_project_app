import 'package:ac_project_app/cubits/folders/get_user_folders_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';
import 'package:ac_project_app/provider/api/folders/folder_api.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:ac_project_app/provider/api/report/report_api.dart';
import 'package:ac_project_app/provider/api/user/profile_api.dart';
import 'package:ac_project_app/provider/api/user/user_api.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void locator() {
  final httpClient = CustomClient();

  getIt..registerLazySingleton(() => httpClient)

  // APIs
  ..registerLazySingleton(() => FolderApi(httpClient))
  ..registerLazySingleton(() => LinkApi(httpClient))
  ..registerLazySingleton(() => ReportApi(httpClient))
  ..registerLazySingleton(() => ProfileApi(httpClient))
  ..registerLazySingleton(() => UserApi(httpClient));


  // Cubits
  final profileCubit = GetProfileInfoCubit();
  getIt..registerLazySingleton(GetUserFoldersCubit.new)
  ..registerLazySingleton(() => profileCubit);
}
