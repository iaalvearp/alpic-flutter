import 'dart:typed_data';

import 'package:alpic_flutter/models/image_record.dart';
import 'package:alpic_flutter/repositories/image_repository.dart';
import 'package:alpic_flutter/services/image_remote_gateway.dart';
import 'package:alpic_flutter/services/prepared_image_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  group('subida remota', () {
    test('sube a Storage antes de insertar la fila', () async {
      final remote = _FakeRemoteGateway();
      final repository = SupabaseImageRepository(
        remote,
        generateId: () => _imageId,
      );

      final uploaded = await repository.upload(_pendingRecord());

      expect(remote.events, ['auth', 'upload', 'insert']);
      expect(remote.uploadedPath, 'owner-123/$_imageId.png');
      expect(remote.insertedValues?['id'], _imageId);
      expect(remote.insertedValues?['storage_path'], remote.uploadedPath);
      expect(uploaded.id, _imageId);
      expect(uploaded.uploadStatus, ImageUploadStatus.uploaded);
    });

    test('un fallo de base de datos revierte el archivo subido', () async {
      final remote = _FakeRemoteGateway(failInsert: true);
      final repository = SupabaseImageRepository(
        remote,
        generateId: () => _imageId,
      );

      await expectLater(
        repository.upload(_pendingRecord()),
        throwsA(isA<ImageUploadException>()),
      );

      expect(remote.events, ['auth', 'upload', 'insert', 'remove']);
      expect(remote.removedPath, 'owner-123/$_imageId.png');
    });

    test('un fallo conserva el mismo elemento local como pendiente', () async {
      final library = PreparedImageLibrary();
      final pending = _pendingRecord();
      final remote = _FakeRemoteGateway(failUpload: true);
      final repository = SupabaseImageRepository(
        remote,
        generateId: () => _imageId,
      );
      library.add(pending);

      await expectLater(
        library.upload(pending, repository),
        throwsA(isA<ImageUploadException>()),
      );

      expect(remote.events, ['auth', 'upload']);
      expect(remote.removedPath, isNull);
      expect(library.images, hasLength(1));
      expect(library.images.single.uploadStatus, ImageUploadStatus.pending);
      expect(library.images.single.localFile, same(pending.localFile));
      library.dispose();
    });

    test('el éxito reemplaza el elemento local sin duplicarlo', () async {
      final library = PreparedImageLibrary();
      final pending = _pendingRecord();
      final uploaded = pending.copyWith(
        id: _imageId,
        ownerId: 'owner-123',
        src: 'https://example.test/image.png',
        storagePath: 'owner-123/$_imageId.png',
        uploadStatus: ImageUploadStatus.uploaded,
      );
      library.add(pending);

      await library.upload(pending, _SuccessfulRepository(uploaded));

      expect(library.images, hasLength(1));
      expect(library.images.single.id, _imageId);
      expect(library.images.single.uploadStatus, ImageUploadStatus.uploaded);
      expect(library.images.single.localFile, same(pending.localFile));
      library.dispose();
    });
  });

  group('edición remota', () {
    test('actualiza la misma fila sin volver a subir el archivo', () async {
      final original = _uploadedRecord();
      final edited = original.copyWith(
        name: 'Nombre nuevo',
        alt: 'Texto alternativo nuevo',
        description: 'Descripción nueva',
        updatedAt: DateTime.utc(2026, 7, 20),
      );
      final remote = _FakeRemoteGateway(seedRow: original.toMap());
      final repository = SupabaseImageRepository(remote);

      final result = await repository.updateMetadata(edited);

      expect(remote.events, ['auth', 'update']);
      expect(remote.uploadedPath, isNull);
      expect(remote.updatedId, _imageId);
      expect(remote.updatedValues, {
        'name': 'Nombre nuevo',
        'alt': 'Texto alternativo nuevo',
        'description': 'Descripción nueva',
        'updated_at': '2026-07-20T00:00:00.000Z',
      });
      expect(result.id, original.id);
      expect(result.storagePath, original.storagePath);
      expect(result.createdAt, original.createdAt);
      expect(result.name, 'Nombre nuevo');
    });

    test('la edición reemplaza el registro local con el mismo id', () async {
      final library = PreparedImageLibrary();
      final original = _uploadedRecord();
      final edited = original.copyWith(name: 'Nombre editado');
      library.add(original);

      await library.updateRemoteMetadata(
        original: original,
        edited: edited,
        repository: _SuccessfulRepository(edited),
      );

      expect(library.images, hasLength(1));
      expect(library.images.single.id, _imageId);
      expect(library.images.single.name, 'Nombre editado');
      library.dispose();
    });
  });

  group('carga remota', () {
    test('carga únicamente imágenes visibles del usuario actual', () async {
      final remote = _FakeRemoteGateway(
        visibleRows: [
          _remoteRow(id: 'visible-own'),
          _remoteRow(id: 'visible-other', ownerId: 'other-owner'),
          _remoteRow(id: 'hidden-own', isVisible: false),
        ],
      );
      final repository = SupabaseImageRepository(remote);

      final images = await repository.loadVisible();

      expect(remote.events, ['auth', 'load']);
      expect(remote.requestedOwnerId, 'owner-123');
      expect(images.map((image) => image.id), ['visible-own']);
      expect(images.single.isVisible, isTrue);
    });

    test('la carga reemplaza la lista local y evita duplicados', () async {
      final remote = _FakeRemoteGateway(
        visibleRows: [
          _remoteRow(id: 'remote-image'),
          _remoteRow(id: 'remote-image'),
        ],
      );
      final repository = SupabaseImageRepository(remote);
      final library = PreparedImageLibrary()..add(_pendingRecord());

      library.replaceAll(await repository.loadVisible());

      expect(library.images, hasLength(1));
      expect(library.images.single.id, 'remote-image');
      expect(library.images.single.uploadStatus, ImageUploadStatus.uploaded);
      library.dispose();
    });
  });

  group('borrado lógico', () {
    test('oculta la fila, fija deleted_at y nunca elimina Storage', () async {
      final original = _uploadedRecord();
      final remote = _FakeRemoteGateway(seedRow: original.toMap());
      final repository = SupabaseImageRepository.withClock(
        remote,
        () => DateTime.utc(2026, 7, 21, 12, 30),
      );

      await repository.softDelete(original);

      expect(remote.events, ['auth', 'update']);
      expect(remote.updatedId, _imageId);
      expect(remote.updatedValues, {
        'is_visible': false,
        'deleted_at': '2026-07-21T12:30:00.000Z',
        'updated_at': '2026-07-21T12:30:00.000Z',
      });
      expect(remote.removedPath, isNull);
    });

    test('si falla, el elemento permanece visible en la lista', () async {
      final original = _uploadedRecord();
      final remote = _FakeRemoteGateway(
        failUpdate: true,
        seedRow: original.toMap(),
      );
      final repository = SupabaseImageRepository(remote);
      final library = PreparedImageLibrary()..add(original);

      await expectLater(
        library.softDelete(original, repository),
        throwsA(isA<ImageSoftDeleteException>()),
      );

      expect(library.images, hasLength(1));
      expect(library.images.single.isVisible, isTrue);
      expect(remote.removedPath, isNull);
      library.dispose();
    });
  });
}

const _imageId = '11111111-2222-3333-4444-555555555555';

ImageRecord _pendingRecord() {
  final timestamp = DateTime.utc(2026, 7, 18, 21, 30, 45);
  return ImageRecord(
    name: 'AlPics_20260718_213045',
    alt: 'Una imagen',
    description: 'Descripción distinta',
    mimeType: 'image/png',
    extension: 'png',
    sizeBytes: 4,
    source: ImageRecordSource.gallery,
    localFile: XFile.fromData(
      Uint8List.fromList([1, 2, 3, 4]),
      name: 'foto.png',
      mimeType: 'image/png',
    ),
    originalFilename: 'foto.png',
    createdAt: timestamp,
    updatedAt: timestamp,
  );
}

ImageRecord _uploadedRecord() => _pendingRecord().copyWith(
  id: _imageId,
  ownerId: 'owner-123',
  src: 'https://example.test/image.png',
  storagePath: 'owner-123/$_imageId.png',
  uploadStatus: ImageUploadStatus.uploaded,
);

Map<String, dynamic> _remoteRow({
  required String id,
  String ownerId = 'owner-123',
  bool isVisible = true,
}) {
  return {
    ..._uploadedRecord().toMap(),
    'id': id,
    'owner_id': ownerId,
    'is_visible': isVisible,
    'deleted_at': isVisible ? null : '2026-07-20T00:00:00.000Z',
  };
}

class _FakeRemoteGateway implements ImageRemoteGateway {
  _FakeRemoteGateway({
    this.failUpload = false,
    this.failInsert = false,
    this.failUpdate = false,
    this.visibleRows = const [],
    Map<String, Object?>? seedRow,
  }) : _row = seedRow == null ? null : Map<String, dynamic>.from(seedRow);

  final bool failUpload;
  final bool failInsert;
  final bool failUpdate;
  final List<Map<String, dynamic>> visibleRows;
  final List<String> events = [];
  final Map<String, dynamic>? _row;
  String? uploadedPath;
  String? removedPath;
  String? updatedId;
  Map<String, Object?>? insertedValues;
  Map<String, Object?>? updatedValues;
  String? requestedOwnerId;

  @override
  Future<String> requireAuthenticatedUserId() async {
    events.add('auth');
    return 'owner-123';
  }

  @override
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    events.add('upload');
    uploadedPath = path;
    if (failUpload) throw StateError('storage upload failed');
  }

  @override
  String publicUrl(String path) => 'https://example.test/$path';

  @override
  Future<Map<String, dynamic>> insertImage(Map<String, Object?> values) async {
    events.add('insert');
    insertedValues = values;
    if (failInsert) throw StateError('database insert failed');
    return Map<String, dynamic>.from(values);
  }

  @override
  Future<List<Map<String, dynamic>>> loadVisibleImages(String ownerId) async {
    events.add('load');
    requestedOwnerId = ownerId;
    return visibleRows;
  }

  @override
  Future<Map<String, dynamic>> updateImage({
    required String id,
    required String ownerId,
    required Map<String, Object?> values,
  }) async {
    events.add('update');
    updatedId = id;
    updatedValues = values;
    if (failUpdate) throw StateError('database update failed');
    return {...?_row, ...values};
  }

  @override
  Future<void> remove(String path) async {
    events.add('remove');
    removedPath = path;
  }
}

class _SuccessfulRepository implements ImageRepository {
  _SuccessfulRepository(this.result);

  final ImageRecord result;

  @override
  Future<List<ImageRecord>> loadVisible() async => [result];

  @override
  Future<ImageRecord> upload(ImageRecord image) async => result;

  @override
  Future<ImageRecord> updateMetadata(ImageRecord image) async => result;

  @override
  Future<void> softDelete(ImageRecord image) async {}
}
