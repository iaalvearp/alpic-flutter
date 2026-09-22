import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/image_record.dart';

Map<String, Object?> imageToJsonMap(ImageRecord image) {
  return {
    'id': image.id,
    'ownerId': image.ownerId,
    'name': image.name,
    'alt': image.alt,
    'description': image.description,
    'src': image.src,
    'storagePath': image.storagePath,
    'extension': image.extension,
    'mimeType': image.mimeType,
    'sizeBytes': image.sizeBytes,
    'latitude': image.latitude,
    'longitude': image.longitude,
    'mapsUrl': image.mapsUrl,
    'source': image.source.jsonValue,
    'originalFilename': image.originalFilename,
    'createdAt': image.createdAt.toUtc().toIso8601String(),
    'updatedAt': image.updatedAt.toUtc().toIso8601String(),
    'isVisible': image.isVisible,
    'deletedAt': image.deletedAt?.toUtc().toIso8601String(),
  };
}

String exportJson(List<ImageRecord> images) {
  final Object payload =
      images.length == 1
          ? imageToJsonMap(images.single)
          : images.map(imageToJsonMap).toList();
  return const JsonEncoder.withIndent('  ').convert(payload);
}

String exportFilename(List<ImageRecord> images) {
  if (images.length == 1 && images.single.id != null) {
    return 'alpic-${images.single.id}.json';
  }
  final stamp = DateTime.now()
      .toUtc()
      .toIso8601String()
      .replaceAll(':', '-')
      .split('.')
      .first;
  return 'alpic-export-${images.length}-$stamp.json';
}

Future<File> writeExportFile(List<ImageRecord> images) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/${exportFilename(images)}');
  await file.writeAsString(exportJson(images));
  return file;
}

Future<ShareResult> shareExportFile(List<ImageRecord> images) async {
  final file = await writeExportFile(images);
  return SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'application/json')],
    ),
  );
}