import 'package:alpic_flutter/app/theme_controller.dart';
import 'package:alpic_flutter/services/location_service.dart';
import 'package:alpic_flutter/widgets/gps_status_tag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('la etiqueta GPS representa los tres estados', (tester) async {
    Future<void> pump(LocationAccessStatus status) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GpsStatusTag(status: status, onOpenLocationSettings: () {}),
          ),
        ),
      );
    }

    await pump(LocationAccessStatus.granted);
    expect(find.byKey(const Key('gps-verde')), findsOneWidget);

    await pump(LocationAccessStatus.serviceDisabled);
    expect(find.byKey(const Key('gps-amarillo')), findsOneWidget);
    expect(find.text('Activar'), findsOneWidget);

    await pump(LocationAccessStatus.permissionDenied);
    expect(find.byKey(const Key('gps-rojo')), findsOneWidget);
  });

  test('el tema cambia entre sistema, claro y oscuro', () {
    final controller = ThemeController();
    expect(controller.value, ThemeMode.system);

    controller.setMode(ThemeMode.light);
    expect(controller.value, ThemeMode.light);
    controller.setMode(ThemeMode.dark);
    expect(controller.value, ThemeMode.dark);
    controller.setMode(ThemeMode.system);
    expect(controller.value, ThemeMode.system);
    controller.dispose();
  });
}
