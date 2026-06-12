import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/errors/failures.dart';

class GitHubApiProvider {
  final Dio _dio = ApiClient.github;

  /// Fetch the authenticated user's profile
  Future<Map<String, dynamic>> fetchUserProfile() async {
    try {
      final response = await _dio.get('/user');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw GitHubFailure('Profile fetch failed: ${e.message}');
    }
  }

  /// Fetch user's public repositories
  Future<List<Map<String, dynamic>>> fetchUserRepos(String username) async {
    try {
      final response = await _dio.get(
        '/users/$username/repos',
        queryParameters: {
          'sort': 'updated',
          'per_page': 50,
          'type': 'owner',
        },
      );
      return List<Map<String, dynamic>>.from(response.data as List);
    } on DioException catch (e) {
      throw GitHubFailure('Repos fetch failed: ${e.message}');
    }
  }

  /// Compute top languages from repos
  Future<List<String>> fetchTopLanguages(String username) async {
    try {
      final repos = await fetchUserRepos(username);
      final Map<String, int> langCount = {};

      for (final repo in repos) {
        final lang = repo['language'] as String?;
        if (lang != null && lang.isNotEmpty) {
          langCount[lang] = (langCount[lang] ?? 0) + 1;
        }
      }

      final sorted = langCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted.take(5).map((e) => e.key).toList();
    } on GitHubFailure {
      rethrow;
    }
  }

  /// Fetch languages breakdown for a specific repo
  Future<Map<String, int>> fetchRepoLanguages(
      String username, String repoName) async {
    try {
      final response = await _dio.get('/repos/$username/$repoName/languages');
      return Map<String, int>.from(response.data as Map);
    } on DioException catch (e) {
      throw GitHubFailure('Languages fetch failed: ${e.message}');
    }
  }

  /// Fetch pinned/popular repos with README content
  Future<String?> fetchReadme(String username, String repoName) async {
    try {
      final response = await _dio.get(
        '/repos/$username/$repoName/readme',
        options: Options(
          headers: {'Accept': 'application/vnd.github.raw+json'},
        ),
      );
      final content = response.data as String?;
      // Truncate to 2000 chars for AI context window management
      return content != null && content.length > 2000
          ? '${content.substring(0, 2000)}...'
          : content;
    } on DioException {
      return null; // README is optional
    }
  }

  /// Fetch user's contribution stats (events-based approximation)
  Future<int> fetchContributionCount(String username) async {
    try {
      final response = await _dio.get(
        '/users/$username/events',
        queryParameters: {'per_page': 100},
      );
      final events = response.data as List;
      // Count push events as a contribution proxy
      final pushEvents =
          events.where((e) => e['type'] == 'PushEvent').length;
      return pushEvents;
    } on DioException {
      return 0;
    }
  }

  /// Exchange OAuth code for access token
  Future<String> exchangeCodeForToken({
    required String code,
    required String clientId,
    required String clientSecret,
  }) async {
    try {
      final response = await ApiClient.base.post(
        'https://github.com/login/oauth/access_token',
        data: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'code': code,
        },
        options: Options(headers: {'Accept': 'application/json'}),
      );
      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String?;
      if (token == null || token.isEmpty) {
        throw const GitHubFailure('Failed to obtain access token');
      }
      return token;
    } on DioException catch (e) {
      throw GitHubFailure('Token exchange failed: ${e.message}');
    }
  }
}
