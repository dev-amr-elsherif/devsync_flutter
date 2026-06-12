import 'package:dio/dio.dart';

class GithubService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://api.github.com'));

  Future<Map<String, dynamic>> getUserActivity(String username) async {
    try {
      final repoResponse = await _dio.get('/users/$username/repos?sort=updated&per_page=10');
      final repos = repoResponse.data as List;
      
      final languages = <String>{};
      final repoNames = <String>[];
      
      for (var repo in repos) {
        repoNames.add(repo['name']);
        if (repo['language'] != null) {
          languages.add(repo['language']);
        }
      }

      return {
        'username': username,
        'top_languages': languages.toList(),
        'recent_repos': repoNames,
        'public_repos_count': repos.length,
      };
    } catch (e) {
      return {
        'username': username,
        'error': 'Could not fetch GitHub activity',
      };
    }
  }
}
