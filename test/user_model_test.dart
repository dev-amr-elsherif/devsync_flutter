import 'package:flutter_test/flutter_test.dart';
import 'package:dev_match_app/data/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    final userMap = {
      'uid': '123',
      'email': 'test@example.com',
      'name': 'Test User',
      'photoUrl': 'https://example.com/photo.jpg',
      'role': 'developer',
      'skills': ['Flutter', 'Dart'],
    };

    test('should create UserModel from map', () {
      final user = UserModel.fromMap(userMap);

      expect(user.uid, '123');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.photoUrl, 'https://example.com/photo.jpg');
      expect(user.role, 'developer');
      expect(user.skills, contains('Flutter'));
    });

    test('should convert UserModel to map', () {
      final user = UserModel(
        uid: '123',
        email: 'test@example.com',
        name: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        role: 'developer',
        skills: ['Flutter', 'Dart'],
      );

      final result = user.toMap();

      expect(result['uid'], '123');
      expect(result['email'], 'test@example.com');
      expect(result['role'], 'developer');
      expect(result['skills'], isA<List>());
    });
  });
}
