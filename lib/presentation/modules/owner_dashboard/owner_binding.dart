import 'package:get/get.dart';
import '../../../data/providers/firebase_provider.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/services/gemini_service.dart';
import 'owner_controller.dart';

class OwnerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FirebaseProvider>(() => FirebaseProvider(), fenix: true);
    Get.lazyPut<GeminiService>(() => GeminiService(), fenix: true);
    Get.lazyPut<AnalyticsService>(() => AnalyticsService(), fenix: true);
    
    Get.lazyPut<OwnerController>(
      () => OwnerController(),
    );
  }
}
