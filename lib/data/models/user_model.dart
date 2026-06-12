enum UserRole { developer, owner, unknown }

class UserModel {
  final String uid; // المعرف الفريد للمستخدم من Firebase
  final String email; // البريد الإلكتروني
  final String name; // اسم المستخدم
  final String? photoUrl; // رابط الصورة الشخصية
  final String role; // دور المستخدم (developer أو owner)
  final List<String> skills; // قائمة المهارات (للمطورين)
  
  // New Portfolio Features
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

  // تحويل البيانات الجاية من Firebase (Map) إلى كائن (Object) - مريح جداً للتعامل مع البيانات
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
      topAiSkills: map['topAiSkills'] != null ? List<String>.from(map['topAiSkills']) : null,
      publicRepos: map['publicRepos'],
      followers: map['followers'],
      accountAgeYears: map['accountAgeYears'],
      ratingCount: map['ratingCount'] ?? 0,
      avgRating: (map['avgRating'] ?? 0.0).toDouble(),
      location: map['location'],
      topRepositories: map['topRepositories'] != null ? List<dynamic>.from(map['topRepositories']) : null,
    );
  }

  // تحويل الكائن إلى Map عشان نخزنه في Firebase
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
