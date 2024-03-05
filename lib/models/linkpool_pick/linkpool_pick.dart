import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'linkpool_pick.g.dart';

@JsonSerializable()
class LinkpoolPick extends Equatable {
  const LinkpoolPick({
    required this.id,
    required this.backgroundColor,
    required this.title,
    required this.image,
    required this.describe,
    required this.linkId,
  });

  factory LinkpoolPick.fromJson(Map<String, dynamic> json) =>
      _$LinkpoolPickFromJson(json);

  static List<LinkpoolPick> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((e) => LinkpoolPick.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  final int id;
  final String backgroundColor;
  final String title;
  final String image;
  final String describe;
  final int linkId;

  Map<String, dynamic> toJson() => _$LinkpoolPickToJson(this);

  @override
  List<Object?> get props => [];

  Color getColor() {
    return Color(int.parse(backgroundColor.replaceAll('#', ''), radix: 16));
  }
}
