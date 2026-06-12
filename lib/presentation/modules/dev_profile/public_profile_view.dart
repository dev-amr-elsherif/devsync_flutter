import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/models/project_model.dart';
import '../../../../data/models/invitation_model.dart';
import '../../../../data/providers/firebase_provider.dart';
import '../../widgets/custom_button.dart';
import '../auth/auth_controller.dart';

class PublicProfileView extends StatefulWidget {
  const PublicProfileView({super.key});

  @override
  State<PublicProfileView> createState() => _PublicProfileViewState();
}

class _PublicProfileViewState extends State<PublicProfileView> {
  final FirebaseProvider _firebaseProvider = FirebaseProvider();
  final UserModel developer = Get.arguments['developer'];
  final ProjectModel? projectContext = Get.arguments['project'];
  
  bool isSending = false;

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      Get.snackbar('Error', 'Could not open the link');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D121F), // Very dark slate to match screenshot
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: NestedScrollView(
            headerSliverBuilder: (context, _) {
              return [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      children: [
                        _buildTopAppBar(),
                        const SizedBox(height: 30),
                        _buildHeader(),
                        const SizedBox(height: 30),
                        _buildStatsRow(),
                        const SizedBox(height: 30),
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
                _buildOverviewTab(),
                _buildReposTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        const Text(
          'Developer Profile',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 48), // Spacer
      ],
    );
  }

  Widget _buildHeader() {
    final displayName = (developer.name.isNotEmpty) ? developer.name : (developer.githubUrl?.split('/').last ?? 'Developer');
    final handle = '@${developer.githubUrl?.split('/').last ?? displayName.replaceAll(' ', '')}';

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.8), width: 3),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3.0),
                child: CircleAvatar(
                  backgroundColor: AppTheme.cardBg,
                  backgroundImage: developer.photoUrl != null && developer.photoUrl!.isNotEmpty ? NetworkImage(developer.photoUrl!) : null,
                  child: developer.photoUrl == null || developer.photoUrl!.isEmpty ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                ),
              ),
            ),
            // Online Indicator Status Dot
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0D121F), width: 4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          displayName,
          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          handle,
          style: const TextStyle(color: AppTheme.secondary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on_outlined, color: Colors.white54, size: 16),
            const SizedBox(width: 4),
            Text(
              developer.location ?? 'Remote, Worldwide',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatBox('RATING', developer.ratingCount > 0 ? '${developer.avgRating.toStringAsFixed(1)}/5' : 'N/A'),
        _buildStatBox('REPOS', developer.publicRepos?.toString() ?? '0'),
        _buildStatBox('PROJECTS', developer.topRepositories?.length.toString() ?? '0'),
      ],
    );
  }

  Widget _buildStatBox(String title, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D27), // Card color
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final skills = (developer.topAiSkills != null && developer.topAiSkills!.isNotEmpty) 
        ? developer.topAiSkills! 
        : developer.skills;
        
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
            developer.aiBio ?? 'No AI summary available.',
            style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
          ),
          const SizedBox(height: 32),
          const Text('Top Technologies', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: skills.map((skill) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1D27),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(skill, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
            )).toList(),
          ),
          
          const SizedBox(height: 48),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (projectContext != null)
          DevSyncButton(
            id: 'btn_send_invite',
            onPressed: isSending ? null : _handleSendInvitation,
            isLoading: isSending,
            gradient: AppTheme.primaryGradient,
            child: const Text('Send Project Invitation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () {
             Get.snackbar('Coming Soon', 'Interactive Chat is under development.');
          },
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          label: const Text('Send Direct Message'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            side: const BorderSide(color: Colors.white24),
          ),
        ),
      ],
    );
  }

  Future<void> _handleSendInvitation() async {
    if (projectContext == null) return;
    
    final currentUser = Get.find<AuthController>().currentUser.value;
    if (currentUser == null) return;

    setState(() => isSending = true);

    try {
      final invitation = InvitationModel(
        id: '', 
        senderId: currentUser.uid,
        senderName: currentUser.name,
        senderPhotoUrl: currentUser.photoUrl,
        receiverId: developer.uid,
        receiverName: developer.name,
        receiverPhotoUrl: developer.photoUrl,
        projectId: projectContext!.id,
        projectTitle: projectContext!.title,
        timestamp: DateTime.now(),
      );

      await _firebaseProvider.sendInvitation(invitation);
      
      Get.back();
      Get.snackbar(
        'Success', 
        'Invitation sent to ${developer.name}!',
        backgroundColor: Colors.green.withValues(alpha: 0.2),
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to send invitation: $e');
    } finally {
      setState(() => isSending = false);
    }
  }

  Widget _buildReposTab() {
    final repos = developer.topRepositories ?? [];
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
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
