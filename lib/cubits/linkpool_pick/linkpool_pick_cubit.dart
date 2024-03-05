import 'package:ac_project_app/cubits/linkpool_pick/linkpool_pick_result_state.dart';
import 'package:ac_project_app/di/set_up_get_it.dart';
import 'package:ac_project_app/models/linkpool_pick/linkpool_pick.dart';
import 'package:ac_project_app/models/result.dart';
import 'package:ac_project_app/provider/api/linkpool_pick/linkpool_pick_api.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LinkpoolPickCubit extends Cubit<LinkpoolPickResultState> {
  LinkpoolPickCubit() : super(LinkpoolPickResultInitialState()) {
    loadLinkpoolPicks();
  }

  final LinkpoolPickApi linkpoolPickApi = getIt();

  void loadLinkpoolPicks() {
    linkpoolPickApi
        .getLinkpoolPicks()
        .then((Result<List<LinkpoolPick>> result) {
      result.when(
        success: (List<LinkpoolPick> data) {
          Log.i(data);
          if (data.isEmpty) {
            emit(LinkpoolPickResultNoDataState());
          } else {
            emit(LinkpoolPickResultLoadedState(data));
          }
        },
        error: (msg) {
          Log.i('pick data');
          emit(LinkpoolPickResultErrorState(msg));
        },
      );
    });
  }
}
