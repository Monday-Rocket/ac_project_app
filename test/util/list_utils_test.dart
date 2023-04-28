import 'package:ac_project_app/models/profile/profile.dart';
import 'package:ac_project_app/models/user/detail_user.dart';
import 'package:ac_project_app/util/list_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('전체 JobGroup이 포함된 JobGroup 리스트에서 주어진 프로필을 기준으로 정렬하는 테스트', () {
    final total = JobGroup(id: 99, name: '전체');
    final jobGroup0 = JobGroup(id: 0, name: '직업 0');
    final jobGroup1 = JobGroup(id: 1, name: '직업 1');
    final jobGroup2 = JobGroup(id: 2, name: '직업 2');

    late List<JobGroup> jobGroups;

    setUp(() {
      jobGroups = [
        total,
        jobGroup0,
        jobGroup1,
        jobGroup2,
      ];
    });

    test('이름이 직업 0인 기준으로 정렬하기', () {
      final jobGroup0Target = Profile(
        nickname: 'boring-km',
        profileImage: '01',
        jobGroup: jobGroup0,
      );

      final actual = jobGroups.sortMyJobs(
        jobGroup0Target,
      );

      expect(actual, [total, jobGroup0, jobGroup1, jobGroup2]);
    });

    test('이름이 직업 1인 기준으로 정렬하기', () {
      final jobGroup1Target = Profile(
        nickname: 'boring-km',
        profileImage: '01',
        jobGroup: jobGroup1,
      );

      final actual = jobGroups.sortMyJobs(
        jobGroup1Target,
      );

      expect(actual, [total, jobGroup1, jobGroup0, jobGroup2]);
    });

    test('이름이 직업 2인 기준으로 정렬하기', () {
      final jobGroup2Target = Profile(
        nickname: 'boring-km',
        profileImage: '01',
        jobGroup: jobGroup2,
      );

      final actual = jobGroups.sortMyJobs(
        jobGroup2Target,
      );

      expect(actual, [total, jobGroup2, jobGroup0, jobGroup1]);
    });
  });
}
