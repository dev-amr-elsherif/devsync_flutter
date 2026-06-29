// lib/presentation/modules/matches/match_results_controller.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../data/models/project_model.dart';
import '../../../../data/providers/firebase_provider.dart';

class MatchResultsController extends GetxController {
  // ✅ Get.find بدل new FirebaseProvider()
  final FirebaseProvider _firebaseProvider = Get.find<FirebaseProvider>();

  // ✅ Dio instance واحد مشترك
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  final RxList<Map<String, dynamic>> rankedDevelopers =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;

  late ProjectModel project;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is ProjectModel) {
      project = Get.arguments;
      _loadAndRankDevelopers();
    } else {
      Get.back();
      Get.snackbar('Error', 'Project data not found');
    }
  }

  Future<void> _loadAndRankDevelopers() async {
    try {
      isLoading.value = true;
      rankedDevelopers.clear();

      final developers = await _firebaseProvider.getDevelopers();
      if (developers.isEmpty) {
        isLoading.value = false;
        return;
      }

      final List<Map<String, dynamic>> results = [];

      await Future.wait(
        developers.map((dev) async {
          try {
            final devSkills = <String>{
              ...(dev.topAiSkills ?? []),
              ...dev.skills,
            }.toList();

            // ✅ ApiConstants.pythonBackendUrl بدل URL مكتوب هنا
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
            debugPrint('Matching error for ${dev.name}: $e');
            // Default fallback score
            results.add({'developer': dev, 'score': 10.0});
          }
        }),
      );

      results.sort(
        (a, b) => (b['score'] as double).compareTo(a['score'] as double),
      );

      rankedDevelopers.assignAll(
        results.where((r) => (r['score'] as double) >= 20.0).toList(),
      );
    } catch (e) {
      debugPrint('Overall Ranking Error: $e');
      Get.snackbar(
        'Ranking Error',
        'The AI matching engine is temporarily offline.',
      );
    } finally {
      isLoading.value = false;
    }
  }
}
