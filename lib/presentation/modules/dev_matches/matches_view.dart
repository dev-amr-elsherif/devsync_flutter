import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/project_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/match_score_badge.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/skill_chip.dart';
import '../../widgets/app_empty_state.dart';
import 'matches_controller.dart';

class MatchesView extends StatelessWidget {
  const MatchesView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MatchesController>();

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(controller),
                Expanded(child: _buildBody(controller)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(MatchesController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Project Matches', style: AppTheme.headlineLarge),
                    const SizedBox(height: 4),
                    Obx(() => Text(
                      controller.isLoading.value
                          ? 'Analyzing your skills against projects...'
                          : '${controller.projectMatches.length} projects curated for your profile',
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary, fontSize: 11),
                    )),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  onPressed: controller.loadMatches,
                  icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryLight, size: 20),
                  tooltip: 'Refresh Matches',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
        ],
      ),
    );
  }

  Widget _buildBody(MatchesController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.projectMatches.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.primary),
              const SizedBox(height: 24),
              Text('AI Scanning Ecosystem', style: AppTheme.headlineMedium.copyWith(fontSize: 16)),
              const SizedBox(height: 8),
              Text('Matching your GitHub seniority with active projects...', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
            ],
          ).animate().fadeIn(),
        );
      }

      if (controller.projectMatches.isEmpty) {
        return AppEmptyState(
          icon: Icons.search_off_rounded,
          title: 'No Matches Found',
          subtitle: 'Check back later or try updating your technical skill sets.',
          action: OutlinedButton(onPressed: controller.loadMatches, child: const Text('REFRESH')),
        );
      }

      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        itemCount: controller.projectMatches.length,
        itemBuilder: (ctx, i) {
          final match = controller.projectMatches[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ProjectMatchCard(
              controller: controller,
              match: match,
              index: i,
            ),
          );
        },
      );
    });
  }
}

class _ProjectMatchCard extends StatelessWidget {
  final MatchesController controller;
  final Map<String, dynamic> match;
  final int index;

  const _ProjectMatchCard({
    required this.controller,
    required this.match,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final ProjectModel project = match['project'];
    final double score = match['score'];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.title, style: AppTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Owner: ${project.ownerName}', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              MatchScoreBadge(score: score / 100, size: 52),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            project.description,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (project.techStack.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: project.techStack.take(4).map((tech) => SkillChip(label: tech)).toList(),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 16),
          Obx(() {
            final alreadySent = controller.sentRequestIds.contains(project.id);
            return SizedBox(
              width: double.infinity,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: alreadySent
                    ? StatusBadge.invitationStatus('join_request')
                    : ElevatedButton.icon(
                        key: const ValueKey('request'),
                        onPressed: controller.isSendingRequest.value
                            ? null
                            : () => controller.sendJoinRequest(project),
                        icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                        label: const Text('Request to Join'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                          foregroundColor: AppTheme.primary,
                          side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          minimumSize: const Size(double.infinity, 48),
                          elevation: 0,
                        ),
                      ).animate().shimmer(delay: const Duration(seconds: 2), duration: const Duration(seconds: 2)),
              ),
            );
          }),
        ],
      ),
    ).animate(delay: (80 * index).ms).fadeIn().slideY(begin: 0.1);
  }
}
