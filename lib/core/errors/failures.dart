abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network error occurred']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed']);
}

class AIFailure extends Failure {
  const AIFailure([super.message = 'AI matching failed']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache operation failed']);
}

class GitHubFailure extends Failure {
  const GitHubFailure([super.message = 'GitHub API error']);
}

class FirestoreFailure extends Failure {
  const FirestoreFailure([super.message = 'Firestore operation failed']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Unknown error']);
}
