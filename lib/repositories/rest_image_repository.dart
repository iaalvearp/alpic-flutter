import 'package:flutter/foundation.dart';

import '../models/image_record.dart';
import '../services/api_client.dart';
import 'image_repository.dart';

class RestImageRepository implements ImageRepository {
  const RestImageRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<ImageRecord>> loadVisible() async {
    try {
      final response = await _client.getJson('/api/images');
      final data = response['data'];
      if (data is! List) throw const FormatException('Invalid image list');
      return data
          .map(
            (item) =>
                ImageRecord.fromApiJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(growable: false);
    } catch (error, stackTrace) {
      _debugLog('REST image loading failed', error, stackTrace);
      throw const ImageLoadException();
    }
  }

  @override
  Future<ImageRecord> upload(ImageRecord image) async {
    try {
      final file = image.localFile;
      if (file == null) throw StateError('Local image file is unavailable');
      final response = await _client.postMultipart(
        path: '/api/images',
        fields: {
          'name': image.name,
          'alt': image.alt,
          'description': image.description,
          'source': image.source.jsonValue,
          if (image.latitude != null) 'latitude': '${image.latitude}',
          if (image.longitude != null) 'longitude': '${image.longitude}',
          if (image.mapsUrl != null) 'mapsUrl': image.mapsUrl!,
        },
        bytes: await file.readAsBytes(),
        filename: image.originalFilename,
        contentType: image.mimeType,
      );
      return ImageRecord.fromApiJson(
        _data(response),
        localFile: file,
        localPath: image.localPath,
      );
    } catch (error, stackTrace) {
      _debugLog('REST image upload failed', error, stackTrace);
      throw const ImageUploadException();
    }
  }

  @override
  Future<ImageRecord> updateMetadata(ImageRecord image) async {
    try {
      final id = image.id;
      if (id == null) throw StateError('Remote image identity is unavailable');
      final response = await _client.putJson('/api/images/$id', {
        'name': image.name,
        'alt': image.alt,
        'description': image.description,
      });
      return ImageRecord.fromApiJson(
        _data(response),
        localFile: image.localFile,
        localPath: image.localPath,
      );
    } catch (error, stackTrace) {
      _debugLog('REST image metadata update failed', error, stackTrace);
      throw const ImageMetadataUpdateException();
    }
  }

  @override
  Future<void> softDelete(ImageRecord image) async {
    try {
      final id = image.id;
      if (id == null) throw StateError('Remote image identity is unavailable');
      await _client.delete('/api/images/$id');
    } catch (error, stackTrace) {
      _debugLog('REST image soft delete failed', error, stackTrace);
      throw const ImageSoftDeleteException();
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is! Map) throw const FormatException('Invalid image response');
    return Map<String, dynamic>.from(data);
  }

  void _debugLog(String context, Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    debugPrint('$context: $error');
    debugPrint('Stack trace: $stackTrace');
  }
}
