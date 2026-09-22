import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../app/theme_controller.dart';
import '../config/app_settings.dart';
import '../models/image_record.dart';
import '../repositories/image_repository.dart';
import '../services/image_picker_service.dart';
import '../services/location_service.dart';
import '../services/prepared_image_library.dart';
import '../utils/image_metadata.dart';
import '../widgets/gps_status_tag.dart';
import 'image_form_screen.dart';
import 'image_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.locationService,
    required this.themeController,
    this.imagePickerService,
    this.imageLibrary,
    this.startupMessage,
    this.imageRepository,
    this.authenticatedUserId,
    this.authenticatedUserRole,
    this.authenticatedUserEmail,
    this.onLogout,
    super.key,
  });

  final LocationService locationService;
  final ImagePickerService? imagePickerService;
  final ThemeController themeController;
  final PreparedImageLibrary? imageLibrary;
  final String? startupMessage;
  final ImageRepository? imageRepository;
  final String? authenticatedUserId;
  final String? authenticatedUserRole;
  final String? authenticatedUserEmail;
  final VoidCallback? onLogout;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ImagePickerService _imagePickerService;
  late final PreparedImageLibrary _imageLibrary;
  late final bool _ownsImageLibrary;
  LocationAccessStatus _locationStatus = LocationAccessStatus.checking;
  bool _isWorking = false;
  bool _isUploading = false;
  late bool _isLoadingImages;
  bool _imageLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _imagePickerService =
        widget.imagePickerService ?? DeviceImagePickerService();
    _ownsImageLibrary = widget.imageLibrary == null;
    _imageLibrary = widget.imageLibrary ?? PreparedImageLibrary();
    _imageLibrary.addListener(_refreshLibraryCount);
    _isLoadingImages = widget.imageRepository != null;
    _checkLocationStatus();
    _loadImages();
    if (widget.startupMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showMessage(widget.startupMessage!);
      });
    }
  }

  Future<void> _loadImages() async {
    final repository = widget.imageRepository;
    if (repository == null) return;

    try {
      final images = await repository.loadVisible();
      if (!mounted) return;
      _imageLibrary.replaceAll(images);
      setState(() {
        _isLoadingImages = false;
        _imageLoadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingImages = false;
        _imageLoadFailed = true;
      });
      _showMessage('No fue posible cargar tus imágenes.');
    }
  }

  @override
  void dispose() {
    _imageLibrary.removeListener(_refreshLibraryCount);
    if (_ownsImageLibrary) _imageLibrary.dispose();
    super.dispose();
  }

  void _refreshLibraryCount() {
    if (mounted) setState(() {});
  }

  Future<void> _checkLocationStatus() async {
    final result = await widget.locationService.checkAndRequestAccess(
      obtainPosition: false,
    );
    if (!mounted) return;
    setState(() => _locationStatus = result.status);
  }

  Future<void> _openLocationSettings() async {
    await widget.locationService.openLocationSettings();
    if (mounted) await _checkLocationStatus();
  }

  Future<Position?> _optionalPosition(ImageRecordSource source) async {
    final enabled = source == ImageRecordSource.camera
        ? AppSettings.captureCameraLocation
        : AppSettings.captureGalleryLocation;
    if (!enabled) return null;

    final result = await widget.locationService.checkAndRequestAccess();
    if (result.status == LocationAccessStatus.granted) return result.position;
    if (mounted) {
      _showMessage('La imagen se guardará sin ubicación.');
      setState(() => _locationStatus = result.status);
    }
    return null;
  }

  Future<void> _pickImage(ImageRecordSource source) async {
    if (_isWorking) return;
    setState(() => _isWorking = true);

    try {
      final pickResult = await _imagePickerService.pick(source);
      if (!mounted) return;
      if (pickResult.wasCancelled) {
        _showMessage('No seleccionaste ninguna imagen.');
        return;
      }
      if (pickResult.errorMessage != null) {
        _showMessage(pickResult.errorMessage!);
        return;
      }

      final selectedImage = pickResult.image;
      if (selectedImage == null) return;

      try {
        final record = await buildLocalImageRecord(
          image: selectedImage,
          position: await _optionalPosition(source),
        );
        if (!mounted) return;

        final saved = await Navigator.of(context).push<ImageRecord>(
          MaterialPageRoute<ImageRecord>(
            builder: (context) => ImageFormScreen(
              record: record,
              mode: ImageFormMode.create,
              locationService: widget.locationService,
            ),
          ),
        );
        if (saved != null) {
          _imageLibrary.add(saved);
          await _upload(saved);
        }
      } on ImageMetadataException catch (error) {
        if (mounted) _showMessage(error.message);
      } catch (_) {
        if (mounted) _showMessage('No fue posible preparar la imagen.');
      }
    } finally {
      if (mounted) setState(() => _isWorking = false);
    }
  }

  Future<void> _upload(ImageRecord image) async {
    final repository = widget.imageRepository;
    if (repository == null) {
      _imageLibrary.update(
        image.copyWith(uploadStatus: ImageUploadStatus.pending),
      );
      _showMessage(
        'No fue posible subir la imagen. Puedes intentarlo nuevamente.',
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      await _imageLibrary.upload(image, repository);
      if (mounted) _showMessage('Imagen subida correctamente.');
    } catch (_) {
      if (mounted) {
        _showMessage(
          'No fue posible subir la imagen. Puedes intentarlo nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showProfile() {
    final email = widget.authenticatedUserEmail;
    final role = widget.authenticatedUserRole ?? 'USER';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          email ?? 'Usuario',
                          key: const Key('perfil-email'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          role,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                key: const Key('boton-cerrar-sesion'),
                onPressed: widget.onLogout == null
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        widget.onLogout!();
                      },
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPreparedImages() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ImageListScreen(
          library: _imageLibrary,
          imageRepository: widget.imageRepository,
          authenticatedUserId: widget.authenticatedUserId,
          authenticatedUserRole: widget.authenticatedUserRole,
          locationService: widget.locationService,
          loadFailed: _imageLoadFailed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AlPics'),
        actions: [
          IconButton(
            key: const Key('boton-perfil'),
            tooltip: 'Perfil',
            onPressed: _showProfile,
            icon: const Icon(Icons.person_outline),
          ),
          PopupMenuButton<ThemeMode>(
            key: const Key('selector-tema'),
            tooltip: 'Cambiar tema',
            initialValue: widget.themeController.value,
            onSelected: widget.themeController.setMode,
            itemBuilder: (context) => const [
              PopupMenuItem(value: ThemeMode.system, child: Text('Sistema')),
              PopupMenuItem(value: ThemeMode.light, child: Text('Claro')),
              PopupMenuItem(value: ThemeMode.dark, child: Text('Oscuro')),
            ],
            icon: const Icon(Icons.brightness_6_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Image.asset(
                'assets/images/alpic.png',
                width: 160,
                height: 160,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tus imágenes, listas para compartir.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _isWorking
                  ? null
                  : () => _pickImage(ImageRecordSource.camera),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Tomar foto'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isWorking
                  ? null
                  : () => _pickImage(ImageRecordSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Elegir de la galería'),
            ),
            if (_isUploading) ...[
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Subiendo imagen...'),
                ],
              ),
            ] else if (_isWorking) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: GpsStatusTag(
                status: _locationStatus,
                onOpenLocationSettings: _openLocationSettings,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                onTap: _isLoadingImages ? null : _openPreparedImages,
                leading: const Icon(Icons.collections_outlined),
                title: const Text('Imágenes preparadas'),
                subtitle: Text(
                  _isLoadingImages
                      ? 'Cargando imágenes...'
                      : _imageLoadFailed
                      ? 'No fue posible cargar tus imágenes'
                      : _imageLibrary.images.isEmpty
                      ? 'Todavía no has subido imágenes'
                      : '${_imageLibrary.images.length} guardadas',
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
