import 'dart:convert';

import 'package:alpic_flutter/models/image_record.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el modelo genera el mapa compatible con la futura nube', () {
    final record = _record();
    final json = record.toJson();

    expect(json['id'], isNull);
    expect(json['src'], isNull);
    expect(json['latitude'], isNull);
    expect(json['longitude'], isNull);
    expect(json['maps_url'], isNull);
    expect(json['name'], 'AlPics_20260718_213045');
    expect(json['alt'], 'Alt_AlPics_20260718_213045');
    expect(json['description'], 'Descripción_AlPics_20260718_213045');
  });

  test('la representación conserva los valores más recientes', () {
    final updated = _record().copyWith(
      name: 'Parque Samanes.jpg',
      alt: 'Alt_Parque Samanes',
      description: 'Descripción_Parque Samanes',
      updatedAt: DateTime.utc(2026, 7, 19),
    );
    final decoded = jsonDecode(updated.toPrettyJson()) as Map<String, dynamic>;

    expect(decoded['name'], 'Parque Samanes.jpg');
    expect(decoded['alt'], 'Alt_Parque Samanes');
    expect(decoded['updated_at'], '2026-07-19T00:00:00.000Z');
    expect(updated.createdAt, _record().createdAt);
  });
}

ImageRecord _record() {
  final timestamp = DateTime.utc(2026, 7, 18, 21, 30, 45);
  return ImageRecord(
    name: 'AlPics_20260718_213045',
    alt: 'Alt_AlPics_20260718_213045',
    description: 'Descripción_AlPics_20260718_213045',
    mimeType: 'image/jpeg',
    extension: 'jpg',
    sizeBytes: 123456,
    source: ImageRecordSource.camera,
    originalFilename: 'photo.jpg',
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}
