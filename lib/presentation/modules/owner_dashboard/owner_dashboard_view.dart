import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/project_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/match_score_badge.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/skill_chip.dart';
import '../../widgets/app_empty_state.dart';
import '../../widgets/stat_card.dart';
import '../auth/auth_controller.dart';
import 'owner_controller.dart';

class OwnerDashboardView extends GetView<OwnerController> {
  const OwnerDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient)),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                _buildStatsRow(),
                _buildProjectsList(),
                _buildDeveloperMatchesSection(),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    final user = Get.find<AuthController>().currentUser.value;
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      actions: [
        IconButton(
          onPressed: () => Get.find<AuthController>().signOut(),
          icon: const Icon(Icons.logout_rounded, color: AppTheme.textSecondary),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${user?.name.split(' ').first ?? "Owner"}\'s Dashboard 🚀',
              style: AppTheme.headlineLarge.copyWith(fontSize: 18),
            ),
            Text(
              'Monitor projects and find top talent',
              style: AppTheme.bodyMedium.copyWith(fontSize: 10, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return SliverToBoxAdapter(
      child: Obx(() {
        if (controller.isLoading.value && controller.myProjects.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Row(
            children: [
              StatCard(
                label: 'Total Projects',
                value: '${controller.myProjects.length}',
                icon: Icons.folder_copy_rounded,
                color: AppTheme.primary,
              ),
              const SizedBox(width: 12),
              StatCard(
                label: 'Total Matches',
                value: '${controller.developerMatches.length}',
                icon: Icons.auto_awesome_rounded,
                color: AppTheme.secondary,
              ),
            ],
          ).animate().fadeIn().slideY(begin: 0.1),
        );
      }),
    );
  }

  Widget _buildProjectsList() {
    return Obx(() {
      if (controller.isLoading.value && controller.myProjects.isEmpty) {
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: MatchCardShimmer(),
            ),
            childCount: 3,
          ),
        );
      }

      if (controller.myProjects.isEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: Icons.folder_open_rounded,
            title: 'No Projects Yet',
            subtitle: 'Go to the "Create" tab to launch your first project and start matching.',
          ),
        );
      }

      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) {
            final project = controller.myProjects[i];
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: _ProjectCard(project: project, index: i),
            );
          },
          childCount: controller.myProjects.length,
        ),
      );
    });
  }

  Widget _buildDeveloperMatchesSection() {
    return Obx(() {
      if (controller.selectedProject.value == null || controller.developerMatches.isEmpty) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }

      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.hub_rounded, color: AppTheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('AI Matching Results', style: AppTheme.headlineLarge),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Top developers for "${controller.selectedProject.value!.title}"',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 20),
              if (controller.isFindingDevelopers.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.secondary),
                  ),
                )
              else
                ...controller.developerMatches.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _DeveloperMatchCard(
                          match: e.value,
                          index: e.key,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      );
    });
  }
}

class _ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final int index;

  const _ProjectCard({required this.project, required this.index});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.toNamed('/owner-project-manage', arguments: project),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(project.title, style: AppTheme.headlineMedium),
                ),
                StatusBadge.projectStatus(project.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              project.description.isNotEmpty ? project.description : 'No description provided.',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            if (project.techStack.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: project.techStack
                    .take(4)
                    .map((t) => SkillChip(label: t))
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                const Icon(Icons.people_outline_rounded, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 6),
                Text(
                  'Tap to manage recruitment',
                  style: TextStyle(fontSize: 10, color: AppTheme.primary.withValues(alpha: 0.8), fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Obx(() {
                  final controller = Get.find<OwnerController>();
                  final count = controller.pendingJoinRequests[project.id] ?? 0;
                  if (count > 0) return StatusBadge.newCount(count);
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: 100 * index)).fadeIn().slideY(begin: 0.1);
  }
}

class _DeveloperMatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final int index;

  const _DeveloperMatchCard({required this.match, required this.index});

  @override
  Widget build(BuildContext context) {
    final UserModel developer = match['developer'];
    final double score = (match['score'] as num).toDouble();

    return GestureDetector(
      onTap: () => Get.toNamed(
        '/public-profile', 
        arguments: {
          'developer': developer, 
          'project': Get.find<OwnerController>().selectedProject.value
        }
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderColor: AppTheme.secondary.withValues(alpha: 0.2),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
              ),
              child: ClipOval(
                child: developer.photoUrl != null && developer.photoUrl!.isNotEmpty
                    ? Image.network(
                        developer.photoUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: AppTheme.primary),
                        loadingBuilder: (context, child, loadingProgress) => loadingProgress == null ? child : const CircularProgressIndicator(strokeWidth: 1),
                      )
                    : const Icon(Icons.person, color: AppTheme.primary),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(developer.name, style: AppTheme.titleLarge.copyWith(fontSize: 16)),
                  const SizedBox(height: 2),
                  if (developer.skills.isNotEmpty)
                    Text(
                      developer.skills.take(3).join(' • '),
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                    ),
                ],
              ),
            ),
            MatchScoreBadge(score: score / 100, size: 48),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: 80 * index)).fadeIn().slideX(begin: 0.1);
  }
}
