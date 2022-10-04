import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  User(this.id);

  factory User.nullObject() => User('');

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  final String id;

  Map<String, dynamic> toJson() => _$UserToJson(this);
}
