import 'package:get/get.dart';
import 'dart:async';
import '../../../../data/models/project_model.dart';
import '../../../../data/models/invitation_model.dart';
import '../../../../data/providers/firebase_provider.dart';
import '../auth/auth_controller.dart';

class ProjectDetailsController extends GetxController {
  final FirebaseProvider _firebaseProvider = Get.find<FirebaseProvider>();
  final AuthController _authController = Get.find<AuthController>();

  final Rxn<ProjectModel> project = Rxn<ProjectModel>();
  final Rxn<InvitationModel> myInvitation = Rxn<InvitationModel>();
  final RxList<InvitationModel> allProjectMembers = <InvitationModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isUpdating = false.obs;
  final RxMap<String, String> teamNames = <String, String>{}.obs;
  final RxMap<String, String?> teamPhotos = <String, String?>{}.obs;

  StreamSubscription? _projectSub;

  @override
  void onInit() {
    super.onInit();
    final ProjectModel initialProject = Get.arguments;
    project.value = initialProject;
    _setupStream(initialProject.id);
    _loadSyncData();
  }

  void _setupStream(String projectId) {
    _projectSub?.cancel();
    _projectSub = _firebaseProvider.streamProject(projectId).listen((data) {
      if (data != null) project.value = data;
    });
  }

  @override
  void onClose() {
    _projectSub?.cancel();
    super.onClose();
  }

  Future<void> _loadSyncData() async {
    final user = _authController.currentUser.value;
    final currentProject = project.value;
    if (user == null || currentProject == null) {
      isLoading.value = false;
      return;
    }

    try {
      isLoading.value = true;

      final invites = await _firebaseProvider.getInvitationsByProject(
        currentProject.id,
      );

      // ✅ FIX: compare with InvitationStatus.accepted enum
      final accepted = invites
          .where((i) => i.status == InvitationStatus.accepted)
          .toList();
      allProjectMembers.assignAll(accepted);

      for (var invite in accepted) {
        final uid = invite.receiverId;
        if (!teamNames.containsKey(uid) || !teamPhotos.containsKey(uid)) {
          final userProfile = await _firebaseProvider.getUser(uid);
          if (userProfile != null) {
            teamNames[uid] = userProfile.name;
            teamPhotos[uid] = userProfile.photoUrl;
          }
        }
      }

      // ✅ FIX: compare with InvitationStatus.accepted enum
      final mine = invites.firstWhereOrNull(
        (i) =>
            (i.receiverId == user.uid || i.senderId == user.uid) &&
            i.status == InvitationStatus.accepted,
      );
      myInvitation.value = mine;
    } catch (e) {
      // silent error
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateMyStatus(String newStatus) async {
    final currentProject = project.value;
    if (myInvitation.value == null || currentProject == null) return;

    try {
      isUpdating.value = true;
      await _firebaseProvider.updateDevWorkStatus(
        myInvitation.value!.id,
        currentProject.id,
        newStatus,
      );

      // ✅ FIX: convert String → DevWorkStatus enum
      myInvitation.value = myInvitation.value!.copyWith(
        devWorkStatus: DevWorkStatus.fromString(newStatus),
      );

      final updatedProject = await _firebaseProvider.getProject(
        currentProject.id,
      );
      if (updatedProject != null) project.value = updatedProject;

      Get.snackbar(
        'Success',
        'Status updated: ${newStatus.replaceAll('_', ' ').toUpperCase()}',
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to update status');
    } finally {
      isUpdating.value = false;
    }
  }
}
