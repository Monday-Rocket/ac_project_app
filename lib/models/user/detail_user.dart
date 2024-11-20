// ignore_for_file: avoid_dynamic_calls, test_types_in_equals, hash_and_equals

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

  bool isNotEmpty() => _id != null;

  @override
  List<Object?> get props => [_id, _nickname, _profile_img];
}
