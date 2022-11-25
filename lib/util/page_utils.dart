import 'package:ac_project_app/models/link/searched_links.dart';

bool hasMorePage(SearchedLinks data) =>
    (data.pageNum ?? 0) < (data.totalPage ?? 0) - 1;
