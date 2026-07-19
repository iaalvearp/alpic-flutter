import 'package:flutter/material.dart';

import '../services/location_service.dart';

class GpsStatusTag extends StatelessWidget {
  const GpsStatusTag({
    required this.status,
    required this.onOpenLocationSettings,
    super.key,
  });

  final LocationAccessStatus status;
  final VoidCallback onOpenLocationSettings;

  @override
  Widget build(BuildContext context) {
    final (color, label, key) = switch (status) {
      LocationAccessStatus.granted => (
        Colors.green,
        'GPS disponible',
        const Key('gps-verde'),
      ),
      LocationAccessStatus.serviceDisabled => (
        Colors.amber.shade700,
        'GPS desactivado',
        const Key('gps-amarillo'),
      ),
      LocationAccessStatus.checking => (
        Colors.grey,
        'Comprobando GPS',
        const Key('gps-comprobando'),
      ),
      _ => (Colors.red, 'GPS no disponible', const Key('gps-rojo')),
    };

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Semantics(
          label: label,
          child: Container(
            key: key,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('GPS'),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (status == LocationAccessStatus.serviceDisabled)
          TextButton(
            onPressed: onOpenLocationSettings,
            child: const Text('Activar'),
          ),
      ],
    );
  }
}
