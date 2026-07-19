import 'package:intl/intl.dart';

String generateDefaultImageName([DateTime? dateTime]) {
  final value = dateTime ?? DateTime.now();
  return 'AlPics_${DateFormat('yyyyMMdd_HHmmss').format(value)}';
}

String removeFinalExtension(String value) {
  return value.trim().replaceFirst(RegExp(r'\.[^\.\s]+$'), '');
}

String generateDefaultAlt(String imageName) {
  return 'Alt_${removeFinalExtension(imageName)}';
}

String generateDefaultDescription(String imageName) {
  return 'Descripción_${removeFinalExtension(imageName)}';
}

String sanitizeImageName(String value) {
  return value
      .trim()
      .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
      .replaceAll(RegExp('_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}
