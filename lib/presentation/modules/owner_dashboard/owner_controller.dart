// lib/presentation/modules/owner_dashboard/owner_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/project_model.dart';
import '../../../../data/providers/firebase_provider.dart';
import '../../../../data/services/groq_service.dart'; // ✅ Renamed
import '../../../../data/services/analytics_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../auth/auth_controller.dart';
import '../main_shell/main_shell_controller.dart';

class OwnerController extends GetxController {
  final FirebaseProvider _firebaseProvider = Get.find<FirebaseProvider>();
  final GroqService _groqService = Get.find<GroqService>(); // ✅ Get.find دايماً
  final AnalyticsService _analytics = Get.find<AnalyticsService>();

  // ✅ Dio instance واحد مشترك بدل new في كل call
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  // ─── State ────────────────────────────────────────────────────────
  final RxList<ProjectModel> myProjects = <ProjectModel>[].obs;
  final RxList<Map<String, dynamic>> developerMatches =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isFindingDevelopers = false.obs;
  final RxBool isCreatingProject = false.obs;
  final RxBool isRefining = false.obs;
  final Rx<ProjectModel?> selectedProject = Rx<ProjectModel?>(null);
  final RxMap<String, int> pendingJoinRequests = <String, int>{}.obs;

  // ─── Form State ───────────────────────────────────────────────────
  final RxString projectTitle = ''.obs;
  final RxString projectDescription = ''.obs;
  final RxList<String> techStack = <String>[].obs;

  UserModel? _owner;

  @override
  void onInit() {
    super.onInit();
    _owner = Get.find<AuthController>().currentUser.value;
    loadProjects();
  }

  Future<void> loadProjects() async {
    try {
      isLoading.value = true;
      final projects = await _firebaseProvider.getProjects();
      myProjects.assignAll(
        projects.where((p) => p.ownerId == _owner?.uid).toList(),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to load projects');
    } finally {
      isLoading.value = false;
      _loadPendingCounts();
    }
  }

  Future<void> _loadPendingCounts() async {
    for (var project in myProjects) {
      final invites = await _firebaseProvider.getInvitationsByProject(
        project.id,
      );
      final count = invites
          .where((i) => i.isJoinRequest)
          .length; // ✅ Enum helper
      pendingJoinRequests[project.id] = count;
    }
  }

  void resetForm() {
    projectTitle.value = '';
    projectDescription.value = '';
    techStack.clear();
  }

  Future<void> createProject() async {
    if (projectTitle.value.trim().isEmpty) {
      Get.snackbar('Error', 'Please enter a project title');
      return;
    }
    if (_owner == null) return;

    try {
      isCreatingProject.value = true;
      final project = ProjectModel(
        id: '',
        ownerId: _owner!.uid,
        ownerName: _owner!.name,
        ownerPhotoUrl: _owner!.photoUrl,
        title: projectTitle.value.trim(),
        description: projectDescription.value.trim(),
        techStack: List<String>.from(techStack),
      );

      final created = await _firebaseProvider.createProject(project);
      myProjects.insert(0, created);
      await _analytics.logProjectCreated(created.title);

      resetForm();
      if (Get.isRegistered<MainShellController>()) {
        Get.find<MainShellController>().changePage(0);
      }

      Get.snackbar(
        'Success',
        'Project created! Finding best developers...',
        backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.1),
        colorText: const Color(0xFF00C896),
        duration: const Duration(seconds: 2),
      );

      Get.toNamed('/match-results', arguments: created);
    } catch (e) {
      Get.snackbar('Error', 'Failed to create project: $e');
    } finally {
      isCreatingProject.value = false;
    }
  }

  Future<void> findDevelopersForProject(ProjectModel project) async {
    try {
      isFindingDevelopers.value = true;
      selectedProject.value = project;
      developerMatches.clear();

      final developers = await _firebaseProvider.getDevelopers();
      if (developers.isEmpty) return;

      final List<Map<String, dynamic>> results = [];

      await Future.wait(
        developers.map((dev) async {
          try {
            final devSkills = <String>{
              ...(dev.topAiSkills ?? []),
              ...dev.skills,
            }.toList();

            // ✅ استخدام ApiConstants بدل URL مكتوب جوا الكود
            final response = await _dio.post(
              '${ApiConstants.pythonBackendUrl}/matches/calculate',
              data: {
                'devSkills': devSkills,
                'devSeniority': dev.githubSeniority ?? 'Junior',
                'projects': [
                  {
                    'id': project.id,
                    'techStack': project.techStack,
                    'description': project.description,
                  },
                ],
              },
            );

            if (response.statusCode == 200) {
              final List matches = response.data['matches'];
              if (matches.isNotEmpty) {
                results.add({
                  'developer': dev,
                  'score': (matches[0]['score'] as num).toDouble(),
                });
              }
            }
          } catch (e) {
            // Fallback to Groq cloud matching
            final aiScore = await _groqService.calculateMatch(
              dev.skills.join(', '),
              project.description,
              githubActivity: {
                'top_languages': dev.topAiSkills,
                'seniority': dev.githubSeniority,
              },
            );
            results.add({'developer': dev, 'score': aiScore});
          }
        }),
      );

      results.sort(
        (a, b) => (b['score'] as double).compareTo(a['score'] as double),
      );

      developerMatches.assignAll(
        results.where((r) => (r['score'] as double) >= 20.0).toList(),
      );
      await _analytics.logDeveloperSuggested();
    } catch (e) {
      debugPrint('Matching Error: $e');
      Get.snackbar(
        'Matching Error',
        'The real-time matching engine is temporarily offline.',
      );
    } finally {
      isFindingDevelopers.value = false;
    }
  }

  // ─── Tech Stack Management ────────────────────────────────────────
  void addTech(String tech) {
    final cleaned = tech.trim();
    if (cleaned.isNotEmpty && !techStack.contains(cleaned)) {
      techStack.add(cleaned);
    }
  }

  void removeTech(String tech) => techStack.remove(tech);

  Future<void> refineProjectWithAI() async {
    if (projectTitle.value.trim().isEmpty) {
      Get.snackbar('Idea Needed', 'Please type a basic idea or title first.');
      return;
    }
    try {
      isRefining.value = true;
      // ✅ استخدام Get.find بدل new GroqService()
      final result = await _groqService.expandProjectIdea(projectTitle.value);
      if (result != null) {
        projectTitle.value = result['title'] ?? projectTitle.value;
        projectDescription.value =
            result['description'] ?? projectDescription.value;
        if (result['techStack'] != null) {
          techStack.assignAll(List<String>.from(result['techStack']));
        }
        await _analytics.logProjectDescriptionGenerated();
      }
    } catch (e) {
      Get.snackbar(
        'AI Busy',
        'Could not refine at this moment. Please try manual entry.',
      );
    } finally {
      isRefining.value = false;
    }
  }

  // ─── Project Templates ────────────────────────────────────────────
  void applyTemplate(String type) {
    switch (type) {
      case 'Mobile App':
        projectTitle.value = 'Cross-Platform Mobile Application';
        projectDescription.value =
            'Design and develop a high-performance mobile app for iOS and Android.';
        techStack.assignAll([
          'Flutter',
          'Dart',
          'Firebase',
          'Git',
          'Clean Architecture',
        ]);
        break;
      case 'Web Platform':
        projectTitle.value = 'Scalable Web Application';
        projectDescription.value =
            'Build a responsive, multi-page web platform with modern frontend frameworks.';
        techStack.assignAll([
          'React',
          'Node.js',
          'PostgreSQL',
          'Tailwind CSS',
          'Redux',
        ]);
        break;
      case 'AI Engine':
        projectTitle.value = 'AI Integration & Automation';
        projectDescription.value =
            'Integrate Large Language Models (LLMs) into existing workflows.';
        techStack.assignAll([
          'Python',
          'OpenAI API',
          'LangChain',
          'Pinecone',
          'FastAPI',
        ]);
        break;
      case 'E-Commerce':
        projectTitle.value = 'Premium Digital Storefront';
        projectDescription.value =
            'A secure and scalable e-commerce solution with integrated payment gateways.';
        techStack.assignAll([
          'Next.js',
          'Stripe',
          'Prisma',
          'Supabase',
          'TypeScript',
        ]);
        break;
    }
    Get.snackbar(
      'Template Applied',
      'Draft has been populated for $type',
      backgroundColor: Get.theme.primaryColor.withValues(alpha: 0.1),
      colorText: Get.theme.primaryColor,
    );
  }

  UserModel? get owner => _owner;
}
