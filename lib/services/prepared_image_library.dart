import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/image_record.dart';
import '../repositories/image_repository.dart';

class PreparedImageLibrary extends ChangeNotifier {
  final List<ImageRecord> _images = [];

  UnmodifiableListView<ImageRecord> get images => UnmodifiableListView(_images);

  void add(ImageRecord image) {
    _images.insert(0, image);
    notifyListeners();
  }

  void replaceAll(Iterable<ImageRecord> images) {
    _images.clear();
    for (final image in images) {
      if (!_images.any(image.hasSameIdentityAs)) _images.add(image);
    }
    notifyListeners();
  }

  void update(ImageRecord image) {
    final index = _images.indexWhere(image.hasSameIdentityAs);
    if (index == -1) return;

    // A future remote update must target image.id instead of inserting again.
    _images[index] = image;
    notifyListeners();
  }

  Future<ImageRecord> upload(
    ImageRecord image,
    ImageRepository repository,
  ) async {
    update(image.copyWith(uploadStatus: ImageUploadStatus.uploading));
    try {
      final uploaded = await repository.upload(image);
      update(uploaded);
      return uploaded;
    } catch (_) {
      update(image.copyWith(uploadStatus: ImageUploadStatus.pending));
      rethrow;
    }
  }

  Future<ImageRecord> updateRemoteMetadata({
    required ImageRecord original,
    required ImageRecord edited,
    required ImageRepository repository,
  }) async {
    update(edited.copyWith(uploadStatus: ImageUploadStatus.uploading));
    try {
      final updated = await repository.updateMetadata(edited);
      update(updated);
      return updated;
    } catch (_) {
      update(original);
      rethrow;
    }
  }

  Future<void> softDelete(ImageRecord image, ImageRepository repository) async {
    await repository.softDelete(image);
    _images.removeWhere(image.hasSameIdentityAs);
    notifyListeners();
  }
}
