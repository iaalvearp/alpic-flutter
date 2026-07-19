import 'dart:convert';

import 'package:alpic_flutter/app/alpics_app.dart';
import 'package:alpic_flutter/models/image_record.dart';
import 'package:alpic_flutter/services/image_picker_service.dart';
import 'package:alpic_flutter/services/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  testWidgets('la galería funciona aunque la ubicación esté denegada', (
    tester,
  ) async {
    await tester.pumpWidget(
      AlPicsApp(
        locationService: _DeniedLocationService(),
        imagePickerService: _FakeImagePickerService(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Elegir de la galería'));
    await tester.pumpAndSettle();

    expect(find.text('Nueva imagen'), findsOneWidget);
    expect(find.text('Guardar imagen'), findsOneWidget);
  });

  testWidgets('la cámara abre el mismo flujo de creación', (tester) async {
    await tester.pumpWidget(
      AlPicsApp(
        locationService: _DeniedLocationService(),
        imagePickerService: _FakeImagePickerService(),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Tomar foto'));
    await tester.pumpAndSettle();

    expect(find.text('Nueva imagen'), findsOneWidget);
    expect(find.text('Guardar imagen'), findsOneWidget);
  });
}

class _FakeImagePickerService implements ImagePickerService {
  @override
  Future<ImagePickResult> pick(ImageRecordSource source) async {
    return ImagePickResult(
      image: PickedLocalImage(
        file: XFile.fromData(
          base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
          ),
          name: 'foto.png',
          mimeType: 'image/png',
        ),
        source: source,
      ),
    );
  }
}

class _DeniedLocationService implements LocationService {
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
