class City {
  final int id;
  final String name;
  final String uf;

  const City({required this.id, required this.name, required this.uf});

  String get label => uf.isEmpty ? name : '$name - $uf';

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'uf': uf};

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json['id'] as int,
        name: json['name'] as String,
        uf: json['uf'] as String,
      );
}

class DayForecast {
  final DateTime date;
  final String? code;
  final double? min;
  final double? max;
  final double? uv;

  const DayForecast({
    required this.date,
    this.code,
    this.min,
    this.max,
    this.uv,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'code': code,
        'min': min,
        'max': max,
        'uv': uv,
      };

  factory DayForecast.fromJson(Map<String, dynamic> json) => DayForecast(
        date: DateTime.parse(json['date'] as String),
        code: json['code'] as String?,
        min: (json['min'] as num?)?.toDouble(),
        max: (json['max'] as num?)?.toDouble(),
        uv: (json['uv'] as num?)?.toDouble(),
      );
}

class Forecast {
  final int cityId;
  final String cityName;
  final String uf;
  final DateTime? updatedAt;
  final List<DayForecast> days;

  const Forecast({
    required this.cityId,
    required this.cityName,
    required this.uf,
    required this.updatedAt,
    required this.days,
  });

  Map<String, dynamic> toJson() => {
        'cityId': cityId,
        'cityName': cityName,
        'uf': uf,
        'updatedAt': updatedAt?.toIso8601String(),
        'days': days.map((d) => d.toJson()).toList(),
      };

  factory Forecast.fromJson(Map<String, dynamic> json) => Forecast(
        cityId: json['cityId'] as int,
        cityName: json['cityName'] as String,
        uf: json['uf'] as String,
        updatedAt: json['updatedAt'] == null
            ? null
            : DateTime.tryParse(json['updatedAt'] as String),
        days: (json['days'] as List<dynamic>)
            .map((d) => DayForecast.fromJson(d as Map<String, dynamic>))
            .toList(),
      );
}
