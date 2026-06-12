import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String projectId;
  final String projectTitle;
  final String ownerId;
  final String ownerName;
  final String developerId;
  final double rating; // 1.0 to 5.0
  final String comment;
  final DateTime timestamp;

  ReviewModel({
    required this.id,
    required this.projectId,
    required this.projectTitle,
    required this.ownerId,
    required this.ownerName,
    required this.developerId,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReviewModel(
      id: docId,
      projectId: map['projectId'] ?? '',
      projectTitle: map['projectTitle'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      developerId: map['developerId'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'projectTitle': projectTitle,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'developerId': developerId,
      'rating': rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
