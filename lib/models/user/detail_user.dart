// ignore_for_file: avoid_dynamic_calls, test_types_in_equals

import 'package:equatable/equatable.dart';

class DetailUser extends Equatable {
  DetailUser({
    int? id,
    String? nickname,
    String? profile_img,
  }) {
    _id = id;
    _nickname = nickname;
    _profile_img = profile_img;
  }

  DetailUser.fromJson(dynamic json) {
    _id = json['id'] as int?;
    _nickname = json['nickname'] as String?;
    _profile_img = json['profile_img'] as String?;
  }

  late final int? _id;
  late final String? _nickname;
  late final String? _profile_img;

  DetailUser copyWith({
    int? id,
    String? nickname,
    String? profile_img,
  }) =>
      DetailUser(
        id: id ?? _id,
        nickname: nickname ?? _nickname,
        profile_img: profile_img ?? _profile_img,
      );

  int? get id => _id;

  String get nickname => _nickname ?? '';

  String get profile_img => _profile_img ?? '';

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['nickname'] = _nickname;
    map['profile_img'] = _profile_img;
    return map;
  }

  @override
  bool operator ==(Object other) {
    final input = other as DetailUser;
    return input.id == id &&
        input.nickname == nickname &&
        input.profile_img == profile_img;
  }

  @override
  int get hashCode => super.hashCode;

  bool isNotEmpty() => _id != null;

  @override
  List<Object?> get props => [_id, _nickname, _profile_img];
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

  JobGroup.fromJson(dynamic json) {
    _id = json['id'] as int?;
    _name = json['name'] as String?;
  }

  static List<JobGroup> fromJsonList(List<dynamic> jsonList) {
    final result = <JobGroup>[];
    for (final json in jsonList) {
      result.add(JobGroup.fromJson(json));
    }
    return result;
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
