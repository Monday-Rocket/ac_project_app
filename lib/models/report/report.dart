import 'package:freezed_annotation/freezed_annotation.dart';

part 'report.g.dart';

@JsonSerializable()
class Report {
  Report({
    required this.targetType,
    required this.targetId,
    required this.reasonType,
    this.otherReason,
  });

  factory Report.fromJson(Map<String, dynamic> json) => _$ReportFromJson(json);

  Map<String, dynamic> toJson() => _$ReportToJson(this);

  final String targetType;
  final int targetId;
  final String reasonType;
  final String? otherReason;
}
