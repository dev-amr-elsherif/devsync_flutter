import 'package:get/get.dart';
import 'main_shell_controller.dart';
import '../ai_chat/ai_chat_controller.dart';
import '../dev_dashboard/developer_controller.dart';
import '../dev_projects/dev_invitations_controller.dart';
import '../dev_matches/matches_controller.dart';
import '../owner_dashboard/owner_controller.dart';

class MainShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MainShellController>(() => MainShellController());
    Get.lazyPut<AIChatController>(() => AIChatController());
    
    // We also need the role-specific controllers available
    Get.lazyPut<DeveloperController>(() => DeveloperController());
    Get.lazyPut<DevInvitationsController>(() => DevInvitationsController());
    Get.lazyPut<MatchesController>(() => MatchesController());
    Get.lazyPut<OwnerController>(() => OwnerController());
  }
}
