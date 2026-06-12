import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'match_results_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/match_score_badge.dart';
import '../../../../data/models/user_model.dart';

class MatchResultsView extends GetView<MatchResultsController> {
  const MatchResultsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient)),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildProjectInfo(),
                const Divider(color: Colors.white10),
                Expanded(child: _buildResultsList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text('Ranked Developers', style: AppTheme.headlineLarge.copyWith(fontSize: 22)),
          ),
          TextButton(
            onPressed: () => Get.offAllNamed('/main-shell'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.secondary,
              backgroundColor: AppTheme.secondary.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('FINISH', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Results for: ${controller.project.title}',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.primaryLight, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Based on GitHub-analyzed skills and project requirements.',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 24),
              Text('Analyzing developer skills with AI...', style: TextStyle(color: Colors.white60)),
            ],
          ),
        );
      }

      if (controller.rankedDevelopers.isEmpty) {
        return const Center(child: Text('No developers found in the database.'));
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: controller.rankedDevelopers.length,
        itemBuilder: (context, index) {
          final item = controller.rankedDevelopers[index];
          final UserModel dev = item['developer'];
          final double score = item['score'];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => Get.toNamed(
                '/public-profile', 
                arguments: {'developer': dev, 'project': controller.project}
              ),
              child: GlassCard(
                child: Row(
                  children: [
                     CircleAvatar(
                      radius: 28,
                      backgroundImage: dev.photoUrl != null ? NetworkImage(dev.photoUrl!) : null,
                      child: dev.photoUrl == null ? const Icon(Icons.person) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dev.name, style: AppTheme.headlineMedium.copyWith(fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(dev.email, style: AppTheme.bodySmall),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: dev.skills.take(3).map((s) => _SkillTag(skill: s)).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    MatchScoreBadge(score: score / 100, size: 50),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class _SkillTag extends StatelessWidget {
  final String skill;
  const _SkillTag({required this.skill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Text(skill, style: const TextStyle(color: AppTheme.primaryLight, fontSize: 10)),
    );
  }
}
