import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus { pending, accepted, declined }

class InvitationModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String receiverId;
  final String? receiverName;
  final String? receiverPhotoUrl;
  final String projectId;
  final String projectTitle;
  final String status; // pending, accepted, declined, join_request, cancellation_proposed, cancelled
  final String devWorkStatus; // in_progress, finished
  final String? apologyNote;
  final String? declineReason; // سبب الرفض (اختياري)
  final DateTime timestamp;

  InvitationModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.receiverId,
    this.receiverName,
    this.receiverPhotoUrl,
    required this.projectId,
    required this.projectTitle,
    this.status = 'pending',
    this.devWorkStatus = 'in_progress',
    this.apologyNote,
    this.declineReason,
    required this.timestamp,
  });

  factory InvitationModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parsedTime;
    try {
      parsedTime = (map['timestamp'] as Timestamp).toDate();
    } catch (e) {
      parsedTime = DateTime.now(); // Fallback for old/missing data
    }

    return InvitationModel(
      id: docId,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderPhotoUrl: map['senderPhotoUrl'],
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'],
      receiverPhotoUrl: map['receiverPhotoUrl'],
      projectId: map['projectId'] ?? '',
      projectTitle: map['projectTitle'] ?? '',
      status: map['status'] ?? 'pending',
      devWorkStatus: map['devWorkStatus'] ?? 'in_progress',
      apologyNote: map['apologyNote'],
      declineReason: map['declineReason'],
      timestamp: parsedTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderPhotoUrl': senderPhotoUrl,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverPhotoUrl': receiverPhotoUrl,
      'projectId': projectId,
      'projectTitle': projectTitle,
      'status': status,
      'devWorkStatus': devWorkStatus,
      'apologyNote': apologyNote,
      'declineReason': declineReason,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}



