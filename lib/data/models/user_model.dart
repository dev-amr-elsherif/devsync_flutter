// lib/data/models/user_model.dart

enum UserRole { developer, owner, unknown }

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final String role;
  final List<String> skills;
  final String? githubUrl;
  final String? aiBio;
  final String? githubSeniority;
  final List<String>? topAiSkills;
  final int? publicRepos;
  final int? followers;
  final int? accountAgeYears;
  final int ratingCount;
  final double avgRating;
  final String? location;
  final List<dynamic>? topRepositories;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.role,
    this.skills = const [],
    this.githubUrl,
    this.aiBio,
    this.githubSeniority,
    this.topAiSkills,
    this.publicRepos,
    this.followers,
    this.accountAgeYears,
    this.ratingCount = 0,
    this.avgRating = 0.0,
    this.location,
    this.topRepositories,
  });

  // ✅ copyWith — بدلاً من إعادة كتابة كل الحقول
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? photoUrl,
    String? role,
    List<String>? skills,
    String? githubUrl,
    String? aiBio,
    String? githubSeniority,
    List<String>? topAiSkills,
    int? publicRepos,
    int? followers,
    int? accountAgeYears,
    int? ratingCount,
    double? avgRating,
    String? location,
    List<dynamic>? topRepositories,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      skills: skills ?? this.skills,
      githubUrl: githubUrl ?? this.githubUrl,
      aiBio: aiBio ?? this.aiBio,
      githubSeniority: githubSeniority ?? this.githubSeniority,
      topAiSkills: topAiSkills ?? this.topAiSkills,
      publicRepos: publicRepos ?? this.publicRepos,
      followers: followers ?? this.followers,
      accountAgeYears: accountAgeYears ?? this.accountAgeYears,
      ratingCount: ratingCount ?? this.ratingCount,
      avgRating: avgRating ?? this.avgRating,
      location: location ?? this.location,
      topRepositories: topRepositories ?? this.topRepositories,
    );
  }

  // ✅ Helper getter
  bool get isDeveloper => role == 'developer';
  bool get isOwner => role == 'owner';
  bool get hasGithubProfile => githubUrl != null;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      role: map['role'] ?? 'developer',
      skills: List<String>.from(map['skills'] ?? []),
      githubUrl: map['githubUrl'],
      aiBio: map['aiBio'],
      githubSeniority: map['githubSeniority'],
      topAiSkills: map['topAiSkills'] != null
          ? List<String>.from(map['topAiSkills'])
          : null,
      publicRepos: map['publicRepos'],
      followers: map['followers'],
      accountAgeYears: map['accountAgeYears'],
      ratingCount: map['ratingCount'] ?? 0,
      avgRating: (map['avgRating'] ?? 0.0).toDouble(),
      location: map['location'],
      topRepositories: map['topRepositories'] != null
          ? List<dynamic>.from(map['topRepositories'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'role': role,
      'skills': skills,
      'githubUrl': githubUrl,
      'aiBio': aiBio,
      'githubSeniority': githubSeniority,
      'topAiSkills': topAiSkills,
      'publicRepos': publicRepos,
      'followers': followers,
      'accountAgeYears': accountAgeYears,
      'ratingCount': ratingCount,
      'avgRating': avgRating,
      'location': location,
      'topRepositories': topRepositories,
    };
  }
}
