import 'dart:async';

import 'package:alpic_flutter/app/alpics_app.dart';
import 'package:alpic_flutter/models/image_record.dart';
import 'package:alpic_flutter/repositories/image_repository.dart';
import 'package:alpic_flutter/services/location_service.dart';
import 'package:alpic_flutter/services/prepared_image_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la aplicación no bloquea cuando se deniega la ubicación', (
    tester,
  ) async {
    await tester.pumpWidget(
      AlPicsApp(locationService: _FakeLocationService.denied()),
    );
    await tester.pump();

    expect(find.text('Tomar foto'), findsOneWidget);
    expect(find.text('Elegir de la galería'), findsOneWidget);
    expect(find.byKey(const Key('gps-rojo')), findsOneWidget);
  });

  testWidgets('la interfaz anterior ya no aparece', (tester) async {
    await tester.pumpWidget(
      AlPicsApp(locationService: _FakeLocationService.denied()),
    );
    await tester.pump();

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Grant permission'), findsNothing);
  });

  testWidgets('un fallo de conexión no bloquea y muestra un aviso amigable', (
    tester,
  ) async {
    const message =
        'No pudimos conectarnos en este momento. Puedes seguir usando la aplicación.';
    await tester.pumpWidget(
      AlPicsApp(
        locationService: _FakeLocationService.denied(),
        startupMessage: message,
      ),
    );
    await tester.pump();

    expect(find.text('Tomar foto'), findsOneWidget);
    expect(find.text(message), findsOneWidget);
  });

  testWidgets('el diagnóstico temporal de autenticación ya no se muestra', (
    tester,
  ) async {
    await tester.pumpWidget(
      AlPicsApp(locationService: _FakeLocationService.denied()),
    );
    await tester.pump();

    expect(find.byKey(const Key('auth-diagnostic')), findsNothing);
    expect(find.textContaining('Auth:'), findsNothing);
    expect(find.text('AlPics'), findsOneWidget);
  });

  testWidgets('la carga inicial reemplaza la lista local sin duplicados', (
    tester,
  ) async {
    final library = PreparedImageLibrary()..add(_record(id: null));
    final repository = _LoadingImageRepository();
    await tester.pumpWidget(
      AlPicsApp(
        locationService: _FakeLocationService.denied(),
        imageLibrary: library,
        imageRepository: repository,
        authenticatedUserId: 'owner-123',
      ),
    );
    await tester.pump();

    expect(find.text('Cargando imágenes...'), findsOneWidget);

    repository.complete([_record(id: 'remote-id'), _record(id: 'remote-id')]);
    await tester.pumpAndSettle();

    expect(library.images, hasLength(1));
    expect(library.images.single.id, 'remote-id');
    expect(find.text('1 guardadas'), findsOneWidget);
    library.dispose();
  });
}

ImageRecord _record({required String? id}) {
  final timestamp = DateTime.utc(2026, 7, 18);
  return ImageRecord(
    id: id,
    ownerId: id == null ? null : 'owner-123',
    name: 'Imagen',
    alt: 'Texto alternativo',
    description: 'Descripción',
    mimeType: 'image/png',
    extension: 'png',
    sizeBytes: 4,
    source: ImageRecordSource.gallery,
    originalFilename: 'foto.png',
    createdAt: timestamp,
    updatedAt: timestamp,
    uploadStatus: id == null
        ? ImageUploadStatus.pending
        : ImageUploadStatus.uploaded,
  );
}

class _LoadingImageRepository implements ImageRepository {
  final _completer = Completer<List<ImageRecord>>();

  void complete(List<ImageRecord> images) => _completer.complete(images);

  @override
  Future<List<ImageRecord>> loadVisible() => _completer.future;

  @override
  Future<void> softDelete(ImageRecord image) async {}

  @override
  Future<ImageRecord> updateMetadata(ImageRecord image) async => image;

  @override
  Future<ImageRecord> upload(ImageRecord image) async => image;
}

class _FakeLocationService implements LocationService {
  _FakeLocationService.denied();

  @override
  Future<LocationAccessResult> checkAndRequestAccess({
    bool obtainPosition = true,
  }) async {
    return const LocationAccessResult(LocationAccessStatus.permissionDenied);
  }

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;
}
