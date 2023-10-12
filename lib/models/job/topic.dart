class Topic {
  Topic({
    int? id,
    String? name,
  }) {
    _id = id;
    _name = name;
  }

  Topic.fromJson(dynamic json) {
    _id = json['id'] as int?;
    _name = json['name'] as String?;
  }

  static List<Topic> fromJsonList(List<dynamic> jsonList) {
    final result = <Topic>[];
    for (final json in jsonList) {
      result.add(Topic.fromJson(json));
    }
    return result;
  }

  int? _id;
  String? _name;

  Topic copyWith({
    int? id,
    String? name,
  }) =>
      Topic(
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
    final input = other as Topic;
    return input.id == id && input.name == name;
  }

  @override
  int get hashCode => super.hashCode;
}
