import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import '../models/image_record.dart';
import '../services/image_picker_service.dart';
import 'image_name_generator.dart';

class ImageMetadataException implements Exception {
  const ImageMetadataException(this.message);

  final String message;
}

Future<ImageRecord> buildLocalImageRecord({
  required PickedLocalImage image,
  Position? position,
  DateTime? createdAt,
}) async {
  try {
    final bytes = await image.file.readAsBytes();
    if (bytes.isEmpty) {
      throw const ImageMetadataException('La imagen seleccionada está vacía.');
    }

    final originalFilename = image.file.name;
    final extension = path
        .extension(originalFilename)
        .replaceFirst('.', '')
        .toLowerCase();
    final mimeType =
        lookupMimeType(
          originalFilename,
          headerBytes: bytes.take(16).toList(growable: false),
        ) ??
        'application/octet-stream';
    final timestamp = (createdAt ?? DateTime.now()).toUtc();
    final latitude = position?.latitude;
    final longitude = position?.longitude;
    final hasCompleteLocation = latitude != null && longitude != null;
    final name = generateDefaultImageName(timestamp.toLocal());
    final localPath = image.file.path.trim();

    return ImageRecord(
      name: name,
      alt: generateDefaultAlt(name),
      description: generateDefaultDescription(name),
      mimeType: mimeType,
      extension: extension,
      sizeBytes: bytes.length,
      latitude: hasCompleteLocation ? latitude : null,
      longitude: hasCompleteLocation ? longitude : null,
      mapsUrl: hasCompleteLocation
          ? 'https://www.google.com/maps?q=$latitude,$longitude'
          : null,
      source: image.source,
      localPath: localPath.isEmpty ? null : localPath,
      localFile: image.file,
      originalFilename: originalFilename,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  } on ImageMetadataException {
    rethrow;
  } catch (error) {
    debugPrint('No se pudo leer la imagen: $error');
    throw const ImageMetadataException('No fue posible abrir la imagen.');
  }
}
