import 'package:flutter/material.dart';

import '../models/image_record.dart';
import 'image_preview.dart';

class ImageListItem extends StatelessWidget {
  const ImageListItem({
    required this.image,
    this.onTap,
    this.onRetry,
    this.onDelete,
    this.onWeather,
    super.key,
  });

  final ImageRecord image;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;
  final VoidCallback? onWeather;

  String get _statusText => switch (image.uploadStatus) {
    ImageUploadStatus.pending ||
    ImageUploadStatus.failed => 'Pendiente de subir',
    ImageUploadStatus.uploading => 'Subiendo imagen...',
    ImageUploadStatus.uploaded => 'Subida',
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: image.uploadStatus == ImageUploadStatus.uploading ? null : onTap,
        leading: ImagePreview(
          file: image.localFile,
          src: image.src,
          compact: true,
        ),
        title: Text(image.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${image.alt}\n$_statusText',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: image.uploadStatus == ImageUploadStatus.uploading
            ? const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : onRetry != null
            ? IconButton(
                key: Key('retry-${image.id ?? image.originalFilename}'),
                tooltip: 'Reintentar subida',
                onPressed: onRetry,
                icon: const Icon(Icons.cloud_upload_outlined),
              )
            : onDelete != null || onWeather != null
            ? PopupMenuButton<String>(
                tooltip: 'Acciones de imagen',
                onSelected: (action) {
                  if (action == 'edit') onTap?.call();
                  if (action == 'delete') onDelete?.call();
                  if (action == 'weather') onWeather?.call();
                },
                itemBuilder: (context) => [
                  if (onTap != null)
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Quitar imagen'),
                    ),
                  if (onWeather != null)
                    const PopupMenuItem(
                      value: 'weather',
                      child: Text('Consultar clima'),
                    ),
                ],
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}
