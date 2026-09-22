import 'dart:convert';

import 'package:image_picker/image_picker.dart';

enum ImageRecordSource {
  camera,
  gallery;

  String get jsonValue => name;
}

enum ImageUploadStatus { pending, uploading, uploaded, failed }

class ImageRecord {
  const ImageRecord({
    required this.name,
    required this.alt,
    required this.description,
    required this.mimeType,
    required this.extension,
    required this.sizeBytes,
    required this.source,
    required this.originalFilename,
    required this.createdAt,
    required this.updatedAt,
    this.id,
    this.ownerId,
    this.src,
    this.storagePath,
    this.uploadStatus = ImageUploadStatus.pending,
    this.isVisible = true,
    this.deletedAt,
    this.latitude,
    this.longitude,
    this.mapsUrl,
    this.localPath,
    this.localFile,
  });

  final String? id;
  final String? ownerId;
  final String? src;
  final String? storagePath;
  final ImageUploadStatus uploadStatus;
  final bool isVisible;
  final DateTime? deletedAt;
  final String name;
  final String alt;
  final String description;
  final String mimeType;
  final String extension;
  final int sizeBytes;
  final double? latitude;
  final double? longitude;
  final String? mapsUrl;
  final ImageRecordSource source;
  final String? localPath;
  final XFile? localFile;
  final String originalFilename;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool hasSameIdentityAs(ImageRecord other) {
    if (id != null && other.id != null) return id == other.id;
    return createdAt == other.createdAt &&
        originalFilename == other.originalFilename;
  }

  static const Object _unset = Object();

  ImageRecord copyWith({
    String? id,
    String? ownerId,
    String? src,
    String? storagePath,
    String? name,
    String? alt,
    String? description,
    ImageUploadStatus? uploadStatus,
    bool? isVisible,
    DateTime? deletedAt,
    DateTime? updatedAt,
    Object? latitude = _unset,
    Object? longitude = _unset,
    Object? mapsUrl = _unset,
  }) {
    return ImageRecord(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      src: src ?? this.src,
      storagePath: storagePath ?? this.storagePath,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      isVisible: isVisible ?? this.isVisible,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      alt: alt ?? this.alt,
      description: description ?? this.description,
      mimeType: mimeType,
      extension: extension,
      sizeBytes: sizeBytes,
      latitude: identical(latitude, _unset)
          ? this.latitude
          : latitude as double?,
      longitude: identical(longitude, _unset)
          ? this.longitude
          : longitude as double?,
      mapsUrl: identical(mapsUrl, _unset) ? this.mapsUrl : mapsUrl as String?,
      source: source,
      localPath: localPath,
      localFile: localFile,
      originalFilename: originalFilename,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ImageRecord.fromMap(
    Map<String, dynamic> map, {
    XFile? localFile,
    String? localPath,
    ImageUploadStatus uploadStatus = ImageUploadStatus.uploaded,
  }) {
    return ImageRecord(
      id: map['id'] as String?,
      ownerId: map['owner_id'] as String?,
      name: map['name'] as String,
      src: map['src'] as String?,
      storagePath: map['storage_path'] as String?,
      alt: map['alt'] as String,
      description: map['description'] as String,
      mimeType: map['mime_type'] as String,
      extension: map['extension'] as String,
      sizeBytes: (map['size_bytes'] as num).toInt(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      mapsUrl: map['maps_url'] as String?,
      source: ImageRecordSource.values.firstWhere(
        (source) => source.jsonValue == map['source'],
      ),
      originalFilename: map['original_filename'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toUtc(),
      localPath: localPath,
      localFile: localFile,
      uploadStatus: uploadStatus,
      isVisible: map['is_visible'] as bool? ?? true,
      deletedAt: map['deleted_at'] == null
          ? null
          : DateTime.parse(map['deleted_at'] as String).toUtc(),
    );
  }

  factory ImageRecord.fromApiJson(
    Map<String, dynamic> json, {
    XFile? localFile,
    String? localPath,
    ImageUploadStatus uploadStatus = ImageUploadStatus.uploaded,
  }) {
    return ImageRecord(
      id: json['id'] as String?,
      ownerId: json['ownerId'] as String?,
      name: json['name'] as String,
      src: json['src'] as String?,
      storagePath: json['storagePath'] as String?,
      alt: json['alt'] as String,
      description: json['description'] as String,
      mimeType: json['mimeType'] as String,
      extension: json['extension'] as String,
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      mapsUrl: json['mapsUrl'] as String?,
      source: ImageRecordSource.values.firstWhere(
        (source) => source.jsonValue == json['source'],
      ),
      originalFilename: json['originalFilename'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
      localPath: localPath,
      localFile: localFile,
      uploadStatus: uploadStatus,
      isVisible: json['isVisible'] as bool? ?? true,
      deletedAt: json['deletedAt'] == null
          ? null
          : DateTime.parse(json['deletedAt'] as String).toUtc(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'src': src,
      'storage_path': storagePath,
      'alt': alt,
      'description': description,
      'mime_type': mimeType,
      'extension': extension,
      'size_bytes': sizeBytes,
      'latitude': latitude,
      'longitude': longitude,
      'maps_url': mapsUrl,
      'source': source.jsonValue,
      'original_filename': originalFilename,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'is_visible': isVisible,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
    };
  }

  Map<String, Object?> toJson() => toMap();

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toMap());
}
