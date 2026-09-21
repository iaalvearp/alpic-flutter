class ImageWeather {
  const ImageWeather({
    required this.provider,
    required this.timezone,
    required this.observedAt,
    required this.temperature,
    required this.apparentTemperature,
    required this.relativeHumidity,
    required this.precipitation,
    required this.windSpeed,
    required this.weatherCode,
    required this.isDay,
  });

  final String provider;
  final String timezone;
  final String observedAt;
  final WeatherMeasurement temperature;
  final WeatherMeasurement apparentTemperature;
  final WeatherMeasurement relativeHumidity;
  final WeatherMeasurement precipitation;
  final WeatherMeasurement windSpeed;
  final int weatherCode;
  final bool isDay;

  factory ImageWeather.fromApiJson(Map<String, dynamic> json) {
    final current = json['current'];
    if (current is! Map) {
      throw const FormatException('Invalid weather response');
    }
    final values = Map<String, dynamic>.from(current);
    return ImageWeather(
      provider: json['provider'] as String? ?? 'open-meteo',
      timezone: json['timezone'] as String,
      observedAt: json['observedAt'] as String,
      temperature: WeatherMeasurement.fromJson(values['temperature']),
      apparentTemperature: WeatherMeasurement.fromJson(
        values['apparentTemperature'],
      ),
      relativeHumidity: WeatherMeasurement.fromJson(values['relativeHumidity']),
      precipitation: WeatherMeasurement.fromJson(values['precipitation']),
      windSpeed: WeatherMeasurement.fromJson(values['windSpeed']),
      weatherCode: (values['weatherCode'] as num).toInt(),
      isDay: values['isDay'] as bool,
    );
  }
}

class WeatherMeasurement {
  const WeatherMeasurement({required this.value, required this.unit});

  final double value;
  final String unit;

  factory WeatherMeasurement.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid weather value');
    }
    final json = Map<String, dynamic>.from(value);
    return WeatherMeasurement(
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
    );
  }
}
