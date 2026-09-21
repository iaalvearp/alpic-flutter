import '../models/image_weather.dart';
import '../services/api_client.dart';

abstract interface class ImageWeatherRepository {
  Future<ImageWeather> loadForImage(String imageId);
}

class RestImageWeatherRepository implements ImageWeatherRepository {
  const RestImageWeatherRepository(this._client);

  final ApiClient _client;

  @override
  Future<ImageWeather> loadForImage(String imageId) async {
    final response = await _client.getJson('/api/images/$imageId/weather');
    final data = response['data'];
    if (data is! Map) throw const FormatException('Invalid weather response');
    return ImageWeather.fromApiJson(Map<String, dynamic>.from(data));
  }
}
