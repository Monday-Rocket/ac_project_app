import 'package:ac_project_app/models/report/report.dart';
import 'package:ac_project_app/models/report/report_result_type.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';

class ReportApi {
  ReportApi(this._client);

  final CustomClient _client;

  Future<ReportResultType> report(Report report) async {
    final result = await _client.postUri('/reports', body: report.toJson());
    return result.when(
      success: (data) {
        return ReportResultType.success;
      },
      error: (code) {
        if (code == '4000') {
          return ReportResultType.duplicated;
        }
        return ReportResultType.error;
      },
    );
  }
}
