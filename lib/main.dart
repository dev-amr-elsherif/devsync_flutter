import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/routes/app_pages.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'data/services/analytics_service.dart';
import 'data/services/fcm_service.dart';
import 'data/services/remote_config_service.dart';
import 'firebase_options.dart';
import 'flavors/flavor_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Hive ──────────────────────────────────────────────────────────
  await Hive.initFlutter();
  await Hive.openBox('settings');

  // ── Theme Controller ──────────────────────────────────────────────
  final themeCtrl = Get.put(ThemeController(), permanent: true);

  // ── System UI ──────────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          themeCtrl.isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          themeCtrl.isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF4F6FF),
      systemNavigationBarIconBrightness:
          themeCtrl.isDark ? Brightness.light : Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // ── Flavor ────────────────────────────────────────────────────────
  FlavorConfig.setFlavor(FlavorType.pro);

  // ── Firebase ──────────────────────────────────────────────────────
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      debugPrint('[Firebase] Desktop init failed: $e');
      runApp(const DevSyncApp());
      return;
    }
    rethrow;
  }

  // ── Remote Config ─────────────────────────────────────────────────
  final remoteConfig = RemoteConfigService();
  await remoteConfig.init();
  Get.put(remoteConfig, permanent: true);

  // ── FCM ───────────────────────────────────────────────────────────
  final fcmService = FcmService();
  await fcmService.init();
  Get.put(fcmService, permanent: true);

  // ── Analytics ─────────────────────────────────────────────────────
  Get.put(AnalyticsService(), permanent: true);

  runApp(const DevSyncApp());
}

class DevSyncApp extends StatelessWidget {
  const DevSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeCtrl) {
        // ── System UI يتحدث مع كل تغيير في الثيم ──────────────────
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                themeCtrl.isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: themeCtrl.isDark
                ? const Color(0xFF0A0E1A)
                : const Color(0xFFF4F6FF),
            systemNavigationBarIconBrightness:
                themeCtrl.isDark ? Brightness.light : Brightness.dark,
          ),
        );

        return GetMaterialApp(
          title: FlavorConfig.instance.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeCtrl.themeMode,
          initialRoute: AppPages.initial,
          getPages: AppPages.routes,
          defaultTransition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 350),
        );
      },
    );
  }
}