import 'package:json_annotation/json_annotation.dart';

/// status : 0
/// data : {"id":"1"}

@JsonSerializable(explicitToJson: true)
class ApiResult {
  ApiResult({
      int? status, 
      Data? data,}){
    _status = status;
    _data = data;
}

  ApiResult.fromJson(dynamic json) {
    _status = json['status'] as int?;
    _data = json['data'] != null ? Data.fromJson(json['data']) : null;
  }
  int? _status;
  Data? _data;
ApiResult copyWith({  int? status,
  Data? data,
}) => ApiResult(  status: status ?? _status,
  data: data ?? _data,
);
  int? get status => _status;
  Data? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['status'] = _status;
    if (_data != null) {
      map['data'] = _data?.toJson();
    }
    return map;
  }

}

/// id : "1"

class Data {
  Data({
      String? id,}){
    _id = id;
}

  Data.fromJson(dynamic json) {
    _id = json['id'] as String?;
  }
  String? _id;
Data copyWith({  String? id,
}) => Data(  id: id ?? _id,
);
  String? get id => _id;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    return map;
  }

}