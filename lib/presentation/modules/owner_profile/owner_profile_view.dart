import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../auth/auth_controller.dart';

class OwnerProfileView extends StatelessWidget {
  const OwnerProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final user = controller.currentUser.value;

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(user),
                  const SizedBox(height: 32),
                  _buildProfileCard(user),
                  const SizedBox(height: 40),
                  _buildLogoutButton(controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(user) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.5), width: 2),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
            child: user?.photoUrl == null ? const Icon(Icons.person, size: 50) : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user?.name ?? 'Project Owner',
          style: AppTheme.headlineMedium,
        ),
        Text(
          user?.email ?? '',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildProfileCard(user) {
    return GlassCard(
      child: Column(
        children: [
          _buildInfoRow(Icons.business_center_rounded, 'Role', 'PROJECT OWNER'),
          const Divider(color: Colors.white10, height: 32),
          _buildInfoRow(Icons.email_rounded, 'Email', user?.email ?? 'N/A'),
          const Divider(color: Colors.white10, height: 32),
          _buildInfoRow(Icons.info_outline_rounded, 'Status', 'Active Account'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 22),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary)),
            Text(value, style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildLogoutButton(AuthController controller) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => controller.signOut(),
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Sign Out'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.error,
          side: const BorderSide(color: AppTheme.error),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
