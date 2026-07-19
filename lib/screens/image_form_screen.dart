import 'package:flutter/material.dart';

import '../models/image_record.dart';
import '../utils/image_name_generator.dart';
import '../widgets/image_preview.dart';

enum ImageFormMode { create, edit }

class ImageFormScreen extends StatefulWidget {
  const ImageFormScreen({required this.record, required this.mode, super.key});

  final ImageRecord record;
  final ImageFormMode mode;

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
      ),
    );
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
