import 'package:ac_project_app/cubits/http_client_cubit.dart';
import 'package:ac_project_app/cubits/profile/profile_info_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final List<BlocProvider> globalProviders = [
  BlocProvider<GetProfileInfoCubit>(
    create: (_) => GetProfileInfoCubit(),
  ),
  BlocProvider(
    create: (_) => HttpClientCubit(),
  ),
];
