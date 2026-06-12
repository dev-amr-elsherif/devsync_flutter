import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../auth/auth_controller.dart';
import '../../../../data/models/user_model.dart';


class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Error', 'Could not open the link');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    
    return Scaffold(
      backgroundColor: const Color(0xFF0D121F), // Very dark slate to match screenshot
      body: SafeArea(
        child: Obx(() {
          final user = controller.currentUser.value;
          if (user == null) return const Center(child: CircularProgressIndicator());

          return DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder: (context, _) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Column(
                        children: [
                          _buildTopAppBar(),
                          const SizedBox(height: 16),
                          _buildHeader(user),
                          const SizedBox(height: 20),
                          _buildStatsRow(user),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        indicatorColor: AppTheme.secondary,
                        indicatorWeight: 3,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white54,
                        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        tabs: const [
                          Tab(text: 'Overview'),
                          Tab(text: 'GitHub Repos'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _buildOverviewTab(user, controller),
                  _buildReposTab(user),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 48), // Spacer to center title
        const Text(
          'Developer Profile',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.settings_outlined, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildHeader(UserModel user) {
    final displayName = (user.name.isNotEmpty) ? user.name : (user.githubUrl?.split('/').last ?? 'Developer');
    final handle = '@${user.githubUrl?.split('/').last ?? displayName.replaceAll(' ', '')}';

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.8), width: 2.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: CircleAvatar(
                  backgroundColor: AppTheme.cardBg,
                  backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty ? NetworkImage(user.photoUrl!) : null,
                  child: user.photoUrl == null || user.photoUrl!.isEmpty ? const Icon(Icons.person, size: 45, color: Colors.white) : null,
                ),
              ),
            ),
            // Online Indicator Status Dot
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0D121F), width: 4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          displayName,
          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ),
        const SizedBox(height: 2),
        Text(
          handle,
          style: const TextStyle(color: AppTheme.secondary, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on_outlined, color: Colors.white54, size: 14),
            const SizedBox(width: 4),
            Text(
              user.location ?? 'Remote, Worldwide',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF102830), // Dark teal/blue glow background
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(color: AppTheme.secondary.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 1),
            ],
          ),
          child: const Text(
            'AI Verified Match ✨',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(UserModel user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatBox('RATING', user.ratingCount > 0 ? '${user.avgRating.toStringAsFixed(1)}/5' : 'N/A'),
        _buildStatBox('REPOS', user.publicRepos?.toString() ?? '0'),
        _buildStatBox('PROJECTS', user.topRepositories?.length.toString() ?? '0'),
      ],
    );
  }

  Widget _buildStatBox(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D27), // Card color
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Text(title, style: const TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
      ),
    );
  }

  Widget _buildOverviewTab(UserModel user, AuthController controller) {
    final skills = (user.topAiSkills != null && user.topAiSkills!.isNotEmpty) 
        ? user.topAiSkills! 
        : user.skills;
        
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: Colors.amber, size: 22),
              const SizedBox(width: 8),
              const Text('AI Summary', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.aiBio ?? 'No AI summary generated. Tap Refresh below.',
            style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 32),
          const Text('Top Technologies', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: skills.map((skill) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D27),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(skill, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
            )).toList(),
          ),
          const SizedBox(height: 48),
          
          ElevatedButton.icon(
            onPressed: () => controller.refreshDeveloperPortfolio(),
            icon: const Icon(Icons.sync_rounded),
            label: const Text('Refresh AI Portfolio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => controller.signOut(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign Out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error),
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReposTab(UserModel user) {
    final repos = user.topRepositories ?? [];
    if (repos.isEmpty) {
      return const Center(
        child: Text("No GitHub repositories found.", style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: repos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final repo = repos[index];
        final name = repo['name'] ?? 'Unknown';
        final desc = repo['description'] ?? 'No description available for this repository.';
        final lang = repo['language'] ?? 'Code';
        final stars = repo['stargazers_count'] ?? 0;
        final forks = repo['forks_count'] ?? 0;
        final url = repo['html_url'];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1D27),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Public', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                desc,
                style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5),
                maxLines: 3, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // Language dot
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: _getLanguageColor(lang),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(lang, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(width: 16),
                  
                  // Stars
                  const Icon(Icons.star_outline_rounded, color: Colors.white54, size: 16),
                  const SizedBox(width: 4),
                  Text(stars.toString(), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(width: 16),
                  
                  // Forks
                  const Icon(Icons.fork_right_rounded, color: Colors.white54, size: 16),
                  const SizedBox(width: 4),
                  Text(forks.toString(), style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  
                  const Spacer(),
                  
                  // View Code Button
                  if (url != null)
                    InkWell(
                      onTap: () => _launchUrl(url),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('VIEW CODE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                            SizedBox(width: 4),
                            Icon(Icons.open_in_new_rounded, color: Colors.white, size: 12),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getLanguageColor(String language) {
    switch (language.toLowerCase()) {
      case 'dart': return Colors.cyan;
      case 'python': return Colors.yellow;
      case 'typescript': return Colors.blueAccent;
      case 'javascript': return Colors.yellowAccent;
      case 'html': return Colors.orange;
      case 'css': return Colors.blue;
      default: return Colors.white54;
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 16;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 16;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF0D121F), // Match background to cover scrolling items
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
