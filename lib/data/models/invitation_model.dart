import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Enums ──────────────────────────────────────────────────────────────────

enum InvitationStatus {
  pending,
  accepted,
  declined,
  joinRequest,
  cancellationProposed,
  cancelled;

  String toFirestoreString() {
    switch (this) {
      case InvitationStatus.pending:               return 'pending';
      case InvitationStatus.accepted:              return 'accepted';
      case InvitationStatus.declined:              return 'declined';
      case InvitationStatus.joinRequest:           return 'join_request';
      case InvitationStatus.cancellationProposed:  return 'cancellation_proposed';
      case InvitationStatus.cancelled:             return 'cancelled';
    }
  }

  static InvitationStatus fromString(String value) {
    switch (value) {
      case 'accepted':               return InvitationStatus.accepted;
      case 'declined':               return InvitationStatus.declined;
      case 'join_request':           return InvitationStatus.joinRequest;
      case 'cancellation_proposed':  return InvitationStatus.cancellationProposed;
      case 'cancelled':              return InvitationStatus.cancelled;
      default:                       return InvitationStatus.pending;
    }
  }

  bool get isPending              => this == InvitationStatus.pending;
  bool get isAccepted             => this == InvitationStatus.accepted;
  bool get isDeclined             => this == InvitationStatus.declined;
  bool get isJoinRequest          => this == InvitationStatus.joinRequest;
  bool get isCancellationProposed => this == InvitationStatus.cancellationProposed;
  bool get isCancelled            => this == InvitationStatus.cancelled;
}

enum DevWorkStatus {
  inProgress,
  finished;

  String toFirestoreString() {
    switch (this) {
      case DevWorkStatus.inProgress: return 'in_progress';
      case DevWorkStatus.finished:   return 'finished';
    }
  }

  static DevWorkStatus? fromString(String? value) {
    switch (value) {
      case 'in_progress': return DevWorkStatus.inProgress;
      case 'finished':    return DevWorkStatus.finished;
      default:            return null;
    }
  }
}

// ─── Model ───────────────────────────────────────────────────────────────────

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
  final InvitationStatus status;
  final DevWorkStatus? devWorkStatus;
  final DateTime timestamp;
  final String? declineReason;
  final String? apologyNote;

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
    required this.status,
    this.devWorkStatus,
    required this.timestamp,
    this.declineReason,
    this.apologyNote,
  });

  // ✅ Convenience getters — delegate to status enum
  bool get isAccepted             => status.isAccepted;
  bool get isPending              => status.isPending;
  bool get isDeclined             => status.isDeclined;
  bool get isJoinRequest          => status.isJoinRequest;
  bool get isCancellationProposed => status.isCancellationProposed;
  bool get isCancelled            => status.isCancelled;

  factory InvitationModel.fromMap(Map<String, dynamic> map, String id) {
    return InvitationModel(
      id:               id,
      senderId:         map['senderId']         ?? '',
      senderName:       map['senderName']       ?? '',
      senderPhotoUrl:   map['senderPhotoUrl'],
      receiverId:       map['receiverId']        ?? '',
      receiverName:     map['receiverName'],
      receiverPhotoUrl: map['receiverPhotoUrl'],
      projectId:        map['projectId']         ?? '',
      projectTitle:     map['projectTitle']      ?? '',
      status:           InvitationStatus.fromString(map['status'] ?? 'pending'),
      devWorkStatus:    DevWorkStatus.fromString(map['devWorkStatus']),
      timestamp:        (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      declineReason:    map['declineReason'],
      apologyNote:      map['apologyNote'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId':         senderId,
      'senderName':       senderName,
      'senderPhotoUrl':   senderPhotoUrl,
      'receiverId':       receiverId,
      'receiverName':     receiverName,
      'receiverPhotoUrl': receiverPhotoUrl,
      'projectId':        projectId,
      'projectTitle':     projectTitle,
      'status':           status.toFirestoreString(),
      'devWorkStatus':    devWorkStatus?.toFirestoreString(),
      'timestamp':        timestamp,
      'declineReason':    declineReason,
      'apologyNote':      apologyNote,
    };
  }

  InvitationModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? receiverId,
    String? receiverName,
    String? receiverPhotoUrl,
    String? projectId,
    String? projectTitle,
    InvitationStatus? status,
    DevWorkStatus? devWorkStatus,
    DateTime? timestamp,
    String? declineReason,
    String? apologyNote,
  }) {
    return InvitationModel(
      id:               id               ?? this.id,
      senderId:         senderId         ?? this.senderId,
      senderName:       senderName       ?? this.senderName,
      senderPhotoUrl:   senderPhotoUrl   ?? this.senderPhotoUrl,
      receiverId:       receiverId       ?? this.receiverId,
      receiverName:     receiverName     ?? this.receiverName,
      receiverPhotoUrl: receiverPhotoUrl ?? this.receiverPhotoUrl,
      projectId:        projectId        ?? this.projectId,
      projectTitle:     projectTitle     ?? this.projectTitle,
      status:           status           ?? this.status,
      devWorkStatus:    devWorkStatus    ?? this.devWorkStatus,
      timestamp:        timestamp        ?? this.timestamp,
      declineReason:    declineReason    ?? this.declineReason,
      apologyNote:      apologyNote      ?? this.apologyNote,
    );
  }
}