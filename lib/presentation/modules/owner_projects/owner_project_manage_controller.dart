import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../../../data/models/invitation_model.dart';
import '../../../../data/models/project_model.dart';
import '../../../../data/providers/firebase_provider.dart';

class OwnerProjectManageController extends GetxController {
  final FirebaseProvider _firebaseProvider = FirebaseProvider();
  
  final Rxn<ProjectModel> project = Rxn<ProjectModel>();
  // دعوات المدير للمطورين (pending / accepted...)
  final RxList<InvitationModel> invitations = <InvitationModel>[].obs;
  // طلبات انضمام المطورين لمشروعنا
  final RxList<InvitationModel> joinRequests = <InvitationModel>[].obs;
  final RxMap<String, String> developerNames = <String, String>{}.obs;
  final RxMap<String, String?> developerPhotos = <String, String?>{}.obs;
  final RxBool isLoading = true.obs;
  final RxBool isSavingNotes = false.obs;

  // Controller للملاحظات الداخلية
  late TextEditingController notesController;

  // Stats
  final RxInt pendingCount = 0.obs;
  final RxInt acceptedCount = 0.obs;
  final RxInt declinedCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    notesController = TextEditingController();
    _handleArguments();
  }

  Future<void> _handleArguments() async {
    final args = Get.arguments;
    if (args is ProjectModel) {
      project.value = args;
      _setupStream(args.id);
      notesController.text = args.internalNotes;
      await _loadProjectInvitations();
    } else if (args is String && args.isNotEmpty) {
      try {
        isLoading.value = true;
        final fetchedProject = await _firebaseProvider.getProject(args);
        if (fetchedProject != null) {
          project.value = fetchedProject;
          _setupStream(args);
          notesController.text = fetchedProject.internalNotes;
          await _loadProjectInvitations();
        } else {
          _handleNotFound();
        }
      } catch (e) {
        _handleError(e);
      } finally {
        isLoading.value = false;
      }
    } else {
      isLoading.value = false;
    }
  }

  void _handleNotFound() {
    if (Navigator.canPop(Get.context!)) Get.back();
    Get.snackbar('Error', 'Project not found');
  }

  void _handleError(dynamic e) {
    if (Navigator.canPop(Get.context!)) Get.back();
    Get.snackbar('Error', 'Failed to load project: $e');
  }

  StreamSubscription? _projectSub;
  StreamSubscription? _invitationsSub;

  void _setupStream(String projectId) {
    _projectSub?.cancel();
    _projectSub = _firebaseProvider.streamProject(projectId).listen((data) {
      if (data != null) project.value = data;
    });
  }

  @override
  void onClose() {
    notesController.dispose();
    _projectSub?.cancel();
    _invitationsSub?.cancel();
    super.onClose();
  }

  Future<void> saveNotes() async {
    if (project.value == null) return;
    try {
      isSavingNotes.value = true;
      await _firebaseProvider.updateProjectState(project.value!.id, {
        'internalNotes': notesController.text.trim(),
      });
      Get.snackbar('Success', 'Project notes updated for the team.', 
        backgroundColor: Colors.green.withValues(alpha: 0.1), colorText: Colors.green);
    } catch (e) {
      Get.snackbar('Error', 'Failed to save notes');
    } finally {
      isSavingNotes.value = false;
    }
  }

  Future<void> _loadProjectInvitations() async {
    isLoading.value = true;
    final currentProject = project.value;
    if (currentProject == null) return;

    try {
      final list = await _firebaseProvider.getInvitationsByProject(currentProject.id);

      // فصل دعوات المدير عن طلبات المطورين
      invitations.assignAll(list.where((i) => i.status != 'join_request').toList());
      joinRequests.assignAll(list.where((i) => i.status == 'join_request').toList());
      _updateStats();
      
      // Fetch names for all senders/receivers
      final allUserIds = {
        ...list.map((i) => i.receiverId),
        ...list.map((i) => i.senderId),
      };
      for (var uid in allUserIds) {
        if (!developerNames.containsKey(uid) || !developerPhotos.containsKey(uid)) {
          final user = await _firebaseProvider.getUser(uid);
          if (user != null) {
            developerNames[uid] = user.name;
            developerPhotos[uid] = user.photoUrl;
          }
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load recruitment data');
    } finally {
      isLoading.value = false;
    }
  }

  void _updateStats() {
    pendingCount.value = invitations.where((i) => i.status == 'pending').length;
    acceptedCount.value = invitations.where((i) => i.status == 'accepted').length;
    declinedCount.value = invitations.where((i) => i.status == 'declined').length;
  }

  Future<void> deleteEntireProject() async {
    final currentProject = project.value;
    if (currentProject == null) return;

    // إذا كان هناك مقبولين، يجب إرسال اعتذار أولاً لكل واحد
    if (acceptedCount.value > 0) {
      Get.snackbar('Important', 'You must settle with all accepted developers before deletion');
      return;
    }

    try {
      await _firebaseProvider.hardDeleteProject(currentProject.id);
      Get.back();
      Get.snackbar('Success', 'Project deleted from database');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete project');
    }
  }

  Future<void> sendApology(String invitationId, String apology) async {
    try {
      await _firebaseProvider.proposeCancellation(invitationId, apology);
      await _loadProjectInvitations();
      Get.snackbar('Success', 'Apology sent to developer');
    } catch (e) {
      Get.snackbar('Error', 'Failed to send apology');
    }
  }

  Future<void> respondToJoinRequest(String invitationId, bool isAccepted, {String? declineReason}) async {
    final currentProject = project.value;
    if (currentProject == null) return;

    try {
      await _firebaseProvider.respondToJoinRequest(invitationId, isAccepted, declineReason: declineReason);
      await _loadProjectInvitations();
      // Re-fetch project to see if status updated (Actually bindStream handles this, but we can await for certainty)
      final updated = await _firebaseProvider.getProject(currentProject.id);
      if (updated != null) project.value = updated;
      
      Get.snackbar(
        isAccepted ? 'Developer Accepted! 🎉' : 'Request Declined',
        isAccepted ? 'The developer has been accepted to the project.' : 'The join request has been declined.',
        backgroundColor: isAccepted
            ? const Color(0xFF00C896).withValues(alpha: 0.15)
            : const Color(0xFFB00020).withValues(alpha: 0.15),
        colorText: isAccepted ? const Color(0xFF00C896) : const Color(0xFFB00020),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to respond to request: $e');
    }
  }

  Future<void> submitReview({
    required String developerId,
    required double rating,
    required String comment,
  }) async {
    final currentProject = project.value;
    if (currentProject == null) return;

    try {
      isLoading.value = true;
      final reviewData = {
        'projectId': currentProject.id,
        'projectTitle': currentProject.title,
        'ownerId': currentProject.ownerId,
        'ownerName': currentProject.ownerName,
        'developerId': developerId,
        'rating': rating,
        'comment': comment,
      };

      await _firebaseProvider.submitReview(reviewData, developerId);
      
      // Refresh project state
      final updated = await _firebaseProvider.getProject(currentProject.id);
      if (updated != null) project.value = updated;
      
      Get.snackbar('Success', 'Review submitted for ${developerNames[developerId] ?? "developer"}', 
        backgroundColor: const Color(0xFF00C896).withValues(alpha: 0.1), colorText: const Color(0xFF00C896));
    } catch (e) {
      Get.snackbar('Error', 'Failed to submit review');
    } finally {
      isLoading.value = false;
    }
  }
}
