import 'package:alpic_flutter/models/image_record.dart';
import 'package:alpic_flutter/services/prepared_image_library.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('editar una imagen actualiza sin duplicar', () {
    final library = PreparedImageLibrary();
    final original = _record();
    library.add(original);

    final updated = original.copyWith(
      name: 'Nombre actualizado',
      updatedAt: DateTime.utc(2026, 7, 19),
    );
    library.update(updated);

    expect(library.images, hasLength(1));
    expect(library.images.single.name, 'Nombre actualizado');
    expect(library.images.single.createdAt, original.createdAt);
    library.dispose();
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
