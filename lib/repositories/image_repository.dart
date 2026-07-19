import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/image_record.dart';
import '../services/image_remote_gateway.dart';

abstract interface class ImageRepository {
  Future<List<ImageRecord>> loadVisible();

  Future<ImageRecord> upload(ImageRecord image);

  Future<ImageRecord> updateMetadata(ImageRecord image);

  Future<void> softDelete(ImageRecord image);
}

class ImageLoadException implements Exception {
  const ImageLoadException();
}

class ImageUploadException implements Exception {
  const ImageUploadException();
}

class ImageMetadataUpdateException implements Exception {
  const ImageMetadataUpdateException();
}

class ImageSoftDeleteException implements Exception {
  const ImageSoftDeleteException();
}

class SupabaseImageRepository implements ImageRepository {
  SupabaseImageRepository(this._remote, {String Function()? generateId})
    : _generateId = generateId ?? const Uuid().v4,
      _now = DateTime.now;

  SupabaseImageRepository.withClock(
    this._remote,
    this._now, {
    String Function()? generateId,
  }) : _generateId = generateId ?? const Uuid().v4;

  final ImageRemoteGateway _remote;
  final String Function() _generateId;
  final DateTime Function() _now;

  @override
  Future<List<ImageRecord>> loadVisible() async {
    try {
      final ownerId = await _remote.requireAuthenticatedUserId();
      final rows = await _remote.loadVisibleImages(ownerId);
      final images =
          rows
              .where(
                (row) =>
                    row['owner_id'] == ownerId && row['is_visible'] == true,
              )
              .map(ImageRecord.fromMap)
              .toList(growable: false)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return images;
    } catch (error, stackTrace) {
      _debugLog('Visible image loading failed', error, stackTrace);
      throw const ImageLoadException();
    }
  }

  @override
  Future<ImageRecord> upload(ImageRecord image) async {
    late final String storagePath;
    late final String ownerId;
    late final String id;
    late final ImageRecord remoteDraft;
    try {
      ownerId = await _remote.requireAuthenticatedUserId();
      final file = image.localFile;
      if (file == null) throw StateError('Local image file is unavailable');

      id = _generateId();
      storagePath = '$ownerId/$id.${image.extension}';
      final bytes = await file.readAsBytes();
      await _remote.upload(
        path: storagePath,
        bytes: bytes,
        contentType: image.mimeType,
      );
    } catch (error, stackTrace) {
      _debugLog('Image upload failed', error, stackTrace);
      throw const ImageUploadException();
    }

    late final Map<String, dynamic> row;
    try {
      remoteDraft = image.copyWith(
        id: id,
        ownerId: ownerId,
        src: _remote.publicUrl(storagePath),
        storagePath: storagePath,
        uploadStatus: ImageUploadStatus.uploaded,
      );
      row = await _remote.insertImage(remoteDraft.toMap());
    } catch (error, stackTrace) {
      _debugLog('Image database insert failed', error, stackTrace);
      try {
        await _remote.remove(storagePath);
      } catch (rollbackError, rollbackStackTrace) {
        _debugLog(
          'Image upload rollback failed',
          rollbackError,
          rollbackStackTrace,
        );
      }
      throw const ImageUploadException();
    }

    try {
      return ImageRecord.fromMap(
        row,
        localFile: image.localFile,
        localPath: image.localPath,
      );
    } catch (error, stackTrace) {
      _debugLog('Image response parsing failed', error, stackTrace);
      return remoteDraft;
    }
  }

  @override
  Future<ImageRecord> updateMetadata(ImageRecord image) async {
    try {
      final id = image.id;
      final ownerId = image.ownerId;
      if (id == null || ownerId == null) {
        throw StateError('Remote image identity is unavailable');
      }

      final authenticatedUserId = await _remote.requireAuthenticatedUserId();
      if (authenticatedUserId != ownerId) {
        throw StateError('Authenticated user does not own the image');
      }

      final updatedAt = image.updatedAt.toUtc().toIso8601String();
      final row = await _remote.updateImage(
        id: id,
        ownerId: ownerId,
        values: {
          'name': image.name,
          'alt': image.alt,
          'description': image.description,
          'updated_at': updatedAt,
        },
      );
      return ImageRecord.fromMap(
        row,
        localFile: image.localFile,
        localPath: image.localPath,
      );
    } catch (error, stackTrace) {
      _debugLog('Image metadata update failed', error, stackTrace);
      throw const ImageMetadataUpdateException();
    }
  }

  @override
  Future<void> softDelete(ImageRecord image) async {
    try {
      final id = image.id;
      final ownerId = image.ownerId;
      if (id == null || ownerId == null) {
        throw StateError('Remote image identity is unavailable');
      }

      final authenticatedUserId = await _remote.requireAuthenticatedUserId();
      if (authenticatedUserId != ownerId) {
        throw StateError('Authenticated user does not own the image');
      }

      final timestamp = _now().toUtc().toIso8601String();
      await _remote.updateImage(
        id: id,
        ownerId: ownerId,
        values: {
          'is_visible': false,
          'deleted_at': timestamp,
          'updated_at': timestamp,
        },
      );
    } catch (error, stackTrace) {
      _debugLog('Image soft delete failed', error, stackTrace);
      throw const ImageSoftDeleteException();
    }
  }

  void _debugLog(String context, Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    debugPrint('$context: $error');
    debugPrint('Stack trace: $stackTrace');
  }
}
