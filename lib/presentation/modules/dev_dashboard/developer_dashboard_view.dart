import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../data/models/invitation_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/themed_background.dart';
import '../auth/auth_controller.dart';
import '../dev_projects/dev_invitations_controller.dart';
import 'developer_controller.dart';

class DeveloperDashboardView extends GetView<DeveloperController> {
  const DeveloperDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ThemedBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: controller.refreshMatches,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(context),
                _buildStatsRow(context),
                _buildInvitationsSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    final user = Get.find<AuthController>().currentUser.value;
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        Obx(() {
          final isDark = ThemeController.to.isDark;
          return IconButton(
            onPressed: () => ThemeController.to.toggleTheme(),
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: context.colors.textSecondary,
            ),
            tooltip: isDark ? 'Light Mode' : 'Dark Mode',
          );
        }),
        IconButton(
          onPressed: () => Get.find<AuthController>().signOut(),
          icon: Icon(Icons.logout_rounded, color: context.colors.textSecondary),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hey, ${user?.name.split(' ').first ?? 'Developer'} 👋',
              style: AppTheme.headlineLarge.copyWith(
                fontSize: 18,
                color: context.colors.textPrimary,
              ),
            ),
            Text(
              'Your personalized AI career matches.',
              style: AppTheme.bodyMedium.copyWith(
                fontSize: 10,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    final invitesController = Get.find<DevInvitationsController>();
    return SliverToBoxAdapter(
      child: Obx(() {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatCard(
                    label: 'Match Score',
                    value: controller.matches.isNotEmpty
                        ? '${(controller.matches.first['score']).toInt()}%'
                        : '0%',
                    icon: Icons.auto_awesome_rounded,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 12),
                  StatCard(
                    label: 'Active Jobs',
                    value: '${invitesController.activeProjectsCount}',
                    icon: Icons.work_history_rounded,
                    color: AppTheme.secondary,
                  ),
                ],
              ),
              if (invitesController.activeProjectsCount > 0) ...[
                const SizedBox(height: 24),
                _buildRecentActivity(context, invitesController),
              ],
            ],
          ).animate().fadeIn().slideY(begin: 0.1),
        );
      }),
    );
  }

  Widget _buildInvitationsSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Obx(() {
        if (controller.pendingInvitations.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      color: AppTheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'NEW OPPORTUNITIES',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primary,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${controller.pendingInvitations.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: controller.pendingInvitations.length,
                  itemBuilder: (ctx, index) {
                    final invite = controller.pendingInvitations[index];
                    return _InvitationCard(
                      invite: invite,
                      controller: controller,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRecentActivity(
    BuildContext context,
    DevInvitationsController invitesController,
  ) {
    final activeProjects = invitesController.acceptedInvitations;
    if (activeProjects.isEmpty) return const SizedBox.shrink();
    final latest = activeProjects.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RESUME WORK',
              style: AppTheme.bodySmall.copyWith(
                color: context.colors.textMuted,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_right_rounded,
              color: context.colors.textMuted,
              size: 16,
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderColor: AppTheme.secondary.withValues(alpha: 0.3),
          onTap: () async {
            final project = await invitesController.fetchProject(
              latest.projectId,
            );
            if (project != null) {
              Get.toNamed('/project-details', arguments: project);
            }
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: AppTheme.secondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latest.projectTitle,
                      style: AppTheme.titleLarge.copyWith(
                        fontSize: 16,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'TAP TO OPEN WORKSPACE',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 12,
                color: context.colors.textMuted.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InvitationCard extends StatelessWidget {
  final InvitationModel invite;
  final DeveloperController controller;

  const _InvitationCard({required this.invite, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderColor: AppTheme.primary.withValues(alpha: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundImage: invite.senderPhotoUrl != null
                      ? NetworkImage(invite.senderPhotoUrl!)
                      : null,
                  backgroundColor: context.colors.surfaceLight,
                  child: invite.senderPhotoUrl == null
                      ? Icon(
                          Icons.person,
                          size: 14,
                          color: context.colors.textSecondary,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    invite.senderName,
                    style: AppTheme.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              invite.projectTitle,
              style: AppTheme.titleLarge.copyWith(
                fontSize: 14,
                color: context.colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => controller.declineInvitation(invite),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => controller.acceptInvitation(invite),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                      foregroundColor: AppTheme.primary,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Accept',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}
