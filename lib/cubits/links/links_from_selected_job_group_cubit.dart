import 'package:ac_project_app/cubits/links/has_more_cubit.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LinksFromSelectedJobGroupCubit extends Cubit<List<Link>> {
  LinksFromSelectedJobGroupCubit(): super([]) {
    getSelectedJobLinks(1, 0);
    scrollController.addListener(() {
      if (scrollController.position.pixels ==
          scrollController.position.maxScrollExtent &&
          hasMore.state == ScrollableType.can) {
        getSelectedJobLinks(selectedJobId, page + 1);
      } else {
        // Log.i(hasMore.state);
      }
    });
  }

  final linkApi = LinkApi();
  final scrollController = ScrollController();

  HasMoreCubit hasMore = HasMoreCubit();
  int selectedJobId = 0;
  int page = 0;

  Future<void> getSelectedJobLinks(int jobGroupId, int pageNum) async {
    selectedJobId = jobGroupId;
    final result = await linkApi.getJobGroupLinks(jobGroupId, pageNum);
    result.when(
      success: (data) {
        emit(data.contents ?? []);
      },
      error: (msg) {},
    );
  }
}
