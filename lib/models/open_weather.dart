import 'package:json_annotation/json_annotation.dart';

@JsonSerializable()
class OpenWeather {
  OpenWeather({
      Coord? coord, 
      List<Weather>? weather, 
      String? base, 
      Main? main, 
      int? visibility, 
      Wind? wind, 
      Rain? rain, 
      Clouds? clouds, 
      int? dt, 
      Sys? sys, 
      int? timezone, 
      int? id, 
      String? name, 
      int? cod,}){
    _coord = coord;
    _weather = weather;
    _base = base;
    _main = main;
    _visibility = visibility;
    _wind = wind;
    _rain = rain;
    _clouds = clouds;
    _dt = dt;
    _sys = sys;
    _timezone = timezone;
    _id = id;
    _name = name;
    _cod = cod;
}

  OpenWeather.fromJson(Map<String, dynamic> json) {
    _coord = json['coord'] != null ? Coord.fromJson(json['coord']) : null;
    if (json['weather'] != null) {
      _weather = [];
      json['weather'].forEach((v) {
        _weather?.add(Weather.fromJson(v));
      });
    }
    _base = json['base'] as String?;
    _main = json['main'] != null ? Main.fromJson(json['main']) : null;
    _visibility = json['visibility'] as int?;
    _wind = json['wind'] != null ? Wind.fromJson(json['wind']) : null;
    _rain = json['rain'] != null ? Rain.fromJson(json['rain']) : null;
    _clouds = json['clouds'] != null ? Clouds.fromJson(json['clouds']) : null;
    _dt = json['dt'] as int?;
    _sys = json['sys'] != null ? Sys.fromJson(json['sys']) : null;
    _timezone = json['timezone'] as int?;
    _id = json['id'] as int?;
    _name = json['name'] as String?;
    _cod = json['cod'] as int?;
  }
  Coord? _coord;
  List<Weather>? _weather;
  String? _base;
  Main? _main;
  int? _visibility;
  Wind? _wind;
  Rain? _rain;
  Clouds? _clouds;
  int? _dt;
  Sys? _sys;
  int? _timezone;
  int? _id;
  String? _name;
  int? _cod;
OpenWeather copyWith({  Coord? coord,
  List<Weather>? weather,
  String? base,
  Main? main,
  int? visibility,
  Wind? wind,
  Rain? rain,
  Clouds? clouds,
  int? dt,
  Sys? sys,
  int? timezone,
  int? id,
  String? name,
  int? cod,
}) => OpenWeather(  coord: coord ?? _coord,
  weather: weather ?? _weather,
  base: base ?? _base,
  main: main ?? _main,
  visibility: visibility ?? _visibility,
  wind: wind ?? _wind,
  rain: rain ?? _rain,
  clouds: clouds ?? _clouds,
  dt: dt ?? _dt,
  sys: sys ?? _sys,
  timezone: timezone ?? _timezone,
  id: id ?? _id,
  name: name ?? _name,
  cod: cod ?? _cod,
);
  Coord? get coord => _coord;
  List<Weather>? get weather => _weather;
  String? get base => _base;
  Main? get main => _main;
  int? get visibility => _visibility;
  Wind? get wind => _wind;
  Rain? get rain => _rain;
  Clouds? get clouds => _clouds;
  int? get dt => _dt;
  Sys? get sys => _sys;
  int? get timezone => _timezone;
  int? get id => _id;
  String? get name => _name;
  int? get cod => _cod;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_coord != null) {
      map['coord'] = _coord?.toJson();
    }
    if (_weather != null) {
      map['weather'] = _weather?.map((v) => v.toJson()).toList();
    }
    map['base'] = _base;
    if (_main != null) {
      map['main'] = _main?.toJson();
    }
    map['visibility'] = _visibility;
    if (_wind != null) {
      map['wind'] = _wind?.toJson();
    }
    if (_rain != null) {
      map['rain'] = _rain?.toJson();
    }
    if (_clouds != null) {
      map['clouds'] = _clouds?.toJson();
    }
    map['dt'] = _dt;
    if (_sys != null) {
      map['sys'] = _sys?.toJson();
    }
    map['timezone'] = _timezone;
    map['id'] = _id;
    map['name'] = _name;
    map['cod'] = _cod;
    return map;
  }

}

/// type : 2
/// id : 2075663
/// country : "IT"
/// sunrise : 1661834187
/// sunset : 1661882248

class Sys {
  Sys({
      int? type, 
      int? id, 
      String? country, 
      int? sunrise, 
      int? sunset,}){
    _type = type;
    _id = id;
    _country = country;
    _sunrise = sunrise;
    _sunset = sunset;
}

  Sys.fromJson(dynamic json) {
    _type = json['type'] as int?;
    _id = json['id'] as int?;
    _country = json['country'] as String?;
    _sunrise = json['sunrise'] as int?;
    _sunset = json['sunset'] as int?;
  }
  int? _type;
  int? _id;
  String? _country;
  int? _sunrise;
  int? _sunset;
Sys copyWith({  int? type,
  int? id,
  String? country,
  int? sunrise,
  int? sunset,
}) => Sys(  type: type ?? _type,
  id: id ?? _id,
  country: country ?? _country,
  sunrise: sunrise ?? _sunrise,
  sunset: sunset ?? _sunset,
);
  int? get type => _type;
  int? get id => _id;
  String? get country => _country;
  int? get sunrise => _sunrise;
  int? get sunset => _sunset;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['type'] = _type;
    map['id'] = _id;
    map['country'] = _country;
    map['sunrise'] = _sunrise;
    map['sunset'] = _sunset;
    return map;
  }

}

/// all : 100

class Clouds {
  Clouds({
      int? all,}){
    _all = all;
}

  Clouds.fromJson(dynamic json) {
    _all = json['all'] as int?;
  }
  int? _all;
Clouds copyWith({  int? all,
}) => Clouds(  all: all ?? _all,
);
  int? get all => _all;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['all'] = _all;
    return map;
  }

}

/// 1h : 3.16

class Rain {
  Rain({
      double? h,}){
    _h = h;
}

  Rain.fromJson(dynamic json) {
    _h = json['1h'] as double?;
  }
  double? _h;
Rain copyWith({  double? h,
}) => Rain(  h: h ?? _h,
);
  double? get h => _h;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['1h'] = _h;
    return map;
  }

}

/// speed : 0.62
/// deg : 349
/// gust : 1.18

class Wind {
  Wind({
      double? speed, 
      int? deg, 
      double? gust,}){
    _speed = speed;
    _deg = deg;
    _gust = gust;
}

  Wind.fromJson(dynamic json) {
    _speed = json['speed'] as double?;
    _deg = json['deg'] as int?;
    _gust = json['gust'] as double?;
  }
  double? _speed;
  int? _deg;
  double? _gust;
Wind copyWith({  double? speed,
  int? deg,
  double? gust,
}) => Wind(  speed: speed ?? _speed,
  deg: deg ?? _deg,
  gust: gust ?? _gust,
);
  double? get speed => _speed;
  int? get deg => _deg;
  double? get gust => _gust;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['speed'] = _speed;
    map['deg'] = _deg;
    map['gust'] = _gust;
    return map;
  }

}

/// temp : 298.48
/// feels_like : 298.74
/// temp_min : 297.56
/// temp_max : 300.05
/// pressure : 1015
/// humidity : 64
/// sea_level : 1015
/// grnd_level : 933

class Main {
  Main({
      double? temp,
      num? feelsLike,
      double? tempMin, 
      double? tempMax, 
      int? pressure, 
      int? humidity, 
      int? seaLevel, 
      int? grndLevel,}){
    _temp = temp;
    _feelsLike = feelsLike;
    _tempMin = tempMin;
    _tempMax = tempMax;
    _pressure = pressure;
    _humidity = humidity;
    _seaLevel = seaLevel;
    _grndLevel = grndLevel;
}

  Main.fromJson(dynamic json) {
    _temp = json['temp'] as double?;
    _feelsLike = json['feels_like'] as num?;
    _tempMin = json['temp_min'] as double?;
    _tempMax = json['temp_max'] as double?;
    _pressure = json['pressure'] as int?;
    _humidity = json['humidity'] as int?;
    _seaLevel = json['sea_level'] as int?;
    _grndLevel = json['grnd_level'] as int?;
  }
  double? _temp;
  num? _feelsLike;
  double? _tempMin;
  double? _tempMax;
  int? _pressure;
  int? _humidity;
  int? _seaLevel;
  int? _grndLevel;
Main copyWith({  double? temp,
  num? feelsLike,
  double? tempMin,
  double? tempMax,
  int? pressure,
  int? humidity,
  int? seaLevel,
  int? grndLevel,
}) => Main(  temp: temp ?? _temp,
  feelsLike: feelsLike ?? _feelsLike,
  tempMin: tempMin ?? _tempMin,
  tempMax: tempMax ?? _tempMax,
  pressure: pressure ?? _pressure,
  humidity: humidity ?? _humidity,
  seaLevel: seaLevel ?? _seaLevel,
  grndLevel: grndLevel ?? _grndLevel,
);
  double? get temp => _temp;
  num? get feelsLike => _feelsLike;
  double? get tempMin => _tempMin;
  double? get tempMax => _tempMax;
  int? get pressure => _pressure;
  int? get humidity => _humidity;
  int? get seaLevel => _seaLevel;
  int? get grndLevel => _grndLevel;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['temp'] = _temp;
    map['feels_like'] = _feelsLike;
    map['temp_min'] = _tempMin;
    map['temp_max'] = _tempMax;
    map['pressure'] = _pressure;
    map['humidity'] = _humidity;
    map['sea_level'] = _seaLevel;
    map['grnd_level'] = _grndLevel;
    return map;
  }

}

/// id : 501
/// main : "Rain"
/// description : "moderate rain"
/// icon : "10d"

class Weather {
  Weather({
      int? id, 
      String? main, 
      String? description, 
      String? icon,}){
    _id = id;
    _main = main;
    _description = description;
    _icon = icon;
}

  Weather.fromJson(dynamic json) {
    _id = json['id'] as int?;
    _main = json['main'] as String?;
    _description = json['description'] as String?;
    _icon = json['icon'] as String?;
  }
  int? _id;
  String? _main;
  String? _description;
  String? _icon;
Weather copyWith({  int? id,
  String? main,
  String? description,
  String? icon,
}) => Weather(  id: id ?? _id,
  main: main ?? _main,
  description: description ?? _description,
  icon: icon ?? _icon,
);
  int? get id => _id;
  String? get main => _main;
  String? get description => _description;
  String? get icon => _icon;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = _id;
    map['main'] = _main;
    map['description'] = _description;
    map['icon'] = _icon;
    return map;
  }

}

/// lon : 10.99
/// lat : 44.34

class Coord {
  Coord({
      double? lon, 
      double? lat,}){
    _lon = lon;
    _lat = lat;
}

  Coord.fromJson(dynamic json) {
    _lon = json['lon'] as double?;
    _lat = json['lat'] as double?;
  }
  double? _lon;
  double? _lat;
Coord copyWith({  double? lon,
  double? lat,
}) => Coord(  lon: lon ?? _lon,
  lat: lat ?? _lat,
);
  double? get lon => _lon;
  double? get lat => _lat;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['lon'] = _lon;
    map['lat'] = _lat;
    return map;
  }

}