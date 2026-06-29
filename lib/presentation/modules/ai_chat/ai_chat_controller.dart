import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio_lib;
import '../../../../data/services/groq_service.dart'; // ✅ FIX
import '../auth/auth_controller.dart';
import '../../../../data/models/project_model.dart';
import '../../../../data/providers/firebase_provider.dart';
import '../main_shell/main_shell_controller.dart';

class AIChatController extends GetxController {
  final GroqService _groqService = Get.find<GroqService>(); // ✅ FIX
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseProvider _firebaseProvider = Get.find<FirebaseProvider>();

  final ScrollController scrollController = ScrollController();
  final RxList<dynamic> history = [].obs;
  final RxBool isLoading = false.obs;
  final RxMap<String, dynamic> proposedProject = <String, dynamic>{}.obs;

  final RxBool isReadyToFinalize = false.obs;
  final RxDouble projectHealth = 0.0.obs;
  final RxList<String> quickReplies = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _sendInitialGreeting();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendInitialGreeting() async {
    if (history.isNotEmpty) return;
    final role = _authController.currentUser.value?.role;
    String greeting;
    if (role == 'owner') {
      greeting =
          "Hello! I am your Project Architect. I'll help you define your project clearly.\n"
          "To start, is this a Mobile app, a Web platform, or both? And what is the core idea?";
      quickReplies.assignAll(['Mobile App 📱', 'Web Platform 🌐', 'Both 📱🌐']);
    } else {
      greeting =
          "Hi there! I'm your DevSync assistant. How can I help you improve your profile or find the right project today?";
      quickReplies.assignAll(['Find Projects', 'Improve Profile', 'Help']);
    }
    history.add({'role': 'model', 'text': greeting});
    _scrollToBottom();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    try {
      isLoading.value = true;
      history.add({'role': 'user', 'text': text});
      _scrollToBottom();
      quickReplies.clear();
      projectHealth.value = (projectHealth.value + 0.15).clamp(0.0, 1.0);

      final responseText = await _groqService.sendMessage(history); // ✅ FIX

      if (responseText != null) {
        String cleanText = responseText;
        if (cleanText.contains('[READY_TO_FINALIZE]')) {
          isReadyToFinalize.value = true;
          projectHealth.value = 1.0;
          cleanText = cleanText.replaceAll('[READY_TO_FINALIZE]', '').trim();
          quickReplies.assignAll(['Finalize Now! 🚀', 'Add more details']);
        } else {
          if (history.length < 4) {
            quickReplies.assignAll([
              'Explain features',
              'Tech stack ideas',
              'Skip to target',
            ]);
          } else {
            quickReplies.assignAll([
              'Ready? Check now',
              'Main problems',
              'User stories',
            ]);
          }
        }
        history.add({'role': 'model', 'text': cleanText});
        _scrollToBottom();
      }
    } catch (e) {
      String errorMsg = 'AI Assistant is currently unavailable.';
      if (e is dio_lib.DioException) {
        if (e.type == dio_lib.DioExceptionType.connectionTimeout ||
            e.type == dio_lib.DioExceptionType.receiveTimeout) {
          errorMsg = 'Connection timed out. Please check your internet.';
        } else if (e.response?.statusCode == 429) {
          errorMsg = 'Rate limit reached. Please wait a moment.';
        }
      }
      Get.snackbar(
        'Assistant Error',
        errorMsg,
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> finalizeProject() async {
    try {
      isLoading.value = true;
      final proposal = await _groqService.extractProjectProposal(
        history,
      ); // ✅ FIX
      if (proposal != null) {
        proposedProject.assignAll(proposal);
      } else {
        Get.snackbar(
          'AI Architect',
          "I need a bit more information to define the project. Let's keep talking!",
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to generate proposal: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> confirmAndCreateProject() async {
    final proposal = proposedProject;
    if (proposal.isEmpty) return;
    try {
      isLoading.value = true;
      final user = _authController.currentUser.value;
      if (user == null) return;

      final project = ProjectModel(
        id: '',
        ownerId: user.uid,
        ownerName: user.name,
        ownerPhotoUrl: user.photoUrl,
        title: proposal['title'] ?? 'Untitled Project',
        description: proposal['description'] ?? '',
        techStack: List<String>.from(proposal['techStack'] ?? []),
        status: 'active',
      );

      final createdProject = await _firebaseProvider.createProject(project);
      proposedProject.clear();

      if (Get.isRegistered<MainShellController>()) {
        Get.find<MainShellController>().changePage(0);
      }

      Get.back();
      Get.snackbar(
        'Success',
        'Project "${createdProject.title}" has been created!',
        backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.1),
        colorText: const Color(0xFF00C896),
      );
      Get.toNamed('/match-results', arguments: createdProject);
    } catch (e) {
      Get.snackbar('Error', 'Failed to create project: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
