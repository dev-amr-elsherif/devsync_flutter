import 'package:flutter/foundation.dart';

class GithubAnalyzerService {
  Map<String, dynamic> analyzeProfileData(Map<String, dynamic> profile) {
    debugPrint('DEBUG: Analyzing GitHub profile data directly from auth permissions...');
    
    final int publicRepos = profile['public_repos'] as int? ?? 0;
    final int followers = profile['followers'] as int? ?? 0;
    final String? createdAtStr = profile['created_at']?.toString();
    final String username = profile['login']?.toString() ?? 'developer';
    final String? givenBio = profile['bio']?.toString();

    int accountAgeYears = 0;
    if (createdAtStr != null) {
      try {
        final DateTime createdAt = DateTime.parse(createdAtStr);
        final DateTime now = DateTime.now();
        accountAgeYears = now.year - createdAt.year;
        if (now.month < createdAt.month || (now.month == createdAt.month && now.day < createdAt.day)) {
          accountAgeYears--;
        }
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    String seniority = 'Junior';
    // Logic based on account age, repos, followers
    if (accountAgeYears >= 5 || publicRepos >= 20 || followers >= 50) {
      seniority = 'Senior';
    } else if (accountAgeYears >= 2 || publicRepos >= 5 || followers >= 10) {
      seniority = 'Mid-Level';
    }

    // Since we only use the profile data, we use their own bio or generate a generic one.
    final bio = givenBio ?? "A dedicated $seniority developer with $publicRepos public repositories and ${accountAgeYears > 0 ? '$accountAgeYears years on GitHub' : 'a growing passion for coding'}.";

    debugPrint('DEBUG: Local Analysis complete. Seniority: $seniority');

    return {
      'githubUrl': profile['html_url']?.toString() ?? 'https://github.com/$username',
      'aiBio': bio,
      'githubSeniority': seniority,
      'topAiSkills': <String>[], // Cannot determine fine-grained skills without repos API
      'publicRepos': publicRepos,
      'followers': followers,
      'accountAgeYears': accountAgeYears,
    };
  }
}
