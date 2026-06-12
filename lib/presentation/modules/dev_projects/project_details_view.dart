import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/project_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/skill_chip.dart';
import '../../widgets/custom_button.dart';
import 'project_details_controller.dart';

class ProjectDetailsView extends GetView<ProjectDetailsController> {
  const ProjectDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is initialized
    Get.put(ProjectDetailsController());

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient)),
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
            }
            
            final project = controller.project.value;
            if (project == null) return const Center(child: Text('Project not found'));

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(project),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMainInfo(project),
                        const SizedBox(height: 24),
                        
                        // ─── Phase 2: Project Workspace (Accepted Devs only) ───
                        if (controller.myInvitation.value != null) ...[
                           _buildWorkspace(project),
                           const SizedBox(height: 32),
                        ],

                        // ─── Team Members (Colleagues) Section ───
                        if (controller.allProjectMembers.isNotEmpty) ...[
                          _buildSectionTitle('Team Colleagues'),
                          const SizedBox(height: 12),
                          _buildColleaguesList(),
                          const SizedBox(height: 24),
                        ],

                        // ─── Manager Instructions / Notes ───
                        if (project.internalNotes.isNotEmpty) ...[
                          _buildSectionTitle('Manager Directives'),
                          const SizedBox(height: 12),
                          _buildManagerNotes(project.internalNotes),
                          const SizedBox(height: 32),
                        ],

                        _buildSectionTitle('Project Description'),
                        const SizedBox(height: 12),
                        _buildDescription(project.description),
                        const SizedBox(height: 32),
                        
                        _buildSectionTitle('Technical Stack'),
                        const SizedBox(height: 16),
                        _buildTechStack(project.techStack),
                        const SizedBox(height: 120), // Bottom padding
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
          _buildFloatingAction(),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(ProjectModel project) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(project.title, style: AppTheme.titleLarge.copyWith(fontSize: 18)),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppTheme.surface.withValues(alpha: 0.8)),
            Center(
              child: Icon(
                project.status == 'completed' ? Icons.verified_rounded : Icons.code_rounded, 
                size: 80, 
                color: project.status == 'completed' ? AppTheme.success.withValues(alpha: 0.1) : Colors.white10
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInfo(ProjectModel project) {
    return GlassCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
            child: const Icon(Icons.person, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OWNER', style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted, letterSpacing: 1.2)),
                Text(project.ownerName, style: AppTheme.titleLarge.copyWith(fontSize: 16)),
              ],
            ),
          ),
          StatusBadge.projectStatus(project.status),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildWorkspace(ProjectModel project) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Project Workspace'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('LIVE SYNC', style: AppTheme.bodySmall.copyWith(color: AppTheme.secondary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          borderColor: AppTheme.secondary.withValues(alpha: 0.05),
          child: Column(
            children: [
              _buildStatusStep(
                title: 'Development Phase',
                subtitle: 'Active coding and implementation.',
                icon: Icons.biotech_rounded,
                isActive: controller.myInvitation.value?.devWorkStatus == 'in_progress',
                isDone: controller.myInvitation.value?.devWorkStatus == 'finished',
                onTap: () => controller.updateMyStatus('in_progress'),
              ),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider(color: Colors.white10)),
              _buildStatusStep(
                title: 'Testing & QA',
                subtitle: 'Stability check and performance testing.',
                icon: Icons.bug_report_rounded,
                isActive: false, // For future finer steps
                isDone: controller.myInvitation.value?.devWorkStatus == 'finished',
                onTap: null, // Unified under 'finished' for now as per user request
              ),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider(color: Colors.white10)),
              _buildStatusStep(
                title: 'Mark as Finished',
                subtitle: 'ready for handover to manager.',
                icon: Icons.task_alt_rounded,
                isActive: false,
                isDone: controller.myInvitation.value?.devWorkStatus == 'finished',
                color: AppTheme.success,
                onTap: () => _showFinishDialog(),
              ),
            ],
          ),
        ),
        if (controller.myInvitation.value?.devWorkStatus == 'finished' && project.status != 'ready_for_review')
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                const SizedBox(width: 4),
                const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Waiting for other developers to finish before the manager can review.',
                    style: AppTheme.bodySmall.copyWith(color: Colors.amber.withValues(alpha: 0.8), fontSize: 11),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn().shake(),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildStatusStep({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isActive,
    required bool isDone,
    VoidCallback? onTap,
    Color? color,
  }) {
    return ListTile(
      onTap: isDone ? null : onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDone || isActive) ? (color ?? AppTheme.secondary).withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isDone ? Icons.check_circle_rounded : icon, 
          color: (isDone || isActive) ? (color ?? AppTheme.secondary) : AppTheme.textMuted, 
          size: 20
        ),
      ),
      title: Text(title, style: AppTheme.titleLarge.copyWith(fontSize: 14, color: isDone ? AppTheme.textMuted : AppTheme.textPrimary)),
      subtitle: Text(subtitle, style: AppTheme.bodySmall.copyWith(fontSize: 10)),
      trailing: isDone 
        ? const Icon(Icons.done_all_rounded, color: AppTheme.success, size: 18)
        : (onTap != null ? const Icon(Icons.chevron_right_rounded, size: 18) : null),
    );
  }

  Widget _buildColleaguesList() {
    return SizedBox(
      height: 80,
      child: Obx(() => ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.allProjectMembers.length,
        itemBuilder: (context, i) {
          final invite = controller.allProjectMembers[i];
          final photoUrl = controller.teamPhotos[invite.receiverId];
          final name = controller.teamNames[invite.receiverId] ?? '...';

          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.surfaceLight,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null ? const Icon(Icons.person, color: AppTheme.textMuted) : null,
                ),
                const SizedBox(height: 4),
                Text(name.split(' ').first, style: AppTheme.bodySmall.copyWith(fontSize: 9)),
              ],
            ),
          );
        },
      )),
    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1);
  }

  Widget _buildManagerNotes(String notes) {
    return GlassCard(
      borderColor: AppTheme.primary.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text('DIRECTIVES', style: AppTheme.titleLarge.copyWith(fontSize: 12, color: Colors.amber, letterSpacing: 1.2)),
            ],
          ),
          const SizedBox(height: 12),
          Text(notes, style: AppTheme.bodyMedium.copyWith(fontSize: 14, height: 1.6, color: Colors.white.withValues(alpha: 0.9))),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.headlineMedium.copyWith(fontSize: 18, color: AppTheme.primaryLight),
    );
  }

  Widget _buildDescription(String description) {
    return Text(
      description,
      style: AppTheme.bodyMedium.copyWith(height: 1.6, color: AppTheme.textSecondary),
    );
  }

  Widget _buildTechStack(List<String> skills) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: skills.map((skill) => SkillChip(label: skill)).toList(),
    );
  }

  Widget _buildFloatingAction() {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: DevSyncButton(
        id: 'btn_back',
        onPressed: () => Get.back(),
        borderColor: Colors.white.withValues(alpha: 0.1),
        child: const Text('Close Details'),
      ),
    );
  }

  void _showFinishDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Completion', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you have finished your tasks? This will notify the manager once all team members are ready.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            onPressed: () {
              Get.back();
              controller.updateMyStatus('finished');
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success.withValues(alpha: 0.2), foregroundColor: AppTheme.success),
            child: const Text('YES, FINISHED'),
          ),
        ],
      ),
    );
  }
}
