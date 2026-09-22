import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/image_record.dart';
import 'image_preview.dart';

class ImageListItem extends StatelessWidget {
  const ImageListItem({
    required this.image,
    this.onTap,
    this.onLongPress,
    this.onRetry,
    this.onDelete,
    this.onExport,
    this.selected = false,
    this.selectionMode = false,
    super.key,
  });

  final ImageRecord image;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;
  final VoidCallback? onExport;
  final bool selected;
  final bool selectionMode;

  String get _statusText => switch (image.uploadStatus) {
    ImageUploadStatus.pending ||
    ImageUploadStatus.failed => 'Pendiente de subir',
    ImageUploadStatus.uploading => 'Subiendo imagen...',
    ImageUploadStatus.uploaded => 'Subida',
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final longPressEnabled =
        image.uploadStatus != ImageUploadStatus.uploading &&
        onLongPress != null;
    return RawGestureDetector(
      gestures: {
        LongPressGestureRecognizer: GestureRecognizerFactoryWithHandlers<
          LongPressGestureRecognizer
        >(
          () => LongPressGestureRecognizer(
            duration: const Duration(milliseconds: 1000),
          ),
          (recognizer) =>
              recognizer.onLongPress = longPressEnabled ? onLongPress : null,
        ),
      },
      child: Card(
        color: selected ? colorScheme.primaryContainer : null,
        child: ListTile(
          onTap:
              image.uploadStatus == ImageUploadStatus.uploading ? null : onTap,
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
              : selectionMode
              ? Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: selected ? colorScheme.primary : null,
                )
              : onRetry != null
              ? IconButton(
                  key: Key('retry-${image.id ?? image.originalFilename}'),
                  tooltip: 'Reintentar subida',
                  onPressed: onRetry,
                  icon: const Icon(Icons.cloud_upload_outlined),
                )
              : onDelete != null || onExport != null || onTap != null
              ? PopupMenuButton<String>(
                  tooltip: 'Acciones de imagen',
                  onSelected: (action) {
                    if (action == 'edit') onTap?.call();
                    if (action == 'delete') onDelete?.call();
                    if (action == 'export') onExport?.call();
                  },
                  itemBuilder: (context) => [
                    if (onTap != null)
                      const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    if (onExport != null)
                      const PopupMenuItem(
                        value: 'export',
                        child: Text('Exportar JSON'),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Quitar imagen'),
                      ),
                  ],
                )
              : const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}