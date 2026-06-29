import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/project_model.dart';
import '../../../../data/models/invitation_model.dart';
import '../../../../data/providers/firebase_provider.dart';
import '../../../../data/services/groq_service.dart'; // ✅ FIX
import '../../../../data/services/analytics_service.dart';
import '../../../../data/services/github_service.dart';
import '../auth/auth_controller.dart';

class DeveloperController extends GetxController {
  final FirebaseProvider _firebaseProvider = Get.find<FirebaseProvider>();
  final GroqService _groqService = Get.find<GroqService>(); // ✅ FIX
  final AnalyticsService _analytics = Get.find<AnalyticsService>();
  final GithubService _githubService = GithubService();

  final RxList<ProjectModel> projects = <ProjectModel>[].obs;
  final RxList<Map<String, dynamic>> matches = <Map<String, dynamic>>[].obs;
  final RxList<InvitationModel> pendingInvitations = <InvitationModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool hasError = false.obs;
  final RxString errorMessage = ''.obs;

  UserModel? _developer;
  StreamSubscription? _invitationSub;

  @override
  void onInit() {
    super.onInit();
    _developer = Get.find<AuthController>().currentUser.value;
    loadInitialData();
    _listenToInvitations();
  }

  @override
  void onClose() {
    _invitationSub?.cancel();
    super.onClose();
  }

  void _listenToInvitations() {
    if (_developer == null) return;
    _invitationSub?.cancel();
    _invitationSub = _firebaseProvider
        .streamInvitations(_developer!.uid)
        .listen((data) {
          // ✅ FIX: compare with InvitationStatus enum
          pendingInvitations.assignAll(
            data.where((i) => i.status == InvitationStatus.pending).toList(),
          );
        });
  }

  Future<void> loadInitialData() async {
    try {
      isLoading.value = true;
      hasError.value = false;
      projects.clear();
      matches.clear();

      final snapshot = await _firebaseProvider.getProjects();
      projects.assignAll(snapshot.where((p) => p.status == 'active').toList());

      if (_developer != null && projects.isNotEmpty) {
        await _runAIMatching();
      }
    } catch (e) {
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _runAIMatching() async {
    if (_developer == null) return;
    await _analytics.logAIMatchRequested();

    final githubActivity = await _githubService.getUserActivity(
      _developer!.name.replaceAll(' ', ''),
    );

    final List<Map<String, dynamic>> results = [];
    for (var project in projects) {
      final score = await _groqService.calculateMatch(
        // ✅ FIX
        _developer!.skills.join(', '),
        project.description,
        githubActivity: githubActivity,
      );
      results.add({'project': project, 'score': score});
    }

    results.sort(
      (a, b) => (b['score'] as double).compareTo(a['score'] as double),
    );
    matches.assignAll(results);
  }

  Future<void> acceptInvitation(InvitationModel invitation) async {
    try {
      await _firebaseProvider.updateInvitationStatus(invitation.id, 'accepted');
      Get.snackbar(
        'Success! 🚀',
        'Project "${invitation.projectTitle}" accepted. Check your Projects tab.',
        backgroundColor: Colors.green.withValues(alpha: 0.1),
        colorText: Colors.green,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to accept invitation');
    }
  }

  Future<void> declineInvitation(InvitationModel invitation) async {
    try {
      await _firebaseProvider.updateInvitationStatus(invitation.id, 'declined');
      Get.snackbar(
        'Declined',
        'Invitation for "${invitation.projectTitle}" was declined.',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to decline invitation');
    }
  }

  Future<void> refreshMatches() async {
    await _analytics.logProfileRefreshed();
    await loadInitialData();
  }

  UserModel? get developer => _developer;
}
