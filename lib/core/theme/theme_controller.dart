import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app_theme.dart';

class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  static const _boxName = 'settings';
  static const _themeKey = 'isDark';

  final _isDark = true.obs;
  bool get isDark => _isDark.value;
  ThemeMode get themeMode => _isDark.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final box = Hive.box(_boxName);
    _isDark.value = box.get(_themeKey, defaultValue: true) as bool;
  }

  void toggleTheme() {
    _isDark.value = !_isDark.value;
    Hive.box(_boxName).put(_themeKey, _isDark.value);
    Get.changeTheme(_isDark.value ? AppTheme.darkTheme : AppTheme.lightTheme);
  }

  void setDark() => _setTheme(true);
  void setLight() => _setTheme(false);

  void _setTheme(bool dark) {
    _isDark.value = dark;
    Hive.box(_boxName).put(_themeKey, dark);
    Get.changeTheme(dark ? AppTheme.darkTheme : AppTheme.lightTheme);
  }
}
