import 'package:dio/dio.dart' as dio_lib;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../data/models/project_model.dart';
import '../../../../data/providers/firebase_provider.dart';

class MatchResultsController extends GetxController {
  final FirebaseProvider _firebaseProvider = FirebaseProvider();

  final RxList<Map<String, dynamic>> rankedDevelopers = <Map<String, dynamic>>[].obs;
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

      // 1. Fetch all developers
      final developers = await _firebaseProvider.getDevelopers();
      if (developers.isEmpty) {
        isLoading.value = false;
        return;
      }
      
      final List<Map<String, dynamic>> results = [];
      final dio = dio_lib.Dio();
      final baseUrl = GetPlatform.isAndroid ? 'http://10.0.2.2:8000' : 'http://localhost:8000';

      // 2. Rank each developer using the Python Backend in parallel
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
          debugPrint('Matching error for ${dev.name}: $e');
          // Default fallback score
          results.add({
            'developer': dev,
            'score': 10.0,
          });
        }
      }));

      // 3. Sort by score descending and filter
      results.sort((a, b) => ((b['score'] as num).toDouble()).compareTo((a['score'] as num).toDouble()));
      
      // Filter out matches < 20%
      final filtered = results.where((r) => (r['score'] as num).toDouble() >= 20.0).toList();
      
      rankedDevelopers.assignAll(filtered);
    } catch (e) {
      debugPrint('Overall Ranking Error: $e');
      Get.snackbar('Ranking Error', 'The AI matching engine is temporarily offline.');
    } finally {
      isLoading.value = false;
    }
  }
}
