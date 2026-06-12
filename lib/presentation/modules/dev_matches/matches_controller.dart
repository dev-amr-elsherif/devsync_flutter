import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio_lib;
import '../../../../data/models/project_model.dart';
import '../../../../data/models/invitation_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/providers/firebase_provider.dart';
import '../../../../data/services/gemini_service.dart';
import '../auth/auth_controller.dart';

class MatchesController extends GetxController {
  final FirebaseProvider _firebaseProvider = Get.find<FirebaseProvider>();
  final GeminiService _geminiService = Get.find<GeminiService>();

  // ─── State ────────────────────────────────────────────────────────
  final RxList<Map<String, dynamic>> projectMatches = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isSendingRequest = false.obs;

  /// Set of project IDs the developer already sent a request to
  final RxSet<String> sentRequestIds = <String>{}.obs;

  UserModel? _developer;

  @override
  void onInit() {
    super.onInit();
    _developer = Get.find<AuthController>().currentUser.value;
    loadMatches();
  }

  Future<void> loadMatches() async {
    if (_developer == null) return;
    try {
      isLoading.value = true;
      projectMatches.clear();

      // جلب المشاريع + الطلبات المرسلة + الـ invitations المقبولة — كلها بالتوازي
      final results = await Future.wait([
        _firebaseProvider.getProjects(),
        _firebaseProvider.getSentJoinRequests(_developer!.uid),
        _firebaseProvider.getAcceptedInvitationsForDev(_developer!.uid),
      ]);

      final allProjects = results[0] as List<ProjectModel>;
      final sentRequests = results[1] as List<InvitationModel>;
      final acceptedInvites = results[2] as List<InvitationModel>;

      // تتبع الطلبات المرسلة + المشاريع المقبول فيها بالفعل
      sentRequestIds.assignAll(sentRequests.map((r) => r.projectId).toSet());
      final acceptedProjectIds = acceptedInvites.map((i) => i.projectId).toSet();

      // فلتر:
      // 1. فقط المشاريع النشطة (active)
      // 2. ليست للمطور نفسه
      // 3. المطور مش مقبول فيها بالفعل
      final filteredProjects = allProjects.where((p) =>
        p.status == 'active' &&
        p.ownerId != _developer!.uid &&
        !acceptedProjectIds.contains(p.id) &&
        !sentRequestIds.contains(p.id)
      ).toList();

      final devSkills = {
        ...(_developer!.topAiSkills ?? []),
        ..._developer!.skills,
      }.toList();

      if (filteredProjects.isEmpty) {
        isLoading.value = false;
        return;
      }

      try {
        final dio = dio_lib.Dio();
        final baseUrl = GetPlatform.isAndroid ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
        
        final response = await dio.post(
          '$baseUrl/matches/calculate',
          data: {
            'devSkills': devSkills,
            'devSeniority': _developer!.githubSeniority ?? 'Junior',
            'projects': filteredProjects.map((p) => {
              'id': p.id,
              'techStack': p.techStack,
              'description': p.description,
            }).toList(),
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> matches = response.data['matches'];
          final Map<String, double> scoresMap = {
            for (var m in matches) m['projectId']: (m['score'] as num).toDouble()
          };

          final List<Map<String, dynamic>> scored = filteredProjects.map((p) {
            return {
              'project': p,
              'score': scoresMap[p.id] ?? 10.0,
            };
          }).toList();

          scored.sort((a, b) => ((b['score'] as num).toDouble()).compareTo((a['score'] as num).toDouble()));
          projectMatches.assignAll(scored);
        } else {
          throw Exception('Backend Matcher failed with code ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error calling Match Engine: $e');
        // Fallback to basic local matching if backend is down
        final List<Map<String, dynamic>> fallbackScored = filteredProjects.map((p) {
          return {'project': p, 'score': 10.0};
        }).toList();
        projectMatches.assignAll(fallbackScored);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load matches: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendJoinRequest(ProjectModel project) async {
    if (_developer == null || isSendingRequest.value) return;
    if (sentRequestIds.contains(project.id)) {
      Get.snackbar('Already Requested', 'You already sent a request for this project.');
      return;
    }

    try {
      isSendingRequest.value = true;

      final invitation = InvitationModel(
        id: '',
        senderId: _developer!.uid,
        senderName: _developer!.name,
        senderPhotoUrl: _developer!.photoUrl,
        receiverId: project.ownerId,
        receiverName: project.ownerName,
        receiverPhotoUrl: project.ownerPhotoUrl,
        projectId: project.id,
        projectTitle: project.title,
        status: 'join_request',
        timestamp: DateTime.now(),
      );

      await _firebaseProvider.sendInvitation(invitation);
      sentRequestIds.add(project.id);

      Get.snackbar(
        'Request Sent! 🚀',
        'Your join request for "${project.title}" was sent to the project owner.',
        backgroundColor: const Color(0xFF00C896).withValues(alpha: 0.15),
        colorText: const Color(0xFF00C896),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to send request: $e');
    } finally {
      isSendingRequest.value = false;
    }
  }

  UserModel? get developer => _developer;
}
