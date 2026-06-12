import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'app/routes/app_pages.dart';
import 'core/theme/app_theme.dart';
import 'data/services/analytics_service.dart';
import 'data/services/fcm_service.dart';
import 'data/services/remote_config_service.dart';
import 'flavors/flavor_config.dart';




Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── System UI ──────────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

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
    return GetMaterialApp(
      title: FlavorConfig.instance.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}
