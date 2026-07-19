import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/image_record.dart';

class PickedLocalImage {
  const PickedLocalImage({required this.file, required this.source});

  final XFile file;
  final ImageRecordSource source;
}

class ImagePickResult {
  const ImagePickResult({this.image, this.errorMessage});

  final PickedLocalImage? image;
  final String? errorMessage;

  bool get wasCancelled => image == null && errorMessage == null;
}

abstract interface class ImagePickerService {
  Future<ImagePickResult> pick(ImageRecordSource source);
}

class DeviceImagePickerService implements ImagePickerService {
  DeviceImagePickerService({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<ImagePickResult> pick(ImageRecordSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == ImageRecordSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
      );

      if (file == null) return const ImagePickResult();
      return ImagePickResult(
        image: PickedLocalImage(file: file, source: source),
      );
    } catch (error) {
      debugPrint('No se pudo abrir el selector de imágenes: $error');
      return ImagePickResult(
        errorMessage: source == ImageRecordSource.camera
            ? 'No se pudo acceder a la cámara.'
            : 'No fue posible abrir la galería.',
      );
    }
  }
}
