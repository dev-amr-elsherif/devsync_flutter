import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio_lib;
import 'package:flutter/foundation.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/project_model.dart';
import '../../../../data/providers/firebase_provider.dart';
import '../../../../data/services/gemini_service.dart';
import '../../../../data/services/analytics_service.dart';
import '../auth/auth_controller.dart';

import '../main_shell/main_shell_controller.dart';

class OwnerController extends GetxController {
  // المحركات الأساسية لجلب البيانات وحساب المطابقة
  final FirebaseProvider _firebaseProvider = Get.find<FirebaseProvider>();
  final GeminiService _geminiService = Get.find<GeminiService>();
  final AnalyticsService _analytics = Get.find<AnalyticsService>();

  // ─── State ────────────────────────────────────────────────────────
  final RxList<ProjectModel> myProjects = <ProjectModel>[].obs;
  final RxList<Map<String, dynamic>> developerMatches = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isFindingDevelopers = false.obs;
  final RxBool isCreatingProject = false.obs;
  final RxBool isRefining = false.obs;
  final Rx<ProjectModel?> selectedProject = Rx<ProjectModel?>(null);
  
  // خريطة لتخزين عدد طلبات الانضمام المعلقة لكل مشروع {projectId: count}
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
      final invites = await _firebaseProvider.getInvitationsByProject(project.id);
      final count = invites.where((i) => i.status == 'join_request').length;
      pendingJoinRequests[project.id] = count;
    }
  }

  // إعادة تعيين النموذج (Reset Form) للبدء من جديد
  void resetForm() {
    projectTitle.value = '';
    projectDescription.value = '';
    techStack.clear();
  }

  // إنشاء مشروع جديد وحفظه في الفايربيز
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
        techStack: List.from(techStack),
      );

      final created = await _firebaseProvider.createProject(project);
      
      // Update local state and logs
      myProjects.insert(0, created);
      await _analytics.logProjectCreated(created.title);

      // ─── UX FIX: Reset Form & Switch Tab ───────────────────────────
      resetForm();
      // Switch the main shell tab back to 0 (Dashboard) in the background
      if (Get.isRegistered<MainShellController>()) {
        Get.find<MainShellController>().changePage(0);
      }

      Get.snackbar('Success', 'Project created! finding best developers...',
          backgroundColor: const Color(0xFF00E676).withValues(alpha: 0.1),
          colorText: const Color(0xFF00C896),
          duration: const Duration(seconds: 2));

      // Navigate to recommendation results
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

      try {
        final dio = dio_lib.Dio(dio_lib.BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));
        final baseUrl = GetPlatform.isAndroid ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
        
        // We need to calculate scores for EVERY developer against ONE project.
        // Our endpoint takes devSkills + seniority for ONE dev and Multiple Projects.
        // So we can send a list of "faked" projects where the project is the same but the dev changes?
        // OR: It's better to just call the endpoint for each dev if there aren't many,
        // BUT for efficiency, let's just do it properly.
        
        // For now, to keep it simple and match the backend schema:
        final List<Map<String, dynamic>> results = [];
        
        // Use Future.wait to make multiple calls to the backend in parallel for all developers
        await Future.wait(developers.map((dev) async {
          try {
            final devSkills = {
              ...(dev.topAiSkills ?? []),
              ...dev.skills,
            }.toList().map((s) => s.toString()).toList();

            final response = await dio.post(
              '$baseUrl/matches/calculate',
              data: {
                'devSkills': devSkills,
                'devSeniority': dev.githubSeniority ?? 'Junior',
                'projects': [{
                  'id': project.id,
                  'techStack': project.techStack,
                  'description': project.description,
                }],
              },
            );

            if (response.statusCode == 200) {
              final List matches = response.data['matches'];
              if (matches.isNotEmpty) {
                final double scoreValue = (matches[0]['score'] as num).toDouble();
                results.add({
                  'developer': dev,
                  'score': scoreValue,
                });
              }
            }
          } catch (e) {
            debugPrint('Backend matching failed for ${dev.name}, falling back to AI Cloud Architect...');
            // ─── AI FALLBACK: Use Groq to calculate match score ─────────────
            final aiScore = await _geminiService.calculateMatch(
              dev.skills.join(', '), 
              project.description,
              githubActivity: {
                'top_languages': dev.topAiSkills,
                'seniority': dev.githubSeniority,
              }
            );
            
            results.add({
              'developer': dev,
              'score': aiScore,
            });
          }
        }));

        results.sort((a, b) => ((b['score'] as num).toDouble()).compareTo((a['score'] as num).toDouble()));
        
        // Filter out anyone with less than 20% match as requested
        final filteredResults = results.where((r) => (r['score'] as num).toDouble() >= 20.0).toList();
        
        developerMatches.assignAll(filteredResults);
        await _analytics.logDeveloperSuggested();
      } catch (e) {
        debugPrint('Matching Error: $e');
        Get.snackbar('Matching Error', 'The real-time matching engine is temporarily offline.');
      }
    } catch (e) {
      Get.snackbar('AI Error', 'Matching temporarily unavailable');
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
       Get.snackbar('Idea Needed', 'Please type a basic idea or title first (e.g., Pharmacy App)');
       return;
    }

    try {
      isRefining.value = true;
      final result = await GeminiService().expandProjectIdea(projectTitle.value);
      if (result != null) {
        projectTitle.value = result['title'] ?? projectTitle.value;
        projectDescription.value = result['description'] ?? projectDescription.value;
        if (result['techStack'] != null) {
          techStack.assignAll(List<String>.from(result['techStack']));
        }
        await _analytics.logProjectDescriptionGenerated();
      }
    } catch (e) {
      Get.snackbar('AI Busy', 'Could not refine at this moment. Please try manual entry.');
    } finally {
      isRefining.value = false;
    }
  }

  // ─── Project Templates ──────────────────────────────────────────
  void applyTemplate(String type) {
    switch (type) {
      case 'Mobile App':
        projectTitle.value = 'Cross-Platform Mobile Application';
        projectDescription.value = 'Design and develop a high-performance mobile app for iOS and Android. Focus on smooth animations, offline-first capabilities, and a premium user experience.';
        techStack.assignAll(['Flutter', 'Dart', 'Firebase', 'Git', 'Clean Architecture']);
        break;
      case 'Web Platform':
        projectTitle.value = 'Scalable Web Application';
        projectDescription.value = 'Build a responsive, multi-page web platform with modern frontend frameworks and a robust backend. Requirements include SEO optimization and secure user authentication.';
        techStack.assignAll(['React', 'Node.js', 'PostgreSQL', 'Tailwind CSS', 'Redux']);
        break;
      case 'AI Engine':
        projectTitle.value = 'AI Integration & Automation';
        projectDescription.value = 'Integrate Large Language Models (LLMs) into existing workflows. Developing custom agents, prompt engineering pipelines, and data processing vectors.';
        techStack.assignAll(['Python', 'OpenAI API', 'LangChain', 'Pinecone', 'FastAPI']);
        break;
      case 'E-Commerce':
        projectTitle.value = 'Premium Digital Storefront';
        projectDescription.value = 'A secure and highly scalable e-commerce solution with integrated payment gateways, real-time inventory tracking, and an admin dashboard.';
        techStack.assignAll(['Next.js', 'Stripe', 'Prisma', 'Supabase', 'TypeScript']);
        break;
    }
    Get.snackbar('Template Applied', 'Draft has been populated for $type', 
        backgroundColor: Get.theme.primaryColor.withValues(alpha: 0.1), 
        colorText: Get.theme.primaryColor);
  }

  UserModel? get owner => _owner;
}
