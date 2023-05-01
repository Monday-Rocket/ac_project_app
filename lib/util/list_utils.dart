import 'package:ac_project_app/models/profile/profile.dart';
import 'package:ac_project_app/models/user/detail_user.dart';

extension SortMyJobs on List<JobGroup> {
  List<JobGroup> sortMyJobs(Profile profile) {
    final myJobId = profile.jobGroup!.id!;
    final tempJob = firstWhere((element) => element.id == myJobId);
    return this
      ..remove(tempJob)
      ..insert(1, tempJob);
  }
}
