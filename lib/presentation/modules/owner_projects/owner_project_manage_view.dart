import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/invitation_model.dart';
import '../../../../data/providers/firebase_provider.dart';
import '../../widgets/glass_card.dart';
import 'owner_project_manage_controller.dart';

class OwnerProjectManageView extends StatelessWidget {
  const OwnerProjectManageView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OwnerProjectManageController());

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(controller),
                Expanded(child: _buildMainContent(controller)),
                _buildBottomActions(controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(OwnerProjectManageController controller) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            padding: EdgeInsets.zero,
            alignment: Alignment.centerLeft,
          ),
          const SizedBox(height: 16),
          Obx(() => Text(
            controller.project.value?.title ?? 'Project',
            style: AppTheme.headlineLarge.copyWith(fontSize: 26),
          )).animate().fadeIn().slideX(begin: -0.2),
          const SizedBox(height: 4),
          Text(
            'Recruitment Management Hub',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(OwnerProjectManageController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
      }

      final project = controller.project.value;
      if (project == null) return const Center(child: Text('Project not found'));

      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsSection(controller),
            const SizedBox(height: 24),

            // AI Discovery Shortcut
            if (project.status == 'active')
              GlassCard(
                padding: const EdgeInsets.all(16),
                borderColor: AppTheme.primary.withValues(alpha: 0.3),
                onTap: () => Get.toNamed('/match-results', arguments: controller.project.value),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Expand Your Team', style: AppTheme.titleLarge.copyWith(fontSize: 16)),
                          const SizedBox(height: 2),
                          Text('Find more AI-matched developers for this project', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.primary),
                  ],
                ),
              ).animate().shimmer(delay: const Duration(seconds: 1), duration: const Duration(seconds: 2)),

            const SizedBox(height: 32),

            if (project.status == 'ready_for_review')
              _buildReviewCelebration(controller).animate().shimmer(duration: const Duration(seconds: 2)),
            
            if (project.status == 'completed')
               _buildProjectCompletedCard(),

            const SizedBox(height: 32),
            
            _buildSectionTitle('Project Workspace'),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description_rounded, color: AppTheme.secondary, size: 20),
                      const SizedBox(width: 8),
                      Text('Internal Directives', style: AppTheme.titleLarge.copyWith(fontSize: 16)),
                      const Spacer(),
                      Obx(() => TextButton.icon(
                        onPressed: controller.isSavingNotes.value ? null : () => controller.saveNotes(),
                        icon: controller.isSavingNotes.value 
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save_rounded, size: 16),
                        label: const Text('SAVE'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.secondary,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller.notesController,
                    maxLines: 4,
                    style: AppTheme.bodyMedium.copyWith(fontSize: 14, height: 1.5),
                    decoration: InputDecoration(
                      hintText: 'Add project goals, links, or internal notes for the team...',
                      hintStyle: const TextStyle(color: Colors.white10),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.02),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (controller.joinRequests.isNotEmpty && project.status == 'active') ...[
              Row(
                children: [
                   const Icon(Icons.inbox_rounded, color: AppTheme.warning, size: 20),
                   const SizedBox(width: 8),
                   _buildSectionTitle('Join Requests'),
                   const SizedBox(width: 8),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                     decoration: BoxDecoration(color: AppTheme.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                     child: Text(controller.joinRequests.length.toString(), style: const TextStyle(color: AppTheme.warning, fontWeight: FontWeight.bold, fontSize: 12)),
                   ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Developers requesting to join your project', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 12),
              ...controller.joinRequests.map((req) => _JoinRequestItem(invite: req, controller: controller)),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 32),
            ],

            _buildSectionTitle(project.status == 'completed' ? 'Team History' : 'Development Team'),
            const SizedBox(height: 4),
            Text('Manage active team members and work status', style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ...controller.invitations.map((invite) => _DeveloperStatusItem(invite: invite, controller: controller)),
            if (controller.invitations.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24, bottom: 16),
                child: Center(child: Text('No developers invited yet', style: TextStyle(color: Colors.white24))),
              ),
            const SizedBox(height: 40),
          ],
        ),
      );
    });
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.headlineMedium.copyWith(fontSize: 18, color: AppTheme.primaryLight),
    );
  }


  Widget _buildReviewCelebration(OwnerProjectManageController controller) {
    return GlassCard(
      borderColor: AppTheme.success.withValues(alpha: 0.3),
      child: Column(
        children: [
          const Icon(Icons.celebration_rounded, color: AppTheme.success, size: 40),
          const SizedBox(height: 12),
          Text('Project Ready!', style: AppTheme.headlineMedium.copyWith(color: AppTheme.success)),
          const SizedBox(height: 4),
          Text(
            'All developers have finished their work. You can now rate them and close the project.',
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _showRatingDialog(controller),
            icon: const Icon(Icons.star_rounded),
            label: const Text('Rate & Finish Project'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCompletedCard() {
    return GlassCard(
      borderColor: Colors.white.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppTheme.success, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Project Completed', style: AppTheme.titleLarge.copyWith(color: AppTheme.success)),
                Text('This project is archived and closed.', style: AppTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(OwnerProjectManageController controller) {
    final acceptedDevs = controller.invitations.where((i) => i.status == 'accepted').toList();
    if (acceptedDevs.isEmpty) return;

    final Map<String, double> ratings = { for (var e in acceptedDevs) e.receiverId : 5.0 };
    final Map<String, TextEditingController> feedbackControllers = { 
       for (var e in acceptedDevs) e.receiverId : TextEditingController() 
    };

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1F3A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Rate Your Team', style: TextStyle(color: Colors.white)),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: acceptedDevs.length,
                itemBuilder: (context, index) {
                  final invite = acceptedDevs[index];
                  final devId = invite.receiverId;
                  final devName = controller.developerNames[devId] ?? 'Developer';
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(devName, style: AppTheme.titleLarge.copyWith(fontSize: 14, color: AppTheme.secondary)),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (sIndex) {
                          return IconButton(
                            onPressed: () => setState(() => ratings[devId] = sIndex + 1.0),
                            iconSize: 24,
                            icon: Icon(
                              sIndex < (ratings[devId] ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: Colors.amber,
                            ),
                          );
                        }),
                      ),
                      TextField(
                        controller: feedbackControllers[devId],
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Feedback for $devName...',
                          hintStyle: const TextStyle(color: Colors.white24),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                      if (index < acceptedDevs.length - 1) const Divider(color: Colors.white10, height: 24),
                    ],
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('CANCEL', style: TextStyle(color: AppTheme.textMuted))),
              Obx(() => ElevatedButton(
                onPressed: controller.isLoading.value ? null : () async {
                  // Submit reviews for all developers
                  for (var invite in acceptedDevs) {
                    await controller.submitReview(
                      developerId: invite.receiverId,
                      rating: ratings[invite.receiverId] ?? 5.0,
                      comment: feedbackControllers[invite.receiverId]?.text ?? '',
                    );
                  }
                  Get.back(); // Close dialog after ALL submissions
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                child: controller.isLoading.value 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('SUBMIT ALL'),
              )),
            ],
          );
        }
      ),
    );
  }



  Widget _buildStatsSection(OwnerProjectManageController controller) {
    return Row(
      children: [
        _StatBox(label: 'Invited', value: controller.invitations.length.toString(), color: AppTheme.primary),
        const SizedBox(width: 12),
        _StatBox(label: 'Accepted', value: controller.acceptedCount.value.toString(), color: AppTheme.success),
        const SizedBox(width: 12),
        _StatBox(label: 'Pending', value: controller.pendingCount.value.toString(), color: AppTheme.warning),
      ],
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildBottomActions(OwnerProjectManageController controller) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Obx(() => ElevatedButton(
        onPressed: controller.acceptedCount.value > 0 ? null : controller.deleteEntireProject,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.error.withValues(alpha: 0.2),
          foregroundColor: AppTheme.error,
          minimumSize: const Size(double.infinity, 56),
          disabledBackgroundColor: Colors.white10,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3))),
        ),
        child: Text(
          controller.acceptedCount.value > 0 ? 'Cannot Delete (Active Developers)' : 'Hard Delete Project',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      )),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassCard(
        child: Column(
          children: [
            Text(value, style: AppTheme.headlineLarge.copyWith(color: color, fontSize: 24)),
            const SizedBox(height: 2),
            Text(label, style: AppTheme.bodySmall.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _DeveloperStatusItem extends StatelessWidget {
  final InvitationModel invite;
  final OwnerProjectManageController controller;

  const _DeveloperStatusItem({required this.invite, required this.controller});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText = invite.status.capitalizeFirst!;
    
    // Check if it's an accepted dev, then show their Work Status
    if (invite.status == 'accepted') {
      statusText = invite.devWorkStatus == 'finished' ? 'COMPLETED WORK ✅' : 'CURRENTLY WORKING 🛠';
      statusColor = invite.devWorkStatus == 'finished' ? AppTheme.success : AppTheme.secondary;
    } else {
      switch (invite.status) {
        case 'declined': statusColor = AppTheme.error; break;
        case 'cancellation_proposed': statusColor = Colors.purpleAccent; break;
        case 'cancelled': statusColor = Colors.grey; break;
        default: statusColor = AppTheme.warning;
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
              Get.toNamed('/public-profile', arguments: {
                'developer': user,
                'project': controller.project.value,
              });
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Obx(() {
                   final photoUrl = controller.developerPhotos[invite.receiverId];
                   return CircleAvatar(
                    radius: 20,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    backgroundColor: AppTheme.surfaceLight,
                    child: photoUrl == null ? const Icon(Icons.person, size: 20) : null,
                  );
                }),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            controller.developerNames[invite.receiverId] ?? 'Loading...', 
                            style: AppTheme.titleLarge.copyWith(fontSize: 15)
                          ),
                          const SizedBox(width: 8),
                          if (invite.status != 'accepted')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.north_east_rounded, size: 8, color: AppTheme.primary),
                                  SizedBox(width: 4),
                                  Text(
                                    'SENT',
                                    style: TextStyle(color: AppTheme.primary, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusText, 
                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)
                      ),
                    ],
                  )),
                ),
                if (invite.status == 'accepted')
                  IconButton(
                    onPressed: () => _showApologyDialog(context),
                    icon: const Icon(Icons.cancel_schedule_send_rounded, color: AppTheme.error, size: 20),
                    tooltip: 'Request Cancellation',
                  )
                else
                   const Icon(Icons.chevron_right_rounded, color: Colors.white24),
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
        backgroundColor: AppTheme.surface,
        title: const Text('Send Apology & Request Cancellation', style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('To delete this project, you must first get approval from the accepted developer.', style: TextStyle(color: Colors.white60, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: apologyController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Write your apology note here...',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
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

// ─── Join Request Item (Developer -> Owner) ─────────────────────────────────
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
                  child: const Icon(Icons.person_rounded, size: 22, color: AppTheme.warning),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            controller.developerNames[invite.senderId] ?? 'Loading...',
                            style: AppTheme.titleLarge.copyWith(fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.south_west_rounded, size: 8, color: AppTheme.secondary),
                                SizedBox(width: 4),
                                Text(
                                  'INCOMING',
                                  style: TextStyle(color: AppTheme.secondary, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Wants to join your project',
                        style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  )),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeclineDialog(invite, controller),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Decline'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(color: AppTheme.error.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => controller.respondToJoinRequest(invite.id, true),
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success.withValues(alpha: 0.15),
                      foregroundColor: AppTheme.success,
                      side: BorderSide(color: AppTheme.success.withValues(alpha: 0.4)),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

// ignore: unused_element
void _showDeclineDialog(InvitationModel invite, OwnerProjectManageController controller) {
  final reasonController = TextEditingController();
  Get.dialog(
    AlertDialog(
      backgroundColor: const Color(0xFF1A1F3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Decline Join Request',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You can optionally provide a reason to the developer.',
              style: TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Reason (optional)...',
              hintStyle: const TextStyle(color: Colors.white24),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
        ElevatedButton(
          onPressed: () {
            Get.back();
            controller.respondToJoinRequest(invite.id, false,
                declineReason: reasonController.text.trim().isEmpty
                    ? null
                    : reasonController.text.trim());
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB00020),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Decline'),
        ),
      ],
    ),
  );
}
