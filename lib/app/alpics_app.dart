import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../repositories/image_repository.dart';
import '../services/image_picker_service.dart';
import '../services/location_service.dart';
import '../services/prepared_image_library.dart';
import 'app_theme.dart';
import 'theme_controller.dart';

class AlPicsApp extends StatefulWidget {
  const AlPicsApp({
    super.key,
    this.locationService,
    this.imagePickerService,
    this.themeController,
    this.imageLibrary,
    this.startupMessage,
    this.imageRepository,
    this.authenticatedUserId,
  });

  final LocationService? locationService;
  final ImagePickerService? imagePickerService;
  final ThemeController? themeController;
  final PreparedImageLibrary? imageLibrary;
  final String? startupMessage;
  final ImageRepository? imageRepository;
  final String? authenticatedUserId;

  @override
  State<AlPicsApp> createState() => _AlPicsAppState();
}

class _AlPicsAppState extends State<AlPicsApp> {
  late final ThemeController _themeController;
  late final bool _ownsThemeController;

  @override
  void initState() {
    super.initState();
    _ownsThemeController = widget.themeController == null;
    _themeController = widget.themeController ?? ThemeController();
  }

  @override
  void dispose() {
    if (_ownsThemeController) _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeController,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'AlPics',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: HomeScreen(
            locationService: widget.locationService ?? DeviceLocationService(),
            imagePickerService: widget.imagePickerService,
            themeController: _themeController,
            imageLibrary: widget.imageLibrary,
            startupMessage: widget.startupMessage,
            imageRepository: widget.imageRepository,
            authenticatedUserId: widget.authenticatedUserId,
          ),
        );
      },
    );
  }
}
