/// id : "1"
/// nickname : "test"
/// job_group : {"id":1,"name":"소프트웨어 엔지니어"}

// ignore_for_file: avoid_dynamic_calls, test_types_in_equals

class DetailUser {
  DetailUser({
    int? id,
    String? nickname,
    JobGroup? jobGroup,
  }) {
    _id = id;
    _nickname = nickname;
    _jobGroup = jobGroup;
  }

  DetailUser.fromJson(dynamic json) {
    _id = json['id'] as int?;
    _nickname = json['nickname'] as String?;
    _jobGroup =
        json['job_group'] != null ? JobGroup.fromJson(json['job_group']) : null;
  }
  int? _id;
  String? _nickname;
  JobGroup? _jobGroup;
  DetailUser copyWith({
    int? id,
    String? nickname,
    JobGroup? jobGroup,
  }) =>
      DetailUser(
        id: id ?? _id,
        nickname: nickname ?? _nickname,
        jobGroup: jobGroup ?? _jobGroup,
      );
  int? get id => _id;
  String? get nickname => _nickname;
  JobGroup? get jobGroup => _jobGroup;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['nickname'] = _nickname;
    if (_jobGroup != null) {
      map['job_group'] = _jobGroup?.toJson();
    }
    return map;
  }

  @override
  bool operator ==(Object other) {
    final input = other as DetailUser;
    return input.id == id &&
        input.nickname == nickname &&
        input.jobGroup == jobGroup;
  }

  @override
  int get hashCode => super.hashCode;
}

/// id : 1
/// name : "소프트웨어 엔지니어"

class JobGroup {
  JobGroup({
    int? id,
    String? name,
  }) {
    _id = id;
    _name = name;
  }

  static List<JobGroup> fromJsonList(List<dynamic> jsonList) {
    final result = <JobGroup>[];
    for (final json in jsonList) {
      result.add(JobGroup.fromJson(json));
    }
    return result;
  }

  JobGroup.fromJson(dynamic json) {
    _id = json['id'] as int?;
    _name = json['name'] as String?;
  }
  int? _id;
  String? _name;
  JobGroup copyWith({
    int? id,
    String? name,
  }) =>
      JobGroup(
        id: id ?? _id,
        name: name ?? _name,
      );
  int? get id => _id;
  String? get name => _name;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['name'] = _name;
    return map;
  }

  @override
  bool operator ==(Object other) {
    final input = other as JobGroup;
    return input.id == id && input.name == name;
  }

  @override
  int get hashCode => super.hashCode;
}
