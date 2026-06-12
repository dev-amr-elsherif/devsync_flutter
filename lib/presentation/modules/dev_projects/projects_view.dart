import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/invitation_model.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/app_empty_state.dart';
import 'dev_invitations_controller.dart';

class ProjectsView extends StatelessWidget {
  const ProjectsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DevInvitationsController());

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(child: _buildBody(controller)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Engagements', style: AppTheme.headlineLarge.copyWith(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            'Keep track of your active projects and progress.',
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
        ],
      ),
    );
  }

  Widget _buildBody(DevInvitationsController controller) {
    return Obx(() {
      if (controller.isLoading.value && controller.invitations.isEmpty && controller.myJoinRequests.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
      }

      final filteredInvites = controller.filteredInvitations;
      final filteredReqs = controller.filteredRequests;
      final hasData = filteredInvites.isNotEmpty || filteredReqs.isNotEmpty;

      return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildStatsHeader(controller)),
          SliverToBoxAdapter(child: _buildFilterBar(controller)),
          if (!hasData)
            SliverFillRemaining(
              hasScrollBody: false,
              child: AppEmptyState(
                icon: Icons.filter_list_off_rounded,
                title: 'No Matching Projects',
                subtitle: 'No projects found for the selected filter. Try switching to "All".',
              ),
            )
          else ...[
            if (filteredInvites.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeader(title: 'Invitations', icon: Icons.mail_rounded, color: AppTheme.primary),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _TrackingCard(
                      invitation: filteredInvites[index], 
                      isInvitation: true, 
                      index: index, 
                      controller: controller
                    ),
                    childCount: filteredInvites.length,
                  ),
                ),
              ),
            ],
            if (filteredReqs.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                sliver: SliverToBoxAdapter(
                  child: _SectionHeader(title: 'My Join Requests', icon: Icons.send_rounded, color: AppTheme.secondary),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _TrackingCard(
                      invitation: filteredReqs[index], 
                      isInvitation: false, 
                      index: index, 
                      controller: controller
                    ),
                    childCount: filteredReqs.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      );
    });
  }

  Widget _buildStatsHeader(DevInvitationsController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        children: [
          _buildStatCard('Active', controller.activeProjectsCount.toString(), AppTheme.success),
          const SizedBox(width: 12),
          _buildStatCard('Invites', controller.pendingInvitesCount.toString(), AppTheme.primary),
          const SizedBox(width: 12),
          _buildStatCard('Requests', controller.pendingRequestsCount.toString(), AppTheme.secondary),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        borderColor: color.withValues(alpha: 0.2),
        child: Column(
          children: [
            Text(value, style: AppTheme.headlineMedium.copyWith(color: color, fontSize: 18)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(DevInvitationsController controller) {
    final filters = ['All', 'Active', 'Pending', 'History'];
    return Container(
      height: 45,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          return Obx(() {
            final isSelected = controller.selectedFilter.value == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (val) => controller.selectedFilter.value = filter,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                selectedColor: AppTheme.secondary.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.secondary : Colors.white60,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                side: BorderSide(color: isSelected ? AppTheme.secondary.withValues(alpha: 0.3) : Colors.transparent),
              ),
            );
          });
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader({required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(title, style: AppTheme.titleLarge.copyWith(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _TrackingCard extends StatelessWidget {
  final InvitationModel invitation;
  final bool isInvitation;
  final int index;
  final DevInvitationsController controller;

  const _TrackingCard({
    required this.invitation,
    required this.isInvitation,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final String person = isInvitation ? invitation.senderName : (invitation.receiverName ?? 'Project Owner');
    final String? photoUrl = isInvitation ? invitation.senderPhotoUrl : invitation.receiverPhotoUrl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: InkWell(
          onTap: invitation.status == 'accepted' 
            ? () async {
                final project = await controller.fetchProject(invitation.projectId);
                if (project != null) Get.toNamed('/project-details', arguments: project);
              }
            : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      backgroundColor: AppTheme.surfaceLight,
                      child: photoUrl == null ? const Icon(Icons.person, size: 18) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(invitation.projectTitle, style: AppTheme.titleLarge.copyWith(fontSize: 14)),
                          Text('By $person', style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                    StatusBadge.invitationStatus(invitation.status),
                  ],
                ),
                if (invitation.status == 'accepted') 
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('TAP TO OPEN WORKSPACE', style: AppTheme.bodySmall.copyWith(color: AppTheme.secondary, fontWeight: FontWeight.bold, fontSize: 10)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_right_alt_rounded, color: AppTheme.secondary, size: 14),
                      ],
                    ),
                  ),
                if (invitation.status == 'pending' && isInvitation) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => controller.declineInvitation(invitation),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.error,
                        side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => controller.acceptInvitation(invitation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.success.withValues(alpha: 0.1),
                        foregroundColor: AppTheme.success,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
            if (invitation.status == 'declined' && invitation.declineReason != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                child: Text('Reason: ${invitation.declineReason}', style: AppTheme.bodySmall.copyWith(color: AppTheme.error, fontSize: 11)),
              ),
            ],
            ],
          ),
        ),
      ),
    ),
  ).animate(delay: (80 * index).ms).fadeIn().slideY(begin: 0.1);
  }
}
