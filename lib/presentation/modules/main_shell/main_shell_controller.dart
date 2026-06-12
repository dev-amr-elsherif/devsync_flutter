import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../auth/auth_controller.dart';
import '../../../data/providers/firebase_provider.dart';
import '../../../data/models/invitation_model.dart';
import 'dart:async';
import '../dev_dashboard/developer_dashboard_view.dart';
import '../dev_projects/projects_view.dart';
import '../dev_matches/matches_view.dart';
import '../dev_profile/profile_view.dart';
import '../owner_dashboard/owner_dashboard_view.dart';
import '../owner_create/create_project_view.dart';
import '../owner_projects/my_projects_view.dart';
import '../owner_profile/owner_profile_view.dart';

class MainShellController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final FirebaseProvider _firebaseProvider = FirebaseProvider();

  StreamSubscription? _invitationSub;
  StreamSubscription? _joinRequestStatusSub;
  StreamSubscription? _ownerBadgeSub;

  var currentIndex = 0.obs;

  // Badge counts
  final RxInt devPendingInvites = 0.obs;   // للمطور: دعوات جديدة من المدير
  final RxInt ownerPendingRequests = 0.obs; // للمدير: طلبات انضمام من مطورين

  // IDs of invitations already notified to avoid spam
  final Set<String> _notifiedInviteIds = {};
  // IDs of join requests already notified (status changed)
  final Set<String> _notifiedJoinStatusIds = {};

  @override
  void onInit() {
    super.onInit();
    _setupListeners();
  }

  @override
  void onClose() {
    _invitationSub?.cancel();
    _joinRequestStatusSub?.cancel();
    _ownerBadgeSub?.cancel();
    super.onClose();
  }

  void _setupListeners() {
    final user = _authController.currentUser.value;
    if (user == null) return;

    if (user.role == 'developer') {
      _listenToDevInvitations(user.uid);
      _listenToJoinRequestStatuses(user.uid);
    } else if (user.role == 'owner') {
      _listenToOwnerPendingRequests(user.uid);
    }
  }

  /// مطور: يسمع للدعوات الجديدة من المدير
  void _listenToDevInvitations(String uid) {
    _invitationSub = _firebaseProvider.streamInvitations(uid).listen((invitations) {
      devPendingInvites.value = invitations.where((i) => i.status == 'pending').length;

      // إشعار بالدعوات الجديدة فقط (مرة واحدة لكل دعوة)
      for (final invite in invitations) {
        if (invite.status == 'pending' && !_notifiedInviteIds.contains(invite.id)) {
          _notifiedInviteIds.add(invite.id);
          _showInvitationNotification(invite);
        }
      }
    });
  }

  /// مطور: يسمع لتغيير حالة طلبات الانضمام (join_request -> accepted/declined)
  void _listenToJoinRequestStatuses(String uid) {
    _joinRequestStatusSub = _firebaseProvider.streamMyJoinRequests(uid).listen((requests) {
      for (final req in requests) {
        final key = '${req.id}_${req.status}';
        if (!_notifiedJoinStatusIds.contains(key)) {
          if (req.status == 'accepted') {
            _notifiedJoinStatusIds.add(key);
            _showJoinRequestNotification(req, accepted: true);
          } else if (req.status == 'declined') {
            _notifiedJoinStatusIds.add(key);
            _showJoinRequestNotification(req, accepted: false);
          }
        }
      }
    });
  }

  /// مدير: يسمع لعدد طلبات الانضمام المعلقة (للـ Badge)
  void _listenToOwnerPendingRequests(String uid) {
    _ownerBadgeSub = _firebaseProvider.streamPendingJoinRequestsCount(uid).listen((count) {
      ownerPendingRequests.value = count;
    });
  }

  void _showInvitationNotification(InvitationModel invitation) {
    Get.snackbar(
      '📩 New Project Invitation!',
      '${invitation.senderName} wants you for "${invitation.projectTitle}"',
      snackPosition: SnackPosition.TOP,
      backgroundColor: const Color(0xFF1A1F3A).withValues(alpha: 0.95),
      colorText: Colors.white,
      duration: const Duration(seconds: 6),
      borderRadius: 16,
      margin: const EdgeInsets.all(12),
      icon: const Icon(Icons.mail_rounded, color: Color(0xFF6C63FF)),
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          changePage(1); // Go to Projects tab
        },
        child: const Text('VIEW', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showJoinRequestNotification(InvitationModel req, {required bool accepted}) {
    Get.snackbar(
      accepted ? '✅ Request Accepted!' : '❌ Request Declined',
      accepted
          ? 'Your request to join "${req.projectTitle}" was accepted!'
          : 'Your request to join "${req.projectTitle}" was not accepted this time.',
      snackPosition: SnackPosition.TOP,
      backgroundColor: accepted
          ? const Color(0xFF00C896).withValues(alpha: 0.15)
          : const Color(0xFFB00020).withValues(alpha: 0.15),
      colorText: accepted ? const Color(0xFF00C896) : const Color(0xFFFF4444),
      duration: const Duration(seconds: 5),
      borderRadius: 16,
      margin: const EdgeInsets.all(12),
      mainButton: TextButton(
        onPressed: () {
          Get.back();
          changePage(1); // Go to Projects tab to see status
        },
        child: Text('VIEW', style: TextStyle(
          color: accepted ? const Color(0xFF00C896) : const Color(0xFFFF4444),
          fontWeight: FontWeight.bold,
        )),
      ),
    );
  }

  List<Widget> get pages {
    final role = _authController.currentUser.value?.role;
    if (role == 'developer') {
      return [
        const DeveloperDashboardView(),
        const ProjectsView(),
        const MatchesView(),
        const ProfileView(),
      ];
    } else {
      return [
        const OwnerDashboardView(),
        const CreateProjectView(),
        const MyProjectsView(),
        const OwnerProfileView(),
      ];
    }
  }

  List<BottomNavigationBarItem> get navItems {
    final role = _authController.currentUser.value?.role;
    if (role == 'developer') {
      return [
        const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Dashboard'),
        BottomNavigationBarItem(
          icon: _buildBadgedIcon(Icons.work_rounded, devPendingInvites),
          label: 'Projects',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_rounded), label: 'Matches'),
        const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
      ];
    } else {
      return [
        const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Dashboard'),
        const BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline_rounded), label: 'Create'),
        BottomNavigationBarItem(
          icon: _buildBadgedIcon(Icons.list_alt_rounded, ownerPendingRequests),
          label: 'Recruitment',
        ),
        const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
      ];
    }
  }

  Widget _buildBadgedIcon(IconData icon, RxInt count) {
    return Obx(() {
      final c = count.value;
      if (c == 0) return Icon(icon);
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon),
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xFFFF4444),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                c > 9 ? '9+' : '$c',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    });
  }

  void changePage(int index) {
    currentIndex.value = index;
  }
}
