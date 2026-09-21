import 'package:flutter/material.dart';

import '../models/image_record.dart';
import '../repositories/image_repository.dart';
import '../repositories/weather_repository.dart';
import '../models/image_weather.dart';
import '../services/prepared_image_library.dart';
import '../widgets/image_list_item.dart';
import 'image_form_screen.dart';

class ImageListScreen extends StatefulWidget {
  const ImageListScreen({
    required this.library,
    required this.imageRepository,
    required this.authenticatedUserId,
    this.loadFailed = false,
    this.weatherRepository,
    this.authenticatedUserRole,
    super.key,
  });

  final PreparedImageLibrary library;
  final ImageRepository? imageRepository;
  final String? authenticatedUserId;
  final bool loadFailed;
  final ImageWeatherRepository? weatherRepository;
  final String? authenticatedUserRole;

  @override
  State<ImageListScreen> createState() => _ImageListScreenState();
}

class _ImageListScreenState extends State<ImageListScreen> {
  bool _canManage(ImageRecord image) {
    if (image.uploadStatus != ImageUploadStatus.uploaded) return true;
    return image.isVisible &&
        (widget.authenticatedUserRole == 'ADMIN' ||
            (widget.authenticatedUserId != null &&
                image.ownerId == widget.authenticatedUserId));
  }

  Future<void> _edit(BuildContext context, ImageRecord image) async {
    if (!_canManage(image)) return;
    final updated = await Navigator.of(context).push<ImageRecord>(
      MaterialPageRoute<ImageRecord>(
        builder: (context) =>
            ImageFormScreen(record: image, mode: ImageFormMode.edit),
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

  Future<void> _showWeather(ImageRecord image) async {
    final repository = widget.weatherRepository;
    if (repository == null || image.id == null) return;

    try {
      final weather = await repository.loadForImage(image.id!);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => _WeatherDialog(weather: weather),
      );
    } catch (_) {
      if (mounted) {
        _showMessage('No fue posible consultar el clima de la imagen.');
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

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Imágenes preparadas')),
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
                onTap: canManage ? () => _edit(context, image) : null,
                onRetry:
                    image.uploadStatus == ImageUploadStatus.pending ||
                        image.uploadStatus == ImageUploadStatus.failed
                    ? () => _retry(image)
                    : null,
                onDelete:
                    canManage &&
                        image.uploadStatus == ImageUploadStatus.uploaded
                    ? () => _confirmSoftDelete(image)
                    : null,
                onWeather: widget.weatherRepository == null
                    ? null
                    : () => _showWeather(image),
              );
            },
          );
        },
      ),
    );
  }
}

class _WeatherDialog extends StatelessWidget {
  const _WeatherDialog({required this.weather});

  final ImageWeather weather;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Clima de la imagen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Proveedor: ${weather.provider}'),
          Text('Hora: ${weather.observedAt} (${weather.timezone})'),
          const SizedBox(height: 12),
          Text(
            'Temperatura: ${weather.temperature.value} ${weather.temperature.unit}',
          ),
          Text(
            'Sensación: ${weather.apparentTemperature.value} ${weather.apparentTemperature.unit}',
          ),
          Text(
            'Humedad: ${weather.relativeHumidity.value} ${weather.relativeHumidity.unit}',
          ),
          Text(
            'Precipitación: ${weather.precipitation.value} ${weather.precipitation.unit}',
          ),
          Text('Viento: ${weather.windSpeed.value} ${weather.windSpeed.unit}'),
          Text('Código meteorológico: ${weather.weatherCode}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
