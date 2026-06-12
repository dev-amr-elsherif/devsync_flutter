enum ProjectStatus { active, paused, completed, cancelled }

class ProjectModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerPhotoUrl;
  final String title;
  final String description;
  final List<String> techStack;
  final String? repoUrl;
  final String? websiteUrl;
  final String status;
  final String internalNotes;

  ProjectModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerPhotoUrl,
    required this.title,
    required this.description,
    this.techStack = const [],
    this.repoUrl,
    this.websiteUrl,
    this.status = 'active',
    this.internalNotes = '',
  });

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? '',
      ownerPhotoUrl: map['ownerPhotoUrl'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      techStack: List<String>.from(map['techStack'] ?? []),
      repoUrl: map['repoUrl'],
      websiteUrl: map['websiteUrl'],
      status: map['status'] ?? 'active',
      internalNotes: map['internalNotes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhotoUrl': ownerPhotoUrl,
      'title': title,
      'description': description,
      'techStack': techStack,
      'repoUrl': repoUrl,
      'websiteUrl': websiteUrl,
      'status': status,
      'internalNotes': internalNotes,
    };
  }
}
