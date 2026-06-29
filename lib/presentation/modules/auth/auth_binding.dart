import 'package:get/get.dart';
import '../../../data/providers/firebase_provider.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/services/groq_service.dart'; // ✅ FIX
import 'auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FirebaseProvider>(() => FirebaseProvider(), fenix: true);
    Get.lazyPut<GroqService>(() => GroqService(), fenix: true); // ✅ FIX
    Get.lazyPut<AnalyticsService>(() => AnalyticsService(), fenix: true);
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}
