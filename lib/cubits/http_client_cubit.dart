import 'package:ac_project_app/provider/api/custom_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

class HttpClientCubit extends Cubit<CustomClient> {
  HttpClientCubit(): super(CustomClient(client: http.Client()));
}
