import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/invitation_model.dart';
import '../../../../data/providers/firebase_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/themed_background.dart';
import 'owner_project_manage_controller.dart';

class OwnerProjectManageView extends StatelessWidget {
  const OwnerProjectManageView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OwnerProjectManageController());

    return Scaffold(
      body: ThemedBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, controller),
              Expanded(child: _buildMainContent(context, controller)),
              _buildBottomActions(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    OwnerProjectManageController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: context.colors.textPrimary,
            ),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          const SizedBox(height: 16),
          Obx(
            () => Text(
              controller.project.value?.title ?? 'Project',
              style: AppTheme.headlineLarge.copyWith(
                fontSize: 26,
                color: context.colors.textPrimary,
              ),
            ),
          ).animate().fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 4),
          Text(
            'Recruitment Management Hub',
            style: AppTheme.bodyMedium.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    OwnerProjectManageController controller,
  ) {
    return Obx(() {
      if (controller.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        );
      }

      final project = controller.project.value;
      if (project == null) {
        return Center(
          child: Text(
            'Project not found',
            style: TextStyle(color: context.colors.textPrimary),
          ),
        );
      }

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsSection(context, controller),
            const SizedBox(height: 24),

            if (project.status == 'active')
              GlassCard(
                padding: const EdgeInsets.all(16),
                borderColor: AppTheme.primary.withValues(alpha: 0.3),
                onTap: () => Get.toNamed(
                  '/match-results',
                  arguments: controller.project.value,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: AppTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expand Your Team',
                            style: AppTheme.titleLarge.copyWith(
                              fontSize: 16,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Find more AI-matched developers for this project',
                            style: AppTheme.bodySmall.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppTheme.primary,
                    ),
                  ],
                ),
              ).animate().shimmer(
                delay: const Duration(seconds: 1),
                duration: const Duration(seconds: 2),
              ),

            const SizedBox(height: 32),

            if (project.status == 'ready_for_review')
              _buildReviewCelebration(
                context,
                controller,
              ).animate().shimmer(duration: const Duration(seconds: 2)),

            if (project.status == 'completed')
              _buildProjectCompletedCard(context),

            const SizedBox(height: 32),

            _buildSectionTitle(context, 'Project Workspace'),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.description_rounded,
                        color: AppTheme.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Internal Directives',
                        style: AppTheme.titleLarge.copyWith(
                          fontSize: 16,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Obx(
                        () => TextButton.icon(
                          onPressed: controller.isSavingNotes.value
                              ? null
                              : () => controller.saveNotes(),
                          icon: controller.isSavingNotes.value
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_rounded, size: 16),
                          label: const Text('SAVE'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.secondary,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.notesController,
                    maxLines: 4,
                    style: AppTheme.bodyMedium.copyWith(
                      fontSize: 14,
                      height: 1.5,
                      color: context.colors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Add project goals, links, or internal notes for the team...',
                      hintStyle: TextStyle(
                        color: context.colors.textMuted.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: context.colors.surfaceLight.withValues(
                        alpha: 0.5,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (controller.joinRequests.isNotEmpty &&
                project.status == 'active') ...[
              Row(
                children: [
                  const Icon(
                    Icons.inbox_rounded,
                    color: AppTheme.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  _buildSectionTitle(context, 'Join Requests'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      controller.joinRequests.length.toString(),
                      style: const TextStyle(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Developers requesting to join your project',
                style: AppTheme.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ...controller.joinRequests.map(
                (req) => _JoinRequestItem(invite: req, controller: controller),
              ),
              const SizedBox(height: 24),
              Divider(color: context.colors.divider),
              const SizedBox(height: 32),
            ],

            _buildSectionTitle(
              context,
              project.status == 'completed'
                  ? 'Team History'
                  : 'Development Team',
            ),
            const SizedBox(height: 4),
            Text(
              'Manage active team members and work status',
              style: AppTheme.bodySmall.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ...controller.invitations.map(
              (invite) =>
                  _DeveloperStatusItem(invite: invite, controller: controller),
            ),
            if (controller.invitations.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 16),
                child: Center(
                  child: Text(
                    'No developers invited yet',
                    style: TextStyle(color: context.colors.textMuted),
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      );
    });
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTheme.headlineMedium.copyWith(
        fontSize: 18,
        color: AppTheme.primaryLight,
      ),
    );
  }

  Widget _buildReviewCelebration(
    BuildContext context,
    OwnerProjectManageController controller,
  ) {
    return GlassCard(
      borderColor: AppTheme.success.withValues(alpha: 0.3),
      child: Column(
        children: [
          const Icon(
            Icons.celebration_rounded,
            color: AppTheme.success,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'Project Ready!',
            style: AppTheme.headlineMedium.copyWith(color: AppTheme.success),
          ),
          const SizedBox(height: 4),
          Text(
            'All developers have finished their work. You can now rate them and close the project.',
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall.copyWith(
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showRatingDialog(context, controller),
            icon: const Icon(Icons.star_rounded),
            label: const Text('Rate & Finish Project'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCompletedCard(BuildContext context) {
    return GlassCard(
      borderColor: context.colors.divider,
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppTheme.success, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Project Completed',
                  style: AppTheme.titleLarge.copyWith(color: AppTheme.success),
                ),
                Text(
                  'This project is archived and closed.',
                  style: AppTheme.bodySmall.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context,
    OwnerProjectManageController controller,
  ) {
    return Row(
      children: [
        _StatBox(
          label: 'Invited',
          value: controller.invitations.length.toString(),
          color: AppTheme.primary,
        ),
        const SizedBox(width: 12),
        _StatBox(
          label: 'Accepted',
          value: controller.acceptedCount.value.toString(),
          color: AppTheme.success,
        ),
        const SizedBox(width: 12),
        _StatBox(
          label: 'Pending',
          value: controller.pendingCount.value.toString(),
          color: AppTheme.warning,
        ),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildBottomActions(
    BuildContext context,
    OwnerProjectManageController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Obx(
        () => ElevatedButton(
          onPressed: controller.acceptedCount.value > 0
              ? null
              : controller.deleteEntireProject,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.error.withValues(alpha: 0.2),
            foregroundColor: AppTheme.error,
            minimumSize: const Size(double.infinity, 56),
            disabledBackgroundColor: context.colors.surfaceLight.withValues(
              alpha: 0.3,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
            ),
          ),
          child: Text(
            controller.acceptedCount.value > 0
                ? 'Cannot Delete (Active Developers)'
                : 'Hard Delete Project',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  void _showRatingDialog(
    BuildContext context,
    OwnerProjectManageController controller,
  ) {
    final acceptedDevs = controller.invitations
        .where((i) => i.status == InvitationStatus.accepted)
        .toList();
    if (acceptedDevs.isEmpty) return;

    final Map<String, double> ratings = {
      for (var e in acceptedDevs) e.receiverId: 5.0,
    };
    final Map<String, TextEditingController> feedbackControllers = {
      for (var e in acceptedDevs) e.receiverId: TextEditingController(),
    };

    Get.dialog(
      StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            backgroundColor: context.colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Rate Your Team',
              style: TextStyle(color: context.colors.textPrimary),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: acceptedDevs.length,
                itemBuilder: (context, index) {
                  final invite = acceptedDevs[index];
                  final devId = invite.receiverId;
                  final devName =
                      controller.developerNames[devId] ?? 'Developer';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          devName,
                          style: AppTheme.titleLarge.copyWith(
                            fontSize: 14,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (sIndex) {
                          return IconButton(
                            onPressed: () =>
                                setState(() => ratings[devId] = sIndex + 1.0),
                            iconSize: 24,
                            icon: Icon(
                              sIndex < (ratings[devId] ?? 0)
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: Colors.amber,
                            ),
                          );
                        }),
                      ),
                      TextField(
                        controller: feedbackControllers[devId],
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 12,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Feedback for $devName...',
                          hintStyle: TextStyle(
                            color: context.colors.textMuted.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          filled: true,
                          fillColor: context.colors.surfaceLight.withValues(
                            alpha: 0.5,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      if (index < acceptedDevs.length - 1)
                        Divider(color: context.colors.divider, height: 24),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: Text(
                  'CANCEL',
                  style: TextStyle(color: context.colors.textMuted),
                ),
              ),
              Obx(
                () => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () async {
                          for (var invite in acceptedDevs) {
                            await controller.submitReview(
                              developerId: invite.receiverId,
                              rating: ratings[invite.receiverId] ?? 5.0,
                              comment:
                                  feedbackControllers[invite.receiverId]
                                      ?.text ??
                                  '',
                            );
                          }
                          Get.back();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('SUBMIT ALL'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Stat Box ────────────────────────────────────────────────────────────────
class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        child: Column(
          children: [
            Text(
              value,
              style: AppTheme.headlineLarge.copyWith(
                color: color,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                fontSize: 10,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Developer Status Item ───────────────────────────────────────────────────
class _DeveloperStatusItem extends StatelessWidget {
  final InvitationModel invite;
  final OwnerProjectManageController controller;

  const _DeveloperStatusItem({required this.invite, required this.controller});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText = invite.status.toFirestoreString().capitalizeFirst!;

    if (invite.status == InvitationStatus.accepted) {
      statusText = invite.devWorkStatus == DevWorkStatus.finished
          ? 'COMPLETED WORK ✅'
          : 'CURRENTLY WORKING 🛠';
      statusColor = invite.devWorkStatus == DevWorkStatus.finished
          ? AppTheme.success
          : AppTheme.secondary;
    } else {
      switch (invite.status) {
        case InvitationStatus.declined:
          statusColor = AppTheme.error;
          break;
        case InvitationStatus.cancellationProposed:
          statusColor = Colors.purpleAccent;
          break;
        case InvitationStatus.cancelled:
          statusColor = Colors.grey;
          break;
        default:
          statusColor = AppTheme.warning;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () async {
            final user = await FirebaseProvider().getUser(invite.receiverId);
            if (user != null) {
              Get.toNamed(
                '/public-profile',
                arguments: {
                  'developer': user,
                  'project': controller.project.value,
                },
              );
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Obx(() {
                  final photoUrl =
                      controller.developerPhotos[invite.receiverId];
                  return CircleAvatar(
                    radius: 20,
                    backgroundImage: photoUrl != null
                        ? NetworkImage(photoUrl)
                        : null,
                    backgroundColor: context.colors.surfaceLight,
                    child: photoUrl == null
                        ? Icon(
                            Icons.person,
                            size: 20,
                            color: context.colors.textSecondary,
                          )
                        : null,
                  );
                }),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              controller.developerNames[invite.receiverId] ??
                                  'Loading...',
                              style: AppTheme.titleLarge.copyWith(
                                fontSize: 15,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (invite.status != InvitationStatus.accepted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.north_east_rounded,
                                      size: 8,
                                      color: AppTheme.primary,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'SENT',
                                      style: TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (invite.status == InvitationStatus.accepted)
                  IconButton(
                    onPressed: () => _showApologyDialog(context),
                    icon: const Icon(
                      Icons.cancel_schedule_send_rounded,
                      color: AppTheme.error,
                      size: 20,
                    ),
                    tooltip: 'Request Cancellation',
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.colors.textMuted,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showApologyDialog(BuildContext context) {
    final apologyController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: context.colors.surface,
        title: Text(
          'Send Apology & Request Cancellation',
          style: TextStyle(color: context.colors.textPrimary, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'To delete this project, you must first get approval from the accepted developer.',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: apologyController,
              maxLines: 3,
              style: TextStyle(color: context.colors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Write your apology note here...',
                hintStyle: TextStyle(
                  color: context.colors.textMuted.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: context.colors.surfaceLight.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (apologyController.text.isNotEmpty) {
                controller.sendApology(invite.id, apologyController.text);
                Get.back();
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }
}

// ─── Join Request Item ───────────────────────────────────────────────────────
class _JoinRequestItem extends StatelessWidget {
  final InvitationModel invite;
  final OwnerProjectManageController controller;

  const _JoinRequestItem({required this.invite, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderColor: AppTheme.warning.withValues(alpha: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.warning.withValues(alpha: 0.15),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 22,
                    color: AppTheme.warning,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              controller.developerNames[invite.senderId] ??
                                  'Loading...',
                              style: AppTheme.titleLarge.copyWith(
                                fontSize: 14,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.south_west_rounded,
                                    size: 8,
                                    color: AppTheme.secondary,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'INCOMING',
                                    style: TextStyle(
                                      color: AppTheme.secondary,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Wants to join your project',
                          style: AppTheme.bodySmall.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showDeclineDialog(context, invite, controller),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(
                        color: AppTheme.error.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        controller.respondToJoinRequest(invite.id, true),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success.withValues(alpha: 0.15),
                      foregroundColor: AppTheme.success,
                      side: BorderSide(
                        color: AppTheme.success.withValues(alpha: 0.4),
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void _showDeclineDialog(
  BuildContext context,
  InvitationModel invite,
  OwnerProjectManageController controller,
) {
  final reasonController = TextEditingController();
  Get.dialog(
    AlertDialog(
      backgroundColor: context.colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Decline Request',
        style: TextStyle(color: context.colors.textPrimary),
      ),
      content: TextField(
        controller: reasonController,
        maxLines: 3,
        style: TextStyle(color: context.colors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Reason for declining...',
          hintStyle: TextStyle(
            color: context.colors.textMuted.withValues(alpha: 0.5),
          ),
          filled: true,
          fillColor: context.colors.surfaceLight.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text(
            'Cancel',
            style: TextStyle(color: context.colors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            controller.respondToJoinRequest(invite.id, false);
            Get.back();
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
          child: const Text('Decline', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
