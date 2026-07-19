import 'package:alpic_flutter/utils/image_name_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('genera el nombre con el formato requerido', () {
    final name = generateDefaultImageName(DateTime(2026, 7, 18, 21, 30, 45));
    expect(name, 'AlPics_20260718_213045');
  });

  test('genera valores visibles independientes', () {
    const name = 'AlPics_20260718_213045';
    expect(generateDefaultAlt(name), 'Alt_AlPics_20260718_213045');
    expect(
      generateDefaultDescription(name),
      'Descripción_AlPics_20260718_213045',
    );
  });

  test('elimina solo la extensión final y conserva espacios', () {
    expect(removeFinalExtension('  Parque Samanes.jpg  '), 'Parque Samanes');
    expect(generateDefaultAlt('Mi foto.final.webp'), 'Alt_Mi foto.final');
    expect(
      generateDefaultDescription('Parque Samanes.png'),
      'Descripción_Parque Samanes',
    );
  });

  test('mantiene disponible la sanitización para nombres futuros', () {
    expect(
      sanitizeImageName('  Beach photo: July/18.jpg  '),
      'Beach_photo_July_18_jpg',
    );
    expect(sanitizeImageName('***'), isEmpty);
  });
}
