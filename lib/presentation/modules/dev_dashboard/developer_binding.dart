import 'package:get/get.dart';
import '../../../data/providers/firebase_provider.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/services/groq_service.dart'; // ✅ FIX
import '../dev_projects/dev_invitations_controller.dart';
import 'developer_controller.dart';

class DeveloperBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FirebaseProvider>(() => FirebaseProvider(), fenix: true);
    Get.lazyPut<GroqService>(() => GroqService(), fenix: true); // ✅ FIX
    Get.lazyPut<AnalyticsService>(() => AnalyticsService(), fenix: true);
    Get.lazyPut<DeveloperController>(() => DeveloperController());
    Get.lazyPut<DevInvitationsController>(() => DevInvitationsController());
  }
}
