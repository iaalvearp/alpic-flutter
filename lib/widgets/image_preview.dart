import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePreview extends StatefulWidget {
  const ImagePreview({
    required this.file,
    this.src,
    this.compact = false,
    super.key,
  });

  final XFile? file;
  final String? src;
  final bool compact;

  @override
  State<ImagePreview> createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  Future<Uint8List>? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file != widget.file) _load();
  }

  void _load() {
    _bytes = widget.file?.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 56.0 : null;
    final width = widget.compact ? 56.0 : double.infinity;

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.compact ? 10 : 16),
        child: widget.file == null
            ? _remoteOrFallback(context)
            : FutureBuilder<Uint8List>(
                future: _bytes,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _fallback(context),
                    );
                  }
                  if (snapshot.hasError) return _fallback(context);
                  return const Center(child: CircularProgressIndicator());
                },
              ),
      ),
    );
  }

  Widget _remoteOrFallback(BuildContext context) {
    final src = widget.src;
    if (src == null || src.isEmpty) return _fallback(context);
    return Image.network(
      src,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: widget.compact ? 24 : 48,
        ),
      ),
    );
  }
}
