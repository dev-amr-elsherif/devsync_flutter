import 'package:get/get.dart';
import 'dart:async';
import '../../../../data/models/invitation_model.dart';
import '../../../../data/providers/firebase_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';

class OwnerProjectsController extends GetxController {
  final FirebaseProvider _firebaseProvider = FirebaseProvider();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<InvitationModel> sentInvitations = <InvitationModel>[].obs;
  final RxList<InvitationModel> receivedJoinRequests = <InvitationModel>[].obs;
  final RxBool isLoading = true.obs;

  StreamSubscription? _sentSub;
  StreamSubscription? _joinSub;

  @override
  void onInit() {
    super.onInit();
    _listenToSentInvitations();
    _listenToReceivedJoinRequests();
  }

  @override
  void onClose() {
    _sentSub?.cancel();
    _joinSub?.cancel();
    super.onClose();
  }

  void _listenToSentInvitations() {
    final user = _authController.currentUser.value;
    if (user == null) {
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    _sentSub?.cancel();
    _sentSub = _firebaseProvider.streamSentInvitations(user.uid).listen(
      (data) {
        sentInvitations.assignAll(data);
        isLoading.value = false;
      },
      onError: (e) => isLoading.value = false,
    );
  }

  void _listenToReceivedJoinRequests() {
    final user = _authController.currentUser.value;
    if (user == null) return;

    _joinSub?.cancel();
    _joinSub = _firebaseProvider.streamJoinRequestsForOwner(user.uid).listen(
      (data) {
        receivedJoinRequests.assignAll(data);
        isLoading.value = false;
      },
      onError: (e) => isLoading.value = false,
    );
  }

  // حذف المشروع وكل ما يتعلق به إذا لم يكن هناك مقبولين
  Future<void> deleteProject(String projectId) async {
    try {
      await _firebaseProvider.hardDeleteProject(projectId);
      Get.snackbar('Success', 'Project deleted successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete project: $e');
    }
  }

  // إرسال طلب إلغاء (عند وجود مطورين مقبولين)
  Future<void> requestCancellation(String invitationId, String apology) async {
    try {
      await _firebaseProvider.proposeCancellation(invitationId, apology);
      Get.snackbar('Success', 'Cancellation request sent to developer');
    } catch (e) {
      Get.snackbar('Error', 'Failed to send request: $e');
    }
  }

  Future<void> respondToJoinRequest(String invitationId, bool isAccepted) async {
    try {
      await _firebaseProvider.respondToJoinRequest(invitationId, isAccepted);
      Get.snackbar(
        isAccepted ? 'Accepted! 🎉' : 'Declined',
        isAccepted ? 'The developer has been added to the project.' : 'The request was declined.',
        backgroundColor: isAccepted ? AppTheme.success.withValues(alpha: 0.1) : AppTheme.error.withValues(alpha: 0.1),
        colorText: isAccepted ? AppTheme.success : AppTheme.error,
      );
    } catch (e) {
      Get.snackbar('Error', 'Action failed: $e');
    }
  }
}
