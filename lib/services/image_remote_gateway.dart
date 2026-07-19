import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ImageRemoteGateway {
  Future<String> requireAuthenticatedUserId();

  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  });

  String publicUrl(String path);

  Future<Map<String, dynamic>> insertImage(Map<String, Object?> values);

  Future<List<Map<String, dynamic>>> loadVisibleImages(String ownerId);

  Future<Map<String, dynamic>> updateImage({
    required String id,
    required String ownerId,
    required Map<String, Object?> values,
  });

  Future<void> remove(String path);
}

class SupabaseImageRemoteGateway implements ImageRemoteGateway {
  SupabaseImageRemoteGateway(this._client);

  static const _bucketName = 'alpics-images';
  static const _tableName = 'images';

  final SupabaseClient _client;

  @override
  Future<String> requireAuthenticatedUserId() async {
    final response = await _client.auth.getUser();
    final user = response.user;
    if (user == null) throw StateError('No authenticated user');
    return user.id;
  }

  @override
  Future<void> upload({
    required String path,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _client.storage
        .from(_bucketName)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
  }

  @override
  String publicUrl(String path) =>
      _client.storage.from(_bucketName).getPublicUrl(path);

  @override
  Future<Map<String, dynamic>> insertImage(Map<String, Object?> values) async {
    final row = await _client.from(_tableName).insert(values).select().single();
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<List<Map<String, dynamic>>> loadVisibleImages(String ownerId) async {
    final rows = await _client
        .from(_tableName)
        .select()
        .eq('owner_id', ownerId)
        .eq('is_visible', true)
        .order('created_at', ascending: false);
    return rows.map(Map<String, dynamic>.from).toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> updateImage({
    required String id,
    required String ownerId,
    required Map<String, Object?> values,
  }) async {
    final row = await _client
        .from(_tableName)
        .update(values)
        .eq('id', id)
        .eq('owner_id', ownerId)
        .select()
        .single();
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<void> remove(String path) async {
    await _client.storage.from(_bucketName).remove([path]);
  }
}
