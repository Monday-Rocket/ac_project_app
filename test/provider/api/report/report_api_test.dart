import 'package:ac_project_app/const/consts.dart';
import 'package:ac_project_app/models/net/api_error.dart';
import 'package:ac_project_app/models/net/api_result.dart';
import 'package:ac_project_app/models/report/report.dart';
import 'package:ac_project_app/models/report/report_result_type.dart';
import 'package:ac_project_app/models/report/report_type.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';
import 'package:ac_project_app/provider/api/report/report_api.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mock_client_generator.dart';

void main() {
  test('ReportApi report Success Test', () async {
    // Given: 신고 성공 시 data는 없고 status가 0이다.
    final expectedResult = ApiResult(status: 0);

    // When 1: ReportApi의 MockClient 설정하고
    final mockClient = getMockClient(expectedResult, '/reports');

    final reportApi = ReportApi(
      CustomClient(
        client: mockClient,
        auth: MockFirebaseAuth(),
      ),
    );

    // When 2: ReportApi의 report() 실행했을 때,
    final actual = await reportApi.report(
      Report(
        targetType: ReportType.user.name,
        targetId: 0,
        reasonType: reportReasons[0],
      ),
    );

    // Then: 예상했던 결과와 동일하게 나오는지 확인한다.
    expect(actual, ReportResultType.success);
  });

  test('ReportApi report Duplicated Test', () async {
    // Given: 이미 등록된 신고정보는 status 4000으로 결과가 전달된다.
    final expectedResult = ApiResult(status: 4000, error: ApiError('이미 등록된 신고정보입니다.'));

    // When 1: ReportApi의 MockClient 설정하고
    final mockClient = getMockClient(expectedResult, '/reports');

    final reportApi = ReportApi(
      CustomClient(
        client: mockClient,
        auth: MockFirebaseAuth(),
      ),
    );

    // When 2: ReportApi의 report() 실행했을 때,
    final actual = await reportApi.report(
      Report(
        targetType: ReportType.user.name,
        targetId: 0,
        reasonType: reportReasons[0],
      ),
    );

    // Then: 예상했던 결과와 동일하게 나오는지 확인한다.
    expect(actual, ReportResultType.duplicated);
  });
}
