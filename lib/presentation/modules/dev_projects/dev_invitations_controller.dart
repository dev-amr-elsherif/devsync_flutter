import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../data/models/project_model.dart';
import '../../../../data/models/invitation_model.dart';
import '../../../../data/providers/firebase_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';

class DevInvitationsController extends GetxController {
  final FirebaseProvider _firebaseProvider = FirebaseProvider();
  final AuthController _authController = Get.find<AuthController>();

  // دعوات المدير للمطور
  final RxList<InvitationModel> invitations = <InvitationModel>[].obs;
  // طلبات المطور للانضمام (أرسلها هو بنفسه)
  final RxList<InvitationModel> myJoinRequests = <InvitationModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;
  
  // Filtering
  final RxString selectedFilter = 'Active'.obs;

  // Stats Getters
  int get activeProjectsCount => invitations.where((i) => i.status == 'accepted').length + myJoinRequests.where((i) => i.status == 'accepted').length;
  int get pendingInvitesCount => invitations.where((i) => i.status == 'pending').length;
  int get pendingRequestsCount => myJoinRequests.where((i) => i.status == 'join_request').length;

  List<InvitationModel> get filteredInvitations {
    if (selectedFilter.value == 'All') return invitations;
    if (selectedFilter.value == 'Active') return invitations.where((i) => i.status == 'accepted').toList();
    if (selectedFilter.value == 'Pending') return invitations.where((i) => i.status == 'pending').toList();
    if (selectedFilter.value == 'History') return invitations.where((i) => i.status == 'declined' || i.status == 'cancelled').toList();
    return invitations;
  }

  List<InvitationModel> get filteredRequests {
    if (selectedFilter.value == 'All') return myJoinRequests;
    if (selectedFilter.value == 'Active') return myJoinRequests.where((i) => i.status == 'accepted').toList();
    if (selectedFilter.value == 'Pending') return myJoinRequests.where((i) => i.status == 'join_request').toList();
    if (selectedFilter.value == 'History') return myJoinRequests.where((i) => i.status == 'declined').toList();
    return myJoinRequests;
  }

  StreamSubscription? _invitationSub;
  StreamSubscription? _joinRequestSub;

  // لتعقب الحالات السابقة ومعرفة ما إذا تغيرت (للتنبيهات)
  final Map<String, String> _lastStatusMap = {};

  @override
  void onInit() {
    super.onInit();
    _listenToInvitations();
    _listenToMyJoinRequests();
  }

  @override
  void onClose() {
    _invitationSub?.cancel();
    _joinRequestSub?.cancel();
    super.onClose();
  }

  void _listenToInvitations() {
    final user = _authController.currentUser.value;
    if (user == null) {
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    hasError.value = false;
    
    _invitationSub?.cancel();
    _invitationSub = _firebaseProvider.streamInvitations(user.uid).listen(
      (data) {
        _checkAndNotify(data);
        invitations.assignAll(data);
        isLoading.value = false;
      },
      onError: (error) {
        debugPrint('Error fetching invitations: $error');
        hasError.value = true;
        errorMessage.value = error.toString();
        isLoading.value = false;
      },
    );
  }

  void _listenToMyJoinRequests() {
    final user = _authController.currentUser.value;
    if (user == null) return;
    _joinRequestSub?.cancel();
    _joinRequestSub = _firebaseProvider.streamMyJoinRequests(user.uid).listen(
      (data) {
        _checkAndNotify(data);
        myJoinRequests.assignAll(data);
        isLoading.value = false;
      },
      onError: (error) => debugPrint('Error fetching join requests: $error'),
    );
  }

  void _checkAndNotify(List<InvitationModel> newInvites) {
    for (var invite in newInvites) {
      final oldStatus = _lastStatusMap[invite.id];
      if (oldStatus != null && oldStatus != invite.status) {
        // حدث تغيير في الحالة!
        if (invite.status == 'accepted') {
          _showNotification('Accepted! 🚀', 'Your request to join "${invite.projectTitle}" was accepted!');
        } else if (invite.status == 'declined') {
          _showNotification('Declined', 'Your request for "${invite.projectTitle}" was declined.', isError: true);
        } else if (invite.status == 'cancelled') {
          _showNotification('Project Update', 'The owner has requested cancellation for "${invite.projectTitle}".');
        }
      }
      // تحديث الخريطة للحالة الحالية
      _lastStatusMap[invite.id] = invite.status;
    }
  }

  void _showNotification(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: isError ? AppTheme.error.withValues(alpha: 0.1) : AppTheme.secondary.withValues(alpha: 0.1),
      colorText: isError ? AppTheme.error : AppTheme.secondary,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: Icon(
        isError ? Icons.error_outline_rounded : Icons.notifications_active_rounded,
        color: isError ? AppTheme.error : AppTheme.secondary,
      ),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
    );
  }

  void retry() {
    _listenToInvitations();
    _listenToMyJoinRequests();
  }

  Future<ProjectModel?> fetchProject(String projectId) async {
    return await _firebaseProvider.getProject(projectId);
  }

  Future<void> viewProjectDetails(String projectId) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      final project = await _firebaseProvider.getProject(projectId);
      Get.back(); // Close loading dialog
      
      if (project != null) {
        Get.toNamed('/project-details', arguments: project);
      } else {
        Get.snackbar('Error', 'Project not found');
      }
    } catch (e) {
      Get.back();
      Get.snackbar('Error', 'Failed to fetch project details');
    }
  }

  Future<void> acceptInvitation(InvitationModel invitation) async {
    try {
      await _firebaseProvider.updateInvitationStatus(invitation.id, 'accepted');
      Get.snackbar('Success', 'Project invitation accepted! 🚀');
    } catch (e) {
      Get.snackbar('Error', 'Failed to accept invitation');
    }
  }

  Future<void> declineInvitation(InvitationModel invitation) async {
    try {
      await _firebaseProvider.updateInvitationStatus(invitation.id, 'declined');
      Get.snackbar('Declined', 'Invitation was declined.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to decline invitation');
    }
  }

  // الموافقة على طلب الإلغاء من المالك
  Future<void> approveCancellation(InvitationModel invite) async {
    try {
      await _firebaseProvider.respondToCancellation(invite.id, true);
      Get.snackbar('Project Cancelled', 'You have agreed to cancel this project.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to approve cancellation');
    }
  }

  // رفض طلب الإلغاء (التمسك بالعمل)
  Future<void> declineCancellation(InvitationModel invite) async {
    try {
      await _firebaseProvider.respondToCancellation(invite.id, false);
      Get.snackbar('Feedback Sent', 'The owner has been notified that you wish to continue.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to decline cancellation');
    }
  }
}
