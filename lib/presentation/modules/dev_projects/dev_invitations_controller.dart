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

  final RxList<InvitationModel> invitations = <InvitationModel>[].obs;
  final RxList<InvitationModel> myJoinRequests = <InvitationModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  final RxString selectedFilter = 'Active'.obs;

  // ─── Stats Getters ───────────────────────────────────────────────
  int get activeProjectsCount =>
      invitations.where((i) => i.isAccepted).length +
      myJoinRequests.where((i) => i.isAccepted).length;

  int get pendingInvitesCount => invitations.where((i) => i.isPending).length;

  int get pendingRequestsCount =>
      myJoinRequests.where((i) => i.isJoinRequest).length;

  // ✅ FIX: getter مطلوب من developer_dashboard_view
  List<InvitationModel> get acceptedInvitations =>
      invitations.where((i) => i.isAccepted).toList() +
      myJoinRequests.where((i) => i.isAccepted).toList();

  // ─── Filtered Lists ──────────────────────────────────────────────
  List<InvitationModel> get filteredInvitations {
    switch (selectedFilter.value) {
      case 'Active':
        return invitations.where((i) => i.isAccepted).toList();
      case 'Pending':
        return invitations.where((i) => i.isPending).toList();
      case 'History':
        return invitations.where((i) => i.isDeclined || i.isCancelled).toList();
      default:
        return invitations;
    }
  }

  List<InvitationModel> get filteredRequests {
    switch (selectedFilter.value) {
      case 'Active':
        return myJoinRequests.where((i) => i.isAccepted).toList();
      case 'Pending':
        return myJoinRequests.where((i) => i.isJoinRequest).toList();
      case 'History':
        return myJoinRequests.where((i) => i.isDeclined).toList();
      default:
        return myJoinRequests;
    }
  }

  StreamSubscription? _invitationSub;
  StreamSubscription? _joinRequestSub;

  // ✅ FIX: Map<String, InvitationStatus> بدل Map<String, String>
  final Map<String, InvitationStatus> _lastStatusMap = {};

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
    _invitationSub = _firebaseProvider
        .streamInvitations(user.uid)
        .listen(
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
    _joinRequestSub = _firebaseProvider.streamMyJoinRequests(user.uid).listen((
      data,
    ) {
      _checkAndNotify(data);
      myJoinRequests.assignAll(data);
      isLoading.value = false;
    }, onError: (error) => debugPrint('Error fetching join requests: $error'));
  }

  void _checkAndNotify(List<InvitationModel> newInvites) {
    for (var invite in newInvites) {
      final oldStatus = _lastStatusMap[invite.id];
      if (oldStatus != null && oldStatus != invite.status) {
        // ✅ FIX: مقارنة بالـ enum مش بـ String
        if (invite.isAccepted) {
          _showNotification(
            'Accepted! 🚀',
            'Your request to join "${invite.projectTitle}" was accepted!',
          );
        } else if (invite.isDeclined) {
          _showNotification(
            'Declined',
            'Your request for "${invite.projectTitle}" was declined.',
            isError: true,
          );
        } else if (invite.isCancelled) {
          _showNotification(
            'Project Update',
            'The owner has requested cancellation for "${invite.projectTitle}".',
          );
        }
      }
      // ✅ FIX: خزّن InvitationStatus مباشرة
      _lastStatusMap[invite.id] = invite.status;
    }
  }

  void _showNotification(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      backgroundColor: isError
          ? AppTheme.error.withValues(alpha: 0.1)
          : AppTheme.secondary.withValues(alpha: 0.1),
      colorText: isError ? AppTheme.error : AppTheme.secondary,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: Icon(
        isError
            ? Icons.error_outline_rounded
            : Icons.notifications_active_rounded,
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
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );
      final project = await _firebaseProvider.getProject(projectId);
      Get.back();
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
      await _firebaseProvider.updateInvitationStatus(
        invitation.id,
        InvitationStatus.accepted.toFirestoreString(),
      );
      Get.snackbar('Success', 'Project invitation accepted! 🚀');
    } catch (e) {
      Get.snackbar('Error', 'Failed to accept invitation');
    }
  }

  Future<void> declineInvitation(InvitationModel invitation) async {
    try {
      await _firebaseProvider.updateInvitationStatus(
        invitation.id,
        InvitationStatus.declined.toFirestoreString(),
      );
      Get.snackbar('Declined', 'Invitation was declined.');
    } catch (e) {
      Get.snackbar('Error', 'Failed to decline invitation');
    }
  }

  Future<void> approveCancellation(InvitationModel invite) async {
    try {
      await _firebaseProvider.respondToCancellation(invite.id, true);
      Get.snackbar(
        'Project Cancelled',
        'You have agreed to cancel this project.',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to approve cancellation');
    }
  }

  Future<void> declineCancellation(InvitationModel invite) async {
    try {
      await _firebaseProvider.respondToCancellation(invite.id, false);
      Get.snackbar(
        'Feedback Sent',
        'The owner has been notified that you wish to continue.',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to decline cancellation');
    }
  }
}
