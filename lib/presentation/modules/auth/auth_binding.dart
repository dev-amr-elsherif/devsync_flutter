import 'package:get/get.dart';
import '../../../data/providers/firebase_provider.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/services/gemini_service.dart';
import 'auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // التأكد من وجود الـ Providers والـ Services المطلوبة
    Get.lazyPut<FirebaseProvider>(() => FirebaseProvider(), fenix: true);
    Get.lazyPut<GeminiService>(() => GeminiService(), fenix: true);
    Get.lazyPut<AnalyticsService>(() => AnalyticsService(), fenix: true);
    
    // حقن الـ AuthController
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}
