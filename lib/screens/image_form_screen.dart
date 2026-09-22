import 'package:flutter/material.dart';

import '../models/image_record.dart';
import '../services/location_service.dart';
import '../utils/image_name_generator.dart';
import '../widgets/image_preview.dart';

enum ImageFormMode { create, edit }

class ImageFormScreen extends StatefulWidget {
  const ImageFormScreen({
    required this.record,
    required this.mode,
    this.locationService,
    super.key,
  });

  final ImageRecord record;
  final ImageFormMode mode;
  final LocationService? locationService;

  @override
  State<ImageFormScreen> createState() => _ImageFormScreenState();
}

class _ImageFormScreenState extends State<ImageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _altController;
  late final TextEditingController _descriptionController;
  late bool _altWasEdited;
  late bool _descriptionWasEdited;
  late double? _latitude;
  late double? _longitude;
  late String? _mapsUrl;
  bool _isCapturingLocation = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.record.name);
    _altController = TextEditingController(text: widget.record.alt);
    _descriptionController = TextEditingController(
      text: widget.record.description,
    );
    _altWasEdited = widget.record.alt != generateDefaultAlt(widget.record.name);
    _descriptionWasEdited =
        widget.record.description !=
        generateDefaultDescription(widget.record.name);
    _latitude = widget.record.latitude;
    _longitude = widget.record.longitude;
    _mapsUrl = widget.record.mapsUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _altController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _syncDefaults(String name) {
    if (!_altWasEdited) _altController.text = generateDefaultAlt(name);
    if (!_descriptionWasEdited) {
      _descriptionController.text = generateDefaultDescription(name);
    }
  }

  String? _required(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label es obligatorio.';
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      widget.record.copyWith(
        name: _nameController.text.trim(),
        alt: _altController.text.trim(),
        description: _descriptionController.text.trim(),
        updatedAt: DateTime.now().toUtc(),
        latitude: _latitude,
        longitude: _longitude,
        mapsUrl: _mapsUrl,
      ),
    );
  }

  Future<void> _captureLocation() async {
    final service = widget.locationService;
    if (service == null || _isCapturingLocation) return;

    setState(() => _isCapturingLocation = true);
    try {
      final result = await service.checkAndRequestAccess();
      if (!mounted) return;
      if (result.status == LocationAccessStatus.granted &&
          result.position != null) {
        setState(() {
          _latitude = result.position!.latitude;
          _longitude = result.position!.longitude;
          _mapsUrl =
              'https://www.google.com/maps?q=$_latitude,$_longitude';
        });
      } else {
        _showMessage(
          'No se pudo obtener la ubicación. Verifica que el GPS esté encendido.',
        );
      }
    } finally {
      if (mounted) setState(() => _isCapturingLocation = false);
    }
  }

  void _removeLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;
      _mapsUrl = null;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _friendlyFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isCreate = widget.mode == ImageFormMode.create;

    return Scaffold(
      appBar: AppBar(title: Text(isCreate ? 'Nueva imagen' : 'Editar imagen')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ImagePreview(
                    file: widget.record.localFile,
                    src: widget.record.src,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  key: const Key('campo-nombre'),
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                  onChanged: _syncDefaults,
                  validator: (value) => _required(value, 'El nombre'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('campo-alternativo'),
                  controller: _altController,
                  decoration: const InputDecoration(
                    labelText: 'Texto alternativo',
                    helperText: 'Describe brevemente lo que aparece.',
                  ),
                  onChanged: (_) => _altWasEdited = true,
                  validator: (value) =>
                      _required(value, 'El texto alternativo'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('campo-descripcion'),
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    helperText: 'Añade información útil sobre la imagen.',
                    alignLabelWithHint: true,
                  ),
                  minLines: 3,
                  maxLines: 6,
                  onChanged: (_) => _descriptionWasEdited = true,
                  validator: (value) => _required(value, 'La descripción'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tamaño: ${_friendlyFileSize(widget.record.sizeBytes)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                _LocationSection(
                  latitude: _latitude,
                  longitude: _longitude,
                  mapsUrl: _mapsUrl,
                  isCapturing: _isCapturingLocation,
                  canRequestLocation: widget.locationService != null,
                  onCapture: _captureLocation,
                  onRemove: _removeLocation,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _save,
                  child: Text(isCreate ? 'Guardar imagen' : 'Guardar cambios'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({
    required this.latitude,
    required this.longitude,
    required this.mapsUrl,
    required this.isCapturing,
    required this.canRequestLocation,
    required this.onCapture,
    required this.onRemove,
  });

  final double? latitude;
  final double? longitude;
  final String? mapsUrl;
  final bool isCapturing;
  final bool canRequestLocation;
  final VoidCallback onCapture;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasLocation = latitude != null && longitude != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      key: const Key('seccion-ubicacion'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ubicación',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isCapturing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (hasLocation) ...[
              Text(
                '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
                key: const Key('ubicacion-coordenadas'),
              ),
              if (mapsUrl != null)
                Text(
                  mapsUrl!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('quitar-ubicacion'),
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Quitar ubicación'),
              ),
            ] else if (canRequestLocation) ...[
              Text(
                'Sin ubicación.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('capturar-ubicacion'),
                onPressed: onCapture,
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('Obtener ubicación'),
              ),
            ] else
              Text(
                'La imagen se guardará sin ubicación.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }
}
