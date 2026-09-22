import 'package:alpic_flutter/models/image_record.dart';
import 'package:alpic_flutter/repositories/image_repository.dart';
import 'package:alpic_flutter/screens/image_list_screen.dart';
import 'package:alpic_flutter/services/prepared_image_library.dart';
import 'package:alpic_flutter/utils/image_export.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('exportación JSON', () {
    test('incluye toda la información de la imagen en camelCase', () {
      final image = _record(id: 'abc-123');

      final json = exportJson([image]);

      expect(json, contains('"id": "abc-123"'));
      expect(json, contains('"ownerId": "owner-1"'));
      expect(json, contains('"name": "Imagen abc-123"'));
      expect(json, contains('"alt": "Alternativa"'));
      expect(json, contains('"description": "Descripción"'));
      expect(json, contains('"src": "https://cdn.example/foto.jpg"'));
      expect(json, contains('"storagePath": "imagenes/foto.jpg"'));
      expect(json, contains('"extension": "jpg"'));
      expect(json, contains('"mimeType": "image/jpeg"'));
      expect(json, contains('"sizeBytes": 1234'));
      expect(json, contains('"latitude": -2.16'));
      expect(json, contains('"longitude": -78.46'));
      expect(json, contains('"mapsUrl": "https://maps.example/2"'));
      expect(json, contains('"source": "gallery"'));
      expect(json, contains('"originalFilename": "foto-abc-123.jpg"'));
      expect(json, contains('"createdAt":'));
      expect(json, contains('"updatedAt":'));
      expect(json, contains('"isVisible": true'));
      expect(json, contains('"deletedAt":'));
    });

    test('un lote exporta un array', () {
      final json = exportJson([_record(id: 'a'), _record(id: 'b')]);

      expect(json.startsWith('['), isTrue);
      expect(json.contains('"id": "a"'), isTrue);
      expect(json.contains('"id": "b"'), isTrue);
    });
  });

  group('pantalla de imágenes', () {
    testWidgets('el menú ofrece Exportar JSON y ya no Consultar clima', (
      tester,
    ) async {
      await _pumpScreen(tester, [_record(id: 'a')]);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Exportar JSON'), findsOneWidget);
      expect(find.text('Consultar clima'), findsNothing);
    });

    testWidgets('mantener pulsado más de un segundo entra al modo selección', (
      tester,
    ) async {
      await _pumpScreen(tester, [_record(id: 'a'), _record(id: 'b')]);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Imagen a')),
      );
      await tester.pump(const Duration(milliseconds: 1100));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('1 seleccionada'), findsOneWidget);
      expect(find.byKey(const Key('exportar-seleccion')), findsOneWidget);
      expect(find.byKey(const Key('eliminar-seleccion')), findsOneWidget);
    });

    testWidgets('en modo selección un toque añade otra imagen', (
      tester,
    ) async {
      await _pumpScreen(tester, [_record(id: 'a'), _record(id: 'b')]);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Imagen a')),
      );
      await tester.pump(const Duration(milliseconds: 1100));
      await gesture.up();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      await tester.tap(find.text('Imagen b'));
      await tester.pumpAndSettle();

      expect(find.text('2 seleccionadas'), findsOneWidget);
    });

    testWidgets('exportar abre el diálogo con el JSON y las acciones', (
      tester,
    ) async {
      await _pumpScreen(tester, [_record(id: 'abc-123')]);

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Exportar JSON'));
      await tester.pumpAndSettle();

      expect(find.text('Exportar JSON'), findsOneWidget);
      expect(find.text('Copiar'), findsOneWidget);
      expect(find.text('Guardar / Compartir'), findsOneWidget);
      expect(find.textContaining('"id": "abc-123"'), findsOneWidget);
    });
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  List<ImageRecord> records,
) async {
  final library = PreparedImageLibrary()..replaceAll(records);
  final repository = _FakeImageRepository()..images.addAll(records);
  await tester.pumpWidget(
    MaterialApp(
      home: ImageListScreen(
        library: library,
        imageRepository: repository,
        authenticatedUserId: 'owner-1',
      ),
    ),
  );
  await tester.pump();
  addTearDown(library.dispose);
}

ImageRecord _record({required String id}) {
  final offset = id == 'abc-123' ? 0 : id.codeUnitAt(0) - 'a'.codeUnitAt(0);
  final timestamp = DateTime.utc(
    2026,
    7,
    18,
    21,
    30,
    45,
    offset,
  );
  return ImageRecord(
    id: id,
    ownerId: 'owner-1',
    src: 'https://cdn.example/foto.jpg',
    storagePath: 'imagenes/foto.jpg',
    name: 'Imagen $id',
    alt: 'Alternativa',
    description: 'Descripción',
    mimeType: 'image/jpeg',
    extension: 'jpg',
    sizeBytes: 1234,
    latitude: -2.16,
    longitude: -78.46,
    mapsUrl: 'https://maps.example/2',
    source: ImageRecordSource.gallery,
    originalFilename: 'foto-$id.jpg',
    createdAt: timestamp,
    updatedAt: timestamp,
    uploadStatus: ImageUploadStatus.uploaded,
  );
}

class _FakeImageRepository implements ImageRepository {
  final List<ImageRecord> images = [];

  @override
  Future<List<ImageRecord>> loadVisible() async => images;

  @override
  Future<void> softDelete(ImageRecord image) async {}

  @override
  Future<ImageRecord> updateMetadata(ImageRecord image) async => image;

  @override
  Future<ImageRecord> upload(ImageRecord image) async => image;
}