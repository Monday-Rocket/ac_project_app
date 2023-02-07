import 'package:ac_project_app/models/user/detail_user.dart';

extension CheckContains on List<String?> {
  bool checkContains(String? compare) {
    if (contains(compare ?? '')) {
      return true;
    } else {
      return false;
    }
  }
}

extension SortMyJobs on List<JobGroup> {
  List<JobGroup> sortMyJobs(int myJobId) {
    final tempJob = firstWhere((element) => element.id == myJobId);
    return this
      ..remove(tempJob)
      ..insert(1, tempJob);
  }
}
