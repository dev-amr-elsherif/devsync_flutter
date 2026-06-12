import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/project_model.dart';
import '../models/invitation_model.dart';

class FirebaseProvider {
  // هذا الكلاس هو "الدينامو" اللي بيكلم الفايربيز مباشرة بدون لف ودوران
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // حفظ بيانات المستخدم في المجموعة المخصصة بناءً على الدور (Role)
  Future<void> saveUser(UserModel user) async {
    final String collection = user.role == 'owner' ? 'owners' : 'developers';
    
    // 1. حفظ البيانات في المجموعة الجديدة
    await _firestore.collection(collection).doc(user.uid).set(user.toMap());
    
    // 2. تنظيف المجموعة القديمة (Migration Cleanup) إذا كانت موجودة
    try {
      await _firestore.collection('users').doc(user.uid).delete();
      // أيضاً نحذف من المجموعة "الأخرى" لضمان عدم وجود تكرار إذا غير المستخدم دوره مستقبلاً
      final String otherCollection = user.role == 'owner' ? 'developers' : 'owners';
      await _firestore.collection(otherCollection).doc(user.uid).delete();
    } catch (e) {
      // نتجاهل الأخطاء هنا في حالة عدم وجود الوثيقة أصلاً
    }
  }

  // جلب بيانات مستخدم معين بالبحث في كل المجموعات المتاحة
  Future<UserModel?> getUser(String uid) async {
    // 1. جرب البحث في المطورين
    var devDoc = await _firestore.collection('developers').doc(uid).get();
    if (devDoc.exists) {
      return UserModel.fromMap(devDoc.data()!);
    }
    
    // 2. جرب البحث في الملاك
    var ownerDoc = await _firestore.collection('owners').doc(uid).get();
    if (ownerDoc.exists) {
      return UserModel.fromMap(ownerDoc.data()!);
    }
    
    // 3. Fallback: ابحث في المجموعة القديمة (Legacy)
    var legacyDoc = await _firestore.collection('users').doc(uid).get();
    if (legacyDoc.exists) {
      return UserModel.fromMap(legacyDoc.data()!);
    }
    
    return null;
  }

  // جلب كل المشاريع المتاحة
  Future<List<ProjectModel>> getProjects() async {
    var snapshot = await _firestore.collection('projects').get();
    return snapshot.docs.map((doc) {
      var data = doc.data();
      data['id'] = doc.id;
      return ProjectModel.fromMap(data);
    }).toList();
  }

  // الاستماع لمشروع معين في الوقت الفعلي
  Stream<ProjectModel?> streamProject(String projectId) {
    return _firestore.collection('projects').doc(projectId).snapshots().map((doc) {
      if (doc.exists) {
        var data = doc.data()!;
        data['id'] = doc.id;
        return ProjectModel.fromMap(data);
      }
      return null;
    });
  }

  // جلب مشروع معين بواسطة المعرف (مع معالجة توافقية البيانات)
  Future<ProjectModel?> getProject(String projectId) async {
    var doc = await _firestore.collection('projects').doc(projectId).get();
    if (doc.exists) {
      var data = doc.data()!;
      data['id'] = doc.id;

      // Lazy Migration: التأكد من وجود الحالات الجديدة وإصلاح حالة الإكمال للمشاريع القديمة
      if (!data.containsKey('status')) {
        await _firestore.collection('projects').doc(doc.id).update({'status': 'active'});
        data['status'] = 'active';
      }

      // إذا كان المشروع نشطاً ولكن كل المطورين انتهوا (حالة قديمة)، نقوم بتحديثه لـ Ready For Review
      if (data['status'] == 'active') {
        final invites = await _firestore.collection('invitations')
            .where('projectId', isEqualTo: projectId)
            .where('status', isEqualTo: 'accepted')
            .get();
        if (invites.docs.isNotEmpty && invites.docs.every((d) => d.data()['devWorkStatus'] == 'finished')) {
          await _firestore.collection('projects').doc(projectId).update({'status': 'ready_for_review'});
          data['status'] = 'ready_for_review';
        }
      }

      return ProjectModel.fromMap(data);
    }
    return null;
  }

  // إنشاء مشروع جديد
  Future<ProjectModel> createProject(ProjectModel project) async {
    var doc = await _firestore.collection('projects').add(project.toMap());
    var data = project.toMap();
    data['id'] = doc.id;
    return ProjectModel.fromMap(data);
  }

  // تحديث حالة المشروع أو الملاحظات
  Future<void> updateProjectState(String projectId, Map<String, dynamic> data) async {
    await _firestore.collection('projects').doc(projectId).update(data);
  }

  // جلب كل المطورين من مجموعتهم المخصصة
  Future<List<UserModel>> getDevelopers() async {
    var snapshot = await _firestore.collection('developers').get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  // ─── Invitations ───

  // إرسال دعوة لمطور
  Future<void> sendInvitation(InvitationModel invitation) async {
    await _firestore.collection('invitations').add(invitation.toMap());
  }

  // الاستماع للدعوات الجديدة (للمطور)
  Stream<List<InvitationModel>> streamInvitations(String userId) {
    return _firestore
        .collection('invitations')
        .where('receiverId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final List<InvitationModel> all = snapshot.docs
          .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
          .toList();
      
      // Filter locally to avoid requiring composite indexes
      final filtered = all.where((i) => 
        ['pending', 'cancellation_proposed', 'accepted'].contains(i.status)
      ).toList();
      
      // Sort locally
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return filtered;
    });
  }

  // تحديث حالة الدعوة (قبول/رفض)
  Future<void> updateInvitationStatus(String invitationId, String newStatus) async {
    await _firestore
        .collection('invitations')
        .doc(invitationId)
        .update({'status': newStatus});
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

      // Sort locally to avoid requiring composite indexes
      all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return all;
    });
  }

  // جلب كل الدعوات الخاصة بمشروع معين
  Future<List<InvitationModel>> getInvitationsByProject(String projectId) async {
    var snapshot = await _firestore
        .collection('invitations')
        .where('projectId', isEqualTo: projectId)
        .get();
    
    final List<InvitationModel> all = snapshot.docs
        .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
        .toList();

    // Sort locally to avoid requiring composite indexes
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all;
  }

  // جلب طلبات الانضمام التي أرسلها المطور (join_request status)
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

  // جلب كل طلبات الانضمام للمطور (بغض النظر عن الحالة) لعرضها في Projects tab
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

      // Filter locally to avoid requiring composite indexes
      final filtered = all.where((i) => 
        ['join_request', 'accepted', 'declined'].contains(i.status)
      ).toList();

      // Sort locally
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return filtered;
    });
  }

  // جلب المشاريع المقبول فيها المطور (لفلترتها من Matches)
  Future<List<InvitationModel>> getAcceptedInvitationsForDev(String developerId) async {
    var snapshot = await _firestore
        .collection('invitations')
        .where('receiverId', isEqualTo: developerId)
        .where('status', isEqualTo: 'accepted')
        .get();
    return snapshot.docs
        .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Stream لعدد طلبات الانضمام المعلقة للمدير (Badge)
  Stream<int> streamPendingJoinRequestsCount(String ownerId) {
    return _firestore
        .collection('invitations')
        .where('receiverId', isEqualTo: ownerId)
        .where('status', isEqualTo: 'join_request')
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // جلب كل طلبات الانضمام المرسلة لهذا المالك (ليتمكن من تتبعها في شاشة واحدة)
  Stream<List<InvitationModel>> streamJoinRequestsForOwner(String ownerId) {
    return _firestore
        .collection('invitations')
        .where('receiverId', isEqualTo: ownerId)
        .snapshots()
        .map((snap) {
      final List<InvitationModel> all = snap.docs
          .map((doc) => InvitationModel.fromMap(doc.data(), doc.id))
          .toList();

      // Filter locally to avoid requiring composite indexes
      final filtered = all.where((i) => 
        ['join_request', 'accepted', 'declined'].contains(i.status)
      ).toList();

      // Sort locally
      filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return filtered;
    });
  }

  // الرد على طلب انضمام (من المدير: قبول أو رفض)
  Future<void> respondToJoinRequest(String invitationId, bool isAccepted, {String? declineReason}) async {
    final Map<String, dynamic> update = {'status': isAccepted ? 'accepted' : 'declined'};
    if (!isAccepted && declineReason != null && declineReason.isNotEmpty) {
      update['declineReason'] = declineReason;
    }
    await _firestore.collection('invitations').doc(invitationId).update(update);
  }

  // حذف المشروع وكل الدعوات المرتبطة به نهائياً
  Future<void> hardDeleteProject(String projectId) async {
    // 1. حذف كل الدعوات
    var invites = await _firestore
        .collection('invitations')
        .where('projectId', isEqualTo: projectId)
        .get();
    for (var doc in invites.docs) {
      await doc.reference.delete();
    }
    // 2. حذف المشروع نفسه
    await _firestore.collection('projects').doc(projectId).delete();
  }

  // إرسال طلب إلغاء (اعتذار)
  Future<void> proposeCancellation(String invitationId, String apology) async {
    await _firestore.collection('invitations').doc(invitationId).update({
      'status': 'cancellation_proposed',
      'apologyNote': apology,
    });
  }

  // الرد على طلب الإلغاء (من المطور)
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

  // ─── Project Lifecycle & Ratings ───

  // تحديث حالة العمل للمطور الفردي (Atomic Consensus Logic)
  Future<void> updateDevWorkStatus(String inviteId, String projectId, String newStatus) async {
    return _firestore.runTransaction((transaction) async {
      // 1. تحديث حالة المطور نفسه
      final inviteRef = _firestore.collection('invitations').doc(inviteId);
      transaction.update(inviteRef, {'devWorkStatus': newStatus});

      // 2. إذا كانت الحالة "Finished"، نتحقق من بقية الفريق بشكل ذري
      if (newStatus == 'finished') {
        final query = _firestore
            .collection('invitations')
            .where('projectId', isEqualTo: projectId)
            .where('status', isEqualTo: 'accepted');
        
        final snapshot = await query.get();
        
        // ملاحظة: الـ Every هنا ستعمل على البيانات الحالية + التغيير الذي أجريناه للتو في الـ Transaction
        bool allFinished = true;
        for (var doc in snapshot.docs) {
          // إذا كان هذا هو المجلد الذي نقوم بتحديثه الآن، نعتبره finished
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

  // تقديم التقييم وإغلاق المشروع نهائياً (Atomic Update)
  Future<void> submitReview(Map<String, dynamic> reviewData, String developerId) async {
    final double newRating = (reviewData['rating'] as num).toDouble();

    return _firestore.runTransaction((transaction) async {
      // 1. حفظ التقييم في مجموعة reviews
      final reviewRef = _firestore.collection('reviews').doc();
      transaction.set(reviewRef, {
        ...reviewData,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. تحديث حالة المشروع إلى "مكتمل"
      final projectRef = _firestore.collection('projects').doc(reviewData['projectId']);
      transaction.update(projectRef, {'status': 'completed'});

      // 3. تحديث إحصائيات المطور (Rating Aggregation)
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
