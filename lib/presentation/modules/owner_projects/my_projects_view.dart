import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/invitation_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_empty_state.dart';
import 'owner_projects_controller.dart';

class MyProjectsView extends StatelessWidget {
  const MyProjectsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OwnerProjectsController());

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Stack(
          children: [
            Container(decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient)),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TabBar(
                      dividerColor: Colors.transparent,
                      indicatorColor: AppTheme.secondary,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelColor: AppTheme.secondary,
                      unselectedLabelColor: AppTheme.textMuted,
                      labelStyle: AppTheme.titleLarge.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: 'Received'),
                        Tab(text: 'Sent'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildReceivedList(controller),
                        _buildSentList(controller),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recruitment Tracker', style: AppTheme.headlineLarge.copyWith(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            'Monitor incoming requests and outgoing invitations.',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildReceivedList(OwnerProjectsController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.receivedJoinRequests.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: AppTheme.secondary));
      }

      if (controller.receivedJoinRequests.isEmpty) {
        return AppEmptyState(
          icon: Icons.inbox_outlined,
          title: 'No Incoming Requests',
          subtitle: 'No developers have requested to join your projects yet.',
        );
      }

      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        itemCount: controller.receivedJoinRequests.length,
        itemBuilder: (context, index) => _TrackingCard(
          invitation: controller.receivedJoinRequests[index],
          isIncoming: true,
          index: index,
        ),
      );
    });
  }

  Widget _buildSentList(OwnerProjectsController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.sentInvitations.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
      }

      if (controller.sentInvitations.isEmpty) {
        return AppEmptyState(
          icon: Icons.outbox_outlined,
          title: 'No Sent Invitations',
          subtitle: 'You haven\'t sent any recruitment invitations to developers yet.',
        );
      }

      return ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        itemCount: controller.sentInvitations.length,
        itemBuilder: (context, index) => _TrackingCard(
          invitation: controller.sentInvitations[index],
          isIncoming: false,
          index: index,
        ),
      );
    });
  }
}


class _TrackingCard extends StatelessWidget {
  final InvitationModel invitation;
  final bool isIncoming;
  final int index;

  const _TrackingCard({required this.invitation, required this.isIncoming, required this.index});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OwnerProjectsController>();
    final String name = isIncoming ? invitation.senderName : (invitation.receiverName ?? 'Developer');
    final String? photoUrl = isIncoming ? invitation.senderPhotoUrl : invitation.receiverPhotoUrl;
    final bool isJoinRequest = invitation.status == 'join_request';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderColor: isJoinRequest ? AppTheme.secondary.withValues(alpha: 0.2) : null,
        child: Column(
          children: [
            InkWell(
              onTap: () => Get.toNamed('/owner-project-manage', arguments: invitation.projectId),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                          backgroundColor: AppTheme.surfaceLight,
                          child: photoUrl == null ? const Icon(Icons.person, size: 20) : null,
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: isIncoming ? AppTheme.secondary : AppTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.surface, width: 2),
                            ),
                            child: Icon(
                              isIncoming ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                              size: 10,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(name, style: AppTheme.titleLarge.copyWith(fontSize: 15)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isIncoming ? AppTheme.secondary : AppTheme.primary).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isIncoming ? 'INCOMING' : 'SENT',
                                  style: TextStyle(
                                    color: isIncoming ? AppTheme.secondary : AppTheme.primary,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            invitation.projectTitle,
                            style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    StatusBadge.invitationStatus(invitation.status),
                  ],
                ),
              ),
            ),
            if (isJoinRequest) ...[
              const Divider(color: Colors.white10, height: 1),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => controller.respondToJoinRequest(invitation.id, false),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                        child: const Text('Decline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => controller.respondToJoinRequest(invitation.id, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondary.withValues(alpha: 0.1),
                          foregroundColor: AppTheme.secondary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Accept', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (invitation.status == 'accepted')
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('TAP TO MANAGE', style: AppTheme.bodySmall.copyWith(color: AppTheme.secondary, letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 9)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, color: AppTheme.secondary, size: 10),
                  ],
                ),
              ),
          ],
        ),
      ),
    ).animate(delay: (80 * index).ms).fadeIn().slideX(begin: 0.1);
  }
}
