import 'package:flutter/material.dart';

class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController([super.value = ThemeMode.system]);

  void setMode(ThemeMode mode) {
    value = mode;
  }
}
