import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/image_record.dart';
import '../repositories/image_repository.dart';
import '../services/location_service.dart';
import '../services/prepared_image_library.dart';
import '../utils/image_export.dart';
import '../widgets/image_list_item.dart';
import 'image_form_screen.dart';

class ImageListScreen extends StatefulWidget {
  const ImageListScreen({
    required this.library,
    required this.imageRepository,
    required this.authenticatedUserId,
    this.authenticatedUserRole,
    this.locationService,
    this.loadFailed = false,
    super.key,
  });

  final PreparedImageLibrary library;
  final ImageRepository? imageRepository;
  final String? authenticatedUserId;
  final String? authenticatedUserRole;
  final LocationService? locationService;
  final bool loadFailed;

  @override
  State<ImageListScreen> createState() => _ImageListScreenState();
}

class _ImageListScreenState extends State<ImageListScreen> {
  final Set<String> _selectedKeys = {};

  bool _canManage(ImageRecord image) {
    if (image.uploadStatus != ImageUploadStatus.uploaded) return true;
    return image.isVisible &&
        (widget.authenticatedUserRole == 'ADMIN' ||
            (widget.authenticatedUserId != null &&
                image.ownerId == widget.authenticatedUserId));
  }

  String _identity(ImageRecord image) =>
      image.id ?? '${image.originalFilename}-${image.createdAt.microsecondsSinceEpoch}';

  bool get _selectionMode => _selectedKeys.isNotEmpty;

  Future<void> _edit(BuildContext context, ImageRecord image) async {
    if (!_canManage(image)) return;
    final updated = await Navigator.of(context).push<ImageRecord>(
      MaterialPageRoute<ImageRecord>(
        builder: (context) => ImageFormScreen(
          record: image,
          mode: ImageFormMode.edit,
          locationService: widget.locationService,
        ),
      ),
    );
    if (updated == null) return;

    final repository = widget.imageRepository;
    if (image.uploadStatus != ImageUploadStatus.uploaded ||
        repository == null) {
      widget.library.update(updated);
      return;
    }

    try {
      await widget.library.updateRemoteMetadata(
        original: image,
        edited: updated,
        repository: repository,
      );
      if (context.mounted) _showMessage('Cambios guardados correctamente.');
    } catch (_) {
      if (context.mounted) {
        _showMessage(
          'No fue posible guardar los cambios. Inténtalo nuevamente.',
        );
      }
    }
  }

  Future<void> _retry(ImageRecord image) async {
    final repository = widget.imageRepository;
    if (repository == null) {
      _showMessage(
        'No fue posible subir la imagen. Puedes intentarlo nuevamente.',
      );
      return;
    }

    try {
      await widget.library.upload(image, repository);
      if (mounted) _showMessage('Imagen subida correctamente.');
    } catch (_) {
      if (mounted) {
        _showMessage(
          'No fue posible subir la imagen. Puedes intentarlo nuevamente.',
        );
      }
    }
  }

  Future<void> _confirmSoftDelete(ImageRecord image) async {
    if (!_canManage(image) || image.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quitar imagen'),
        content: const Text(
          '¿Quieres quitar esta imagen de tu lista? El archivo no se eliminará permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Quitar imagen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final repository = widget.imageRepository;
    if (repository == null) return;
    try {
      await widget.library.softDelete(image, repository);
      if (mounted) _showMessage('Imagen eliminada correctamente.');
    } catch (_) {
      if (mounted) {
        _showMessage(
          'No fue posible eliminar la imagen. Inténtalo nuevamente.',
        );
      }
    }
  }

  void _enterSelection(ImageRecord image) {
    setState(() {
      _selectedKeys.add(_identity(image));
    });
    _showMessage(
      'Selección activada. Toca para elegir o quitar más imágenes.',
    );
  }

  void _toggleSelection(ImageRecord image) {
    setState(() {
      final key = _identity(image);
      if (!_selectedKeys.remove(key)) _selectedKeys.add(key);
    });
  }

  void _clearSelection() {
    if (_selectedKeys.isEmpty) return;
    setState(_selectedKeys.clear);
  }

  Future<void> _confirmBatchDelete() async {
    final images = _selectedImages();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar imágenes'),
        content: Text(
          '¿Quieres eliminar ${images.length} ${images.length == 1 ? 'imagen' : 'imágenes'}? El archivo no se eliminará permanentemente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final repository = widget.imageRepository;
    if (repository == null) return;
    for (final image in images) {
      if (image.id == null || !_canManage(image)) continue;
      try {
        await widget.library.softDelete(image, repository);
      } catch (_) {
        // Sigue con el resto y avisa al final.
      }
    }
    if (!mounted) return;
    setState(_selectedKeys.clear);
    _showMessage('Imágenes eliminadas correctamente.');
  }

  List<ImageRecord> _selectedImages() {
    final keys = _selectedKeys;
    return widget.library.images
        .where((image) => keys.contains(_identity(image)))
        .toList();
  }

  Future<void> _openExportDialog(List<ImageRecord> images) async {
    if (images.isEmpty) return;
    await showDialog<void>(
      context: context,
      builder: (context) => _ExportJsonDialog(images: images),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedImages().length;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectionMode
              ? '$selected ${selected == 1 ? 'seleccionada' : 'seleccionadas'}'
              : 'Imágenes preparadas',
        ),
        leading: _selectionMode
            ? IconButton(
                key: const Key('cancelar-seleccion'),
                tooltip: 'Salir de la selección',
                onPressed: _clearSelection,
                icon: const Icon(Icons.close),
              )
            : null,
        actions: [
          if (_selectionMode) ...[
            IconButton(
              key: const Key('exportar-seleccion'),
              tooltip: 'Exportar JSON',
              onPressed:
                  selected == 0 ? null : () => _openExportDialog(_selectedImages()),
              icon: const Icon(Icons.ios_share),
            ),
            IconButton(
              key: const Key('eliminar-seleccion'),
              tooltip: 'Eliminar seleccionadas',
              onPressed:
                  selected == 0 ? null : _confirmBatchDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
      body: AnimatedBuilder(
        animation: widget.library,
        builder: (context, child) {
          if (widget.library.images.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  widget.loadFailed
                      ? 'No fue posible cargar tus imágenes'
                      : 'Todavía no has subido imágenes',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.library.images.length,
            itemBuilder: (context, index) {
              final image = widget.library.images[index];
              final canManage = _canManage(image);
              return ImageListItem(
                image: image,
                onTap: _selectionMode
                    ? () => _toggleSelection(image)
                    : canManage
                    ? () => _edit(context, image)
                    : null,
                onLongPress: () => _enterSelection(image),
                selected: _selectedKeys.contains(_identity(image)),
                selectionMode: _selectionMode,
                onRetry:
                    image.uploadStatus == ImageUploadStatus.pending ||
                        image.uploadStatus == ImageUploadStatus.failed
                    ? () => _retry(image)
                    : null,
                onDelete:
                    !_selectionMode &&
                        canManage &&
                        image.uploadStatus == ImageUploadStatus.uploaded
                    ? () => _confirmSoftDelete(image)
                    : null,
                onExport:
                    image.uploadStatus == ImageUploadStatus.uploaded
                    ? () => _openExportDialog([image])
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

class _ExportJsonDialog extends StatelessWidget {
  const _ExportJsonDialog({required this.images});

  final List<ImageRecord> images;

  bool get _isBatch => images.length > 1;

  @override
  Widget build(BuildContext context) {
    final jsonText = exportJson(images);
    return AlertDialog(
      title: Text(
        _isBatch ? 'Exportar ${images.length} imágenes' : 'Exportar JSON',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'El JSON contiene toda la información de la imagen.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: SelectableText(
                  jsonText,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: jsonText));
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('JSON copiado')));
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copiar'),
        ),
        FilledButton.icon(
          onPressed: () => shareExportFile(images),
          icon: const Icon(Icons.save_alt),
          label: const Text('Guardar / Compartir'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}