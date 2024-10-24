import 'package:metadata_fetch/metadata_fetch.dart';

class UploadResult {

  UploadResult({required this.state, this.metadata});

  final UploadResultState state;
  final Metadata? metadata;

  bool isNotValidAndSuccess() {
    return state != UploadResultState.isValid && state != UploadResultState.success;
  }
}

enum UploadResultState {
  none, isValid, success, duplicated, apiError, error
}
