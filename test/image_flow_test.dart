import 'package:alpic_flutter/models/image_record.dart';
import 'package:alpic_flutter/screens/image_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el formulario usa los títulos de creación y edición', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ImageFormScreen(record: _record(), mode: ImageFormMode.create),
      ),
    );
    expect(find.text('Nueva imagen'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: ImageFormScreen(record: _record(), mode: ImageFormMode.edit),
      ),
    );
    expect(find.text('Editar imagen'), findsOneWidget);
  });

  testWidgets('el nombre actualiza los valores automáticos sin extensión', (
    tester,
  ) async {
    await _pumpForm(tester);

    await tester.enterText(
      find.byKey(const Key('campo-nombre')),
      'Parque Samanes.jpg',
    );

    expect(_text(tester, 'campo-alternativo'), 'Alt_Parque Samanes');
    expect(_text(tester, 'campo-descripcion'), 'Descripción_Parque Samanes');
  });

  testWidgets('los campos editados manualmente no se sobrescriben', (
    tester,
  ) async {
    await _pumpForm(tester);

    await tester.enterText(
      find.byKey(const Key('campo-alternativo')),
      'Un parque al atardecer',
    );
    await tester.enterText(
      find.byKey(const Key('campo-descripcion')),
      'Contexto escrito por la persona',
    );
    await tester.enterText(
      find.byKey(const Key('campo-nombre')),
      'Nombre nuevo.png',
    );

    expect(_text(tester, 'campo-alternativo'), 'Un parque al atardecer');
    expect(
      _text(tester, 'campo-descripcion'),
      'Contexto escrito por la persona',
    );
  });

  testWidgets('el formulario oculta la información técnica', (tester) async {
    await _pumpForm(tester);

    expect(find.text('MIME type'), findsNothing);
    expect(find.text('Latitude'), findsNothing);
    expect(find.text('Longitude'), findsNothing);
    expect(find.text('Google Maps URL'), findsNothing);
    expect(find.text('JSON preview'), findsNothing);
  });
}

Future<void> _pumpForm(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ImageFormScreen(record: _record(), mode: ImageFormMode.create),
    ),
  );
}

String _text(WidgetTester tester, String key) {
  return tester.widget<TextFormField>(find.byKey(Key(key))).controller!.text;
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
    source: ImageRecordSource.gallery,
    originalFilename: 'photo.jpg',
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}
