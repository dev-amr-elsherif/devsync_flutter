import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/project_model.dart';
import '../models/invitation_model.dart';

class FirebaseProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveUser(UserModel user) async {
    final String collection = user.role == 'owner' ? 'owners' : 'developers';
    await _firestore.collection(collection).doc(user.uid).set(user.toMap());
    try {
      await _firestore.collection('users').doc(user.uid).delete();
      final String otherCollection = user.role == 'owner'
          ? 'developers'
          : 'owners';
      await _firestore.collection(otherCollection).doc(user.uid).delete();
    } catch (e) {
      // ignore
    }
  }

  Future<UserModel?> getUser(String uid) async {
    var devDoc = await _firestore.collection('developers').doc(uid).get();
    if (devDoc.exists) return UserModel.fromMap(devDoc.data()!);
    var ownerDoc = await _firestore.collection('owners').doc(uid).get();
    if (ownerDoc.exists) return UserModel.fromMap(ownerDoc.data()!);
    var legacyDoc = await _firestore.collection('users').doc(uid).get();
    if (legacyDoc.exists) return UserModel.fromMap(legacyDoc.data()!);
    return null;
  }

  Future<List<ProjectModel>> getProjects() async {
    var snapshot = await _firestore.collection('projects').get();
    return snapshot.docs.map((doc) {
      var data = doc.data();
      data['id'] = doc.id;
      return ProjectModel.fromMap(data);
    }).toList();
  }

  Stream<ProjectModel?> streamProject(String projectId) {
    return _firestore.collection('projects').doc(projectId).snapshots().map((
      doc,
    ) {
      if (doc.exists) {
        var data = doc.data()!;
        data['id'] = doc.id;
        return ProjectModel.fromMap(data);
      }
      return null;
    });
  }

  Future<ProjectModel?> getProject(String projectId) async {
    var doc = await _firestore.collection('projects').doc(projectId).get();
    if (doc.exists) {
      var data = doc.data()!;
      data['id'] = doc.id;
      if (!data.containsKey('status')) {
        await _firestore.collection('projects').doc(doc.id).update({
          'status': 'active',
        });
        data['status'] = 'active';
      }
      if (data['status'] == 'active') {
        final invites = await _firestore
            .collection('invitations')
            .where('projectId', isEqualTo: projectId)
            .where('status', isEqualTo: 'accepted')
            .get();
        if (invites.docs.isNotEmpty &&
            invites.docs.every(
              (d) => d.data()['devWorkStatus'] == 'finished',
            )) {
          await _firestore.collection('projects').doc(projectId).update({
            'status': 'ready_for_review',
          });
          data['status'] = 'ready_for_review';
        }
      }
      return ProjectModel.fromMap(data);
    }
    return null;
  }

  Future<ProjectModel> createProject(ProjectModel project) async {
    var doc = await _firestore.collection('projects').add(project.toMap());
    var data = project.toMap();
    data['id'] = doc.id;
    return ProjectModel.fromMap(data);
  }

  Future<void> updateProjectState(
    String projectId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('projects').doc(projectId).update(data);
  }

  Future<List<UserModel>> getDevelopers() async {
    var snapshot = await _firestore.collection('developers').get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  // ─── Invitations ──────────────────────────────────────────────

  Future<void> sendInvitation(InvitationModel invitation) async {
    await _firestore.collection('invitations').add(invitation.toMap());
  }

  Stream<List<InvitationModel>> streamInvitations(String userId) {
    return _firestore
        .collection('invitations')
        .where('receiverId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final List<InvitationModel> all = snapshot.docs
              .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
              .toList();

          // ✅ FIX: use .toFirestoreString() for contains check
          final filtered = all
              .where(
                (i) => [
                  'pending',
                  'cancellation_proposed',
                  'accepted',
                ].contains(i.status.toFirestoreString()),
              )
              .toList();

          filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return filtered;
        });
  }

  Future<void> updateInvitationStatus(
    String invitationId,
    String newStatus,
  ) async {
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': newStatus,
    });
  }

  Stream<List<InvitationModel>> streamSentInvitations(String ownerId) {
    return _firestore
        .collection('invitations')
        .where('senderId', isEqualTo: ownerId)
        .snapshots()
        .map((snapshot) {
          final List<InvitationModel> all = snapshot.docs
              .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
              .toList();
          all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return all;
        });
  }

  Future<List<InvitationModel>> getInvitationsByProject(
    String projectId,
  ) async {
    var snapshot = await _firestore
        .collection('invitations')
        .where('projectId', isEqualTo: projectId)
        .get();
    final List<InvitationModel> all = snapshot.docs
        .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
        .toList();
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all;
  }

  Future<List<InvitationModel>> getSentJoinRequests(String developerId) async {
    var snapshot = await _firestore
        .collection('invitations')
        .where('senderId', isEqualTo: developerId)
        .where('status', isEqualTo: 'join_request')
        .get();
    return snapshot.docs
        .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<InvitationModel>> streamMyJoinRequests(String developerId) {
    return _firestore
        .collection('invitations')
        .where('senderId', isEqualTo: developerId)
        .snapshots()
        .map((snap) {
          final List<InvitationModel> all = snap.docs
              .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
              .where((inv) => inv.senderId == developerId)
              .toList();

          // ✅ FIX: use .toFirestoreString()
          final filtered = all
              .where(
                (i) => [
                  'join_request',
                  'accepted',
                  'declined',
                ].contains(i.status.toFirestoreString()),
              )
              .toList();

          filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return filtered;
        });
  }

  Future<List<InvitationModel>> getAcceptedInvitationsForDev(
    String developerId,
  ) async {
    var snapshot = await _firestore
        .collection('invitations')
        .where('receiverId', isEqualTo: developerId)
        .where('status', isEqualTo: 'accepted')
        .get();
    return snapshot.docs
        .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<int> streamPendingJoinRequestsCount(String ownerId) {
    return _firestore
        .collection('invitations')
        .where('receiverId', isEqualTo: ownerId)
        .where('status', isEqualTo: 'join_request')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Stream<List<InvitationModel>> streamJoinRequestsForOwner(String ownerId) {
    return _firestore
        .collection('invitations')
        .where('receiverId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) {
          final List<InvitationModel> all = snap.docs
              .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
              .toList();

          // ✅ FIX: use .toFirestoreString()
          final filtered = all
              .where(
                (i) => [
                  'join_request',
                  'accepted',
                  'declined',
                ].contains(i.status.toFirestoreString()),
              )
              .toList();

          filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return filtered;
        });
  }

  Future<void> respondToJoinRequest(
    String invitationId,
    bool isAccepted, {
    String? declineReason,
  }) async {
    final Map<String, dynamic> update = {
      'status': isAccepted ? 'accepted' : 'declined',
    };
    if (!isAccepted && declineReason != null && declineReason.isNotEmpty) {
      update['declineReason'] = declineReason;
    }
    await _firestore.collection('invitations').doc(invitationId).update(update);
  }

  Future<void> hardDeleteProject(String projectId) async {
    var invites = await _firestore
        .collection('invitations')
        .where('projectId', isEqualTo: projectId)
        .get();
    for (var doc in invites.docs) {
      await doc.reference.delete();
    }
    await _firestore.collection('projects').doc(projectId).delete();
  }

  Future<void> proposeCancellation(String invitationId, String apology) async {
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': 'cancellation_proposed',
      'apologyNote': apology,
    });
  }

  Future<void> respondToCancellation(String invitationId, bool approve) async {
    if (approve) {
      await _firestore.collection('invitations').doc(invitationId).update({
        'status': 'cancelled',
      });
    } else {
      await _firestore.collection('invitations').doc(invitationId).update({
        'status': 'accepted',
        'apologyNote': FieldValue.delete(),
      });
    }
  }

  Future<void> updateDevWorkStatus(
    String inviteId,
    String projectId,
    String newStatus,
  ) async {
    return _firestore.runTransaction((transaction) async {
      final inviteRef = _firestore.collection('invitations').doc(inviteId);
      transaction.update(inviteRef, {'devWorkStatus': newStatus});

      if (newStatus == 'finished') {
        final query = _firestore
            .collection('invitations')
            .where('projectId', isEqualTo: projectId)
            .where('status', isEqualTo: 'accepted');

        final snapshot = await query.get();

        bool allFinished = true;
        for (var doc in snapshot.docs) {
          if (doc.id == inviteId) continue;
          if (doc.data()['devWorkStatus'] != 'finished') {
            allFinished = false;
            break;
          }
        }

        if (allFinished && snapshot.docs.isNotEmpty) {
          final projectRef = _firestore.collection('projects').doc(projectId);
          transaction.update(projectRef, {'status': 'ready_for_review'});
        }
      }
    });
  }

  Future<void> submitReview(
    Map<String, dynamic> reviewData,
    String developerId,
  ) async {
    final double newRating = (reviewData['rating'] as num).toDouble();

    return _firestore.runTransaction((transaction) async {
      final reviewRef = _firestore.collection('reviews').doc();
      transaction.set(reviewRef, {
        ...reviewData,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final projectRef = _firestore
          .collection('projects')
          .doc(reviewData['projectId']);
      transaction.update(projectRef, {'status': 'completed'});

      final devRef = _firestore.collection('developers').doc(developerId);
      final devDoc = await transaction.get(devRef);

      if (devDoc.exists) {
        final data = devDoc.data()!;
        final int oldCount = data['ratingCount'] ?? 0;
        final double oldAvg = (data['avgRating'] ?? 0.0).toDouble();
        final int newCount = oldCount + 1;
        final double newAvg = ((oldAvg * oldCount) + newRating) / newCount;
        transaction.update(devRef, {
          'ratingCount': newCount,
          'avgRating': newAvg,
        });
      }
    });
  }
}
